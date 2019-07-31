import 'package:flutter_moor_demo/db/moor.db.dart';

class MainStore {
  final dbService = DBService();
}

class DBService {
  final database = AppDatabase().taskDao;
}

final MainStore mainStore = MainStore();
