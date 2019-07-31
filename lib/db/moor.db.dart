import 'package:moor_flutter/moor_flutter.dart';

part 'moor.db.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

@UseMoor(tables: [Tasks], daos: [TaskDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite'));
  @override
  int get schemaVersion => 2;

  /// 迁移版本
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAllTables();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.addColumn(tasks, tasks.dueDate);
        }
      },
    );
  }
}

@UseDao(
  tables: [Tasks],
  queries: {
    // 将在_$TaskDaoMixin中生成此查询的实现
    // 将创建completeTasksGenerated()和watchCompletedTasksGenerated()
    // #2
    'completedTasksGenerated':
        'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;'
  },
)
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;
  TaskDao(this.db) : super(db);

  Future<List<Task>> get getAllTasks => select(tasks).get();

  /// 每当基础数据发生变化时，都会发出新项
  // Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  /// all
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)
          ..orderBy(
            ([
              // (t) =>
              //     OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
              // (t) => OrderingTerm(expression: t.name),
              /// 把已完成排在后面
              (t) => OrderingTerm(
                  expression: t.completed, mode: OrderingMode.asc),
            ]),
          ))
        .watch();
  }

  /// 已完成的 #1
  Stream<List<Task>> watchCompletedTasks() {
    return (select(tasks)
          ..orderBy(
            ([
              // 按截止日期进行初步分类
              (t) =>
                  OrderingTerm(expression: t.dueDate, mode: OrderingMode.desc),
              // name 排序
              (t) => OrderingTerm(expression: t.name),
            ]),
          )
          ..where((t) => t.completed.equals(true)))
        .watch();
  }

  /// 使用自定义查询查看完整任务
  /// #3
  Stream<List<Task>> watchCompletedTasksCustom() {
    return customSelectStream(
      'SELECT * FROM tasks WHERE completed = 1 ORDER BY due_date DESC, name;',
      readsFrom: {tasks},
    ).map((List<QueryRow> rows) {
      // 将行的数据转换为Task对象
      return rows.map((row) => Task.fromData(row.data, db)).toList();
    });
  }

  Future<int> insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future<bool> updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future<int> deleteTask(Insertable<Task> task) => delete(tasks).delete(task);
}
