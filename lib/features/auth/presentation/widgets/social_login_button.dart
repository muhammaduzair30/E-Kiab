import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String? iconPath;
  final IconData? icon;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    this.iconPath,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (iconPath != null) {
      iconWidget = Image.network(iconPath!, height: 24, errorBuilder: (_, __, ___) => Icon(icon ?? Icons.login),);
    } else {
      iconWidget = Icon(icon ?? Icons.login);
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
