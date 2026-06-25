import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ekitab/features/notes/data/repositories/note_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteListState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> notes;

  const NoteListState({
    this.isLoading = false,
    this.error,
    this.notes = const [],
  });
}

class NoteListNotifier extends StateNotifier<NoteListState> {
  final Ref ref;
  final bool teacherOnly;

  NoteListNotifier(this.ref, {this.teacherOnly = false}) : super(const NoteListState());

  Future<void> loadNotes() async {
    state = const NoteListState(isLoading: true);
    try {
      final repo = ref.read(noteRepositoryProvider);
      final notes = teacherOnly ? await repo.getNotesByTeacher() : await repo.getNotes();
      state = NoteListState(isLoading: false, notes: notes);
    } catch (e) {
      state = NoteListState(isLoading: false, error: e.toString());
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  Future<void> addNote(String title, String content, String? topic, {Uint8List? fileBytes, String? fileName}) async {
    try {
      final repo = ref.read(noteRepositoryProvider);
      String? fileUrl;

      if (fileBytes != null && fileName != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('notes')
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
        
        final metadata = SettableMetadata(contentType: _getMimeType(fileName));
        final uploadTask = await storageRef.putData(fileBytes, metadata);
        fileUrl = await uploadTask.ref.getDownloadURL();
      }

      final newNote = <String, dynamic>{
        'title': title,
        'content': content,
        'topic': topic ?? 'General',
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (fileName != null) 'fileName': fileName,
      };
      await repo.createNote(newNote);
      await loadNotes();
    } catch (e) {
      state = NoteListState(isLoading: false, error: e.toString(), notes: state.notes);
      rethrow;
    }
  }
}

final studentNoteListProvider = StateNotifierProvider<NoteListNotifier, NoteListState>((ref) {
  return NoteListNotifier(ref)..loadNotes();
});

final teacherNoteListProvider = StateNotifierProvider<NoteListNotifier, NoteListState>((ref) {
  return NoteListNotifier(ref, teacherOnly: true)..loadNotes();
});
