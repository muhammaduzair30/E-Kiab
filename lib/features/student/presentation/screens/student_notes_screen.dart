import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/presentation/providers/note_provider.dart';

class StudentNotesScreen extends ConsumerWidget {
  const StudentNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentNoteListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Study Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: state.isLoading && state.notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}', style: const TextStyle(color: AppColors.error)))
              : state.notes.isEmpty
                  ? Center(child: Text('No notes available yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final note = state.notes[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.note_rounded, color: AppColors.secondary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(note['title'] ?? 'Untitled Note',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (note['topic'] != null)
                                          Text(note['topic'],
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if ((note['content'] ?? '').isNotEmpty)
                                Text(note['content'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
                              if (note['fileUrl'] != null) ...[
                                if ((note['content'] ?? '').isNotEmpty) const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final url = Uri.parse(note['fileUrl']);
                                    try {
                                      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not open file. No app found to handle this link.'), backgroundColor: AppColors.error),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error opening file: $e'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.attach_file, size: 16),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            note['fileName'] ?? 'Attached Document',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
