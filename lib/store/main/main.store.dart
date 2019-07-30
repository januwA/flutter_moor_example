import 'package:flutter_moor_demo/db/moor.db.dart';

class MainStore {
  final dbService = DBService();
}

class DBService {
  final database = AppDatabase();
  Stream<List<Task>> get tasks$ =>
      database.watchAllTasks().map((List<Task> tasks) {
        /// 排序,把完成的排在后面
        tasks.sort(
          (a, b) => _getInt(a.completed).compareTo(_getInt(b.completed)),
        );
        return tasks;
      });
  int _getInt(bool b) {
    return b ? 1 : 0;
  }
}

final MainStore mainStore = MainStore();
