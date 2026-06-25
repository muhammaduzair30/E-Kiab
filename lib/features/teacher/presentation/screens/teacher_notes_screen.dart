import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/presentation/providers/note_provider.dart';

class TeacherNotesScreen extends ConsumerStatefulWidget {
  const TeacherNotesScreen({super.key});

  @override
  ConsumerState<TeacherNotesScreen> createState() => _TeacherNotesScreenState();
}

class _TeacherNotesScreenState extends ConsumerState<TeacherNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    bool isSubmitting = false;
    Uint8List? selectedFileBytes;
    String? selectedFileName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Publish Note', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(labelText: 'Note Title', hintText: 'e.g., Photosynthesis Summary'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _topicCtrl,
                      decoration: const InputDecoration(labelText: 'Topic/Chapter (Optional)', hintText: 'e.g., Biology Ch 4'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentCtrl,
                      maxLines: 5,
                      validator: (v) => (v == null || v.isEmpty) && selectedFileBytes == null ? 'Content or File is required' : null,
                      decoration: const InputDecoration(labelText: 'Content', hintText: 'Type your notes here...'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.any,
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              setDialogState(() {
                                selectedFileBytes = result.files.single.bytes;
                                selectedFileName = result.files.single.name;
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Attach File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (selectedFileName != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setDialogState(() {
                                selectedFileBytes = null;
                                selectedFileName = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx), 
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setDialogState(() => isSubmitting = true);
                    try {
                      await ref.read(teacherNoteListProvider.notifier).addNote(
                            _titleCtrl.text,
                            _contentCtrl.text,
                            _topicCtrl.text.isNotEmpty ? _topicCtrl.text : null,
                            fileBytes: selectedFileBytes,
                            fileName: selectedFileName,
                          );
                      _titleCtrl.clear();
                      _contentCtrl.clear();
                      _topicCtrl.clear();
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to publish note: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  }
                },
                child: isSubmitting 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text('Publish'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherNoteListProvider);

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
                  ? Center(child: Text('No notes published yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final note = state.notes[i];
                        return Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: AppColors.secondary, width: 5)),
                            ),
                            padding: const EdgeInsets.all(16),
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
                                        Text(note['title'] ?? 'Untitled',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (note['topic'] != null)
                                          Text(note['topic'],
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                        ));
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add),
        label: const Text('Publish Note'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
