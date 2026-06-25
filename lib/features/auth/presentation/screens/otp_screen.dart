// lib/features/auth/presentation/screens/otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsLeft = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String val) {
    if (val.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (val.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  Future<void> _verify() async {
    final success = await ref.read(authStateProvider.notifier).verifyOtp(
      email: widget.email,
      otp: _otp,
    );
    if (success && mounted) {
      context.go(AppRoutes.studentHome);
    } else if (mounted) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    // Call resend API
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent again to your email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');

    ref.listen(authStateProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
        ref.read(authStateProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Check your email', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to\n${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 40),

            // OTP input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => _OtpBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (val) => _onDigitChanged(i, val),
                onBackspace: () {
                  if (_controllers[i].text.isEmpty && i > 0) {
                    _controllers[i - 1].clear();
                    _focusNodes[i - 1].requestFocus();
                  }
                },
              )),
            ),
            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (auth.isLoading || _otp.length < 6) ? null : _verify,
                child: auth.isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify Email'),
              ),
            ),
            const SizedBox(height: 24),

            // Resend timer
            if (_secondsLeft > 0)
              Text(
                'Resend in $mm:$ss',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              TextButton(
                onPressed: _resend,
                child: const Text('Resend OTP'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller, required this.focusNode,
    required this.onChanged, required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          maxLength: 1,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
