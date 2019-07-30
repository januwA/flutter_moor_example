import 'package:moor_flutter/moor_flutter.dart';

part 'moor.db.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueData => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

@UseMoor(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite'));
  @override
  int get schemaVersion => 1;

  Future<List<Task>> get getAllTasks => select(tasks).get();

  /// 每当基础数据发生变化时，都会发出新项
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  /// 插入一条数据
  Future<int> insertTask({
    String name,
    DateTime dueData,
  }) =>
      into(tasks).insert(
        TasksCompanion(
          name: Value(name),
          dueData: Value(dueData),
        ),
      );

  /// 更新一条数据
  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  /// 删除一条数据
  Future<int> deleteTask(Task task) => delete(tasks).delete(task);
}
