import 'package:moor_flutter/moor_flutter.dart';

part 'moor.db.g.dart';

/// #3 主要讲链表
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tagName =>
      text().nullable().customConstraint('NULL REFERENCES tags(name)')();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

class Tags extends Table {
  TextColumn get name => text().withLength(min: 1, max: 10)();
  IntColumn get color => integer()();

  // 将name作为标记的主键需要名称是唯一的
  @override
  Set<Column> get primaryKey => {name};
}

//必须手动将tasks与tags分组。
//此类将用于表连接.
class TaskWithTag {
  final Task task;
  final Tag tag;

  TaskWithTag({
    @required this.task,
    @required this.tag,
  });
}

@UseMoor(tables: [Tasks, Tags], daos: [TaskDao, TagDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite'));
  @override
  int get schemaVersion => 3;

  /// 迁移版本
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // onCreate: (Migrator m) {
      //   return m.createAllTables();
      // },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.addColumn(tasks, tasks.dueDate);
        } else if (from == 2) {
          await m.addColumn(tasks, tasks.tagName);
          await m.createTable(tags);
        }
      },
      beforeOpen: (QueryEngine db, OpeningDetails details) async {
        await db.customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

@UseDao(
  tables: [Tasks, Tags],
)
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  final AppDatabase db;
  TaskDao(this.db) : super(db);

  /// all
  Stream<List<TaskWithTag>> watchAllTasks() {
    return (select(tasks)
          ..orderBy(
            ([
              /// 把已完成排在后面
              (t) =>
                  OrderingTerm(expression: t.completed, mode: OrderingMode.asc),
            ]),
          ))
        .join(
          [
            //使用标签加入所有任务。
            //重要的是我们使用equalsExp而不仅仅是equals。
            //这样，我们可以使用tasks表中的所有标记名称加入，而不仅仅是特定的名称
            leftOuterJoin(tags, tags.name.equalsExp(tasks.tagName)),
          ],
        )
        .watch()
        .map(
          (rows) => rows.map(
            (row) {
              return TaskWithTag(
                task: row.readTable(tasks),
                tag: row.readTable(tags),
              );
            },
          ).toList(),
        );
  }

  Future<int> insertTask(Insertable<Task> task) => into(tasks).insert(task);
  Future<bool> updateTask(Insertable<Task> task) => update(tasks).replace(task);
  Future<int> deleteTask(Insertable<Task> task) => delete(tasks).delete(task);
}

@UseDao(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  final AppDatabase db;

  TagDao(this.db) : super(db);

  Stream<List<Tag>> watchTags() => select(tags).watch();
  Future insertTag(Insertable<Tag> tag) => into(tags).insert(tag);
}
