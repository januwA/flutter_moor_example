import 'package:flutter_moor_demo/db/moor.db.dart';

class MainStore {
  final dbService = DBService();
}

class DBService {
  AppDatabase _database = AppDatabase();
  TaskDao get taskDao => _database.taskDao;
  TagDao get tagDao => _database.tagDao;
}

final MainStore mainStore = MainStore();
