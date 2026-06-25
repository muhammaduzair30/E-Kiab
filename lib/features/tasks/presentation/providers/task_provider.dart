import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ekitab/features/tasks/data/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class TaskListState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> tasks;

  const TaskListState({
    this.isLoading = false,
    this.error,
    this.tasks = const [],
  });
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final Ref ref;
  final bool teacherOnly;

  TaskListNotifier(this.ref, {this.teacherOnly = false}) : super(const TaskListState());

  Future<void> loadTasks() async {
    state = const TaskListState(isLoading: true);
    try {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = teacherOnly ? await repo.getTasksByTeacher() : await repo.getTasks();
      state = TaskListState(isLoading: false, tasks: tasks);
    } catch (e) {
      state = TaskListState(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTask(String title, String description, {String type = 'general', String? bookId, String? chapterId, int? totalMarks}) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final newTask = <String, dynamic>{
        'title': title,
        'description': description,
        'type': type,
        if (bookId != null) 'bookId': bookId,
        if (chapterId != null) 'chapterId': chapterId,
        if (totalMarks != null) 'totalMarks': totalMarks,
      };
      await repo.createTask(newTask);
      await loadTasks();
    } catch (e) {
      state = TaskListState(isLoading: false, error: e.toString(), tasks: state.tasks);
      rethrow;
    }
  }

  Future<void> markTaskComplete(String taskId) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.markTaskComplete(taskId);
      await loadTasks(); // reload to reflect changes
    } catch (e) {
      state = TaskListState(isLoading: false, error: e.toString(), tasks: state.tasks);
      rethrow;
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

  Future<void> submitTask(String taskId, Uint8List fileBytes, String fileName) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('task_submissions')
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
      
      final metadata = SettableMetadata(contentType: _getMimeType(fileName));
      final uploadTask = await storageRef.putData(fileBytes, metadata);
      final fileUrl = await uploadTask.ref.getDownloadURL();
      
      await repo.submitTask(taskId, fileUrl, fileName);
      await loadTasks();
    } catch (e) {
      state = TaskListState(isLoading: false, error: e.toString(), tasks: state.tasks);
      rethrow;
    }
  }
  Future<void> rateStudentTask(String taskId, String studentId, int rating, String feedback) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.rateStudentTask(taskId, studentId, rating, feedback);
      await loadTasks(); // reload to reflect changes
    } catch (e) {
      state = TaskListState(isLoading: false, error: e.toString(), tasks: state.tasks);
      rethrow;
    }
  }
}

final studentListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(taskRepositoryProvider);
  return repo.getAllStudents();
});

final studentTaskListProvider = StateNotifierProvider.autoDispose<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(ref)..loadTasks();
});

final teacherTaskListProvider = StateNotifierProvider.autoDispose<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(ref, teacherOnly: true)..loadTasks();
});
