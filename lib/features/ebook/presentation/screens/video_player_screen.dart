import 'package:ekitab/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool _isPlaying = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  double _progress = 0.25; // Simulated progress (0-1)
  final Duration _duration = const Duration(minutes: 42, seconds: 18);

  @override
  void dispose() {
    // Restore portrait on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  Duration get _currentPosition =>
      Duration(seconds: (_duration.inSeconds * _progress).round());

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // TODO: replace with real video data from provider
    final video = _mockVideo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFullscreen
          ? _buildVideoArea(video)
          : Column(
              children: [
                _buildVideoArea(video),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildVideoDetails(context, video),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVideoArea(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: _isFullscreen
            ? MediaQuery.of(context).size.aspectRatio
            : 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video placeholder (use video_player plugin in real impl)
              Container(
                color: const Color(0xFF1A1A2E),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline_rounded,
                          size: 72, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('video_player plugin required',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                ),
              ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _buildControls(video),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(video['title'],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed_rounded, color: Colors.white, size: 20),
                    onSelected: (v) => setState(() => _playbackSpeed = v),
                    itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  if (_playbackSpeed == s)
                                    const Icon(Icons.check_rounded, size: 16,
                                        color: AppColors.primary),
                                  if (_playbackSpeed == s) const SizedBox(width: 8),
                                  Text('${s}x'),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // Center play controls
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                  onPressed: () => setState(() => _progress = (_progress - 0.05).clamp(0, 1)),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => setState(() => _isPlaying = !_isPlaying),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                  onPressed: () => setState(() => _progress = (_progress + 0.05).clamp(0, 1)),
                ),
              ],
            ),
          ),

          // Bottom seek bar
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, 0, 12, _isFullscreen ? 24 : 8),
            child: Column(
              children: [
                Slider(
                  value: _progress,
                  onChanged: (v) => setState(() => _progress = v),
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.white30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_currentPosition),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(_formatDuration(_duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      IconButton(
                        icon: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _toggleFullscreen,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDetails(BuildContext context, Map<String, dynamic> video) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subject
          Text(video['title'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _Tag(label: video['subject'], color: AppColors.primary),
              _Tag(label: 'Grade ${video['grade']}', color: AppColors.secondary),
              _Tag(label: _formatDuration(_duration), color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text('Description',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(video['description'],
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontSize: 13)),
          const SizedBox(height: 20),

          // Related videos
          Text('Related Videos',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RelatedVideoCard(index: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _RelatedVideoCard extends StatelessWidget {
  final int index;
  const _RelatedVideoCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle_outline_rounded,
              color: Colors.white60, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chapter ${index + 2}: Topic ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('18 min • Mathematics',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

final _mockVideo = {
  'title': 'Chapter 3: Algebraic Expressions — Introduction & Simplification',
  'subject': 'Mathematics',
  'grade': 9,
  'description':
      'In this lesson, we explore algebraic expressions, learn how to identify like terms, and practice simplification. Covers examples from the Punjab Board Grade 9 curriculum.',
};
