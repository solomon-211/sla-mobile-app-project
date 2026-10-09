import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../data/seed_data.dart';
import '../models/task.dart';
import '../models/task_activity.dart';

/// Single access point for the local SQLite database (sqflite).
///
/// Tasks, team members and task history are relational data (a task belongs
/// to a member, activity belongs to a task), which is why they are stored in
/// SQLite rather than SharedPreferences.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'sprinttrack.db';
  static const _members = 'members';
  static const _tasks = 'tasks';
  static const _activities = 'activities';

  /// Password given to the demo team and to members added from the Team tab.
  static const demoPassword = 'sprint123';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Version 2 added the members.password column. Existing members get the
  /// demo password so nobody is locked out after the update.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $_members ADD COLUMN password TEXT NOT NULL "
        "DEFAULT '$demoPassword'",
      );
    }
  }

  /// Creates the three tables and seeds demo data on first install.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_members (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        role          TEXT    NOT NULL,
        email         TEXT    NOT NULL UNIQUE,
        color_index   INTEGER NOT NULL DEFAULT 0,
        password      TEXT    NOT NULL DEFAULT '$demoPassword'
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tasks (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT    NOT NULL,
        description  TEXT    NOT NULL DEFAULT '',
        category     TEXT    NOT NULL,
        assignee_id  INTEGER NOT NULL REFERENCES $_members(id),
        due_date     INTEGER NOT NULL,
        priority     TEXT    NOT NULL,
        status       TEXT    NOT NULL,
        created_at   INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE $_activities (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id    INTEGER NOT NULL REFERENCES $_tasks(id) ON DELETE CASCADE,
        message    TEXT    NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await _seed(db);
  }

  /// Inserts demo members and tasks, then writes the first activity row for
  /// each task so the history tab is never empty on a fresh install.
  Future<void> _seed(Database db) async {
    final namesById = <int, String>{};
    for (final member in seedMembers) {
      await db.insert(_members, {...member.toMap(), 'password': demoPassword});
      namesById[member.id] = member.name;
    }

    for (final task in buildSeedTasks(DateTime.now())) {
      final taskId = await db.insert(_tasks, task.toMap());
      await db.insert(
        _activities,
        TaskActivity(
          taskId: taskId,
          message: 'Created and assigned to ${namesById[task.assigneeId]}',
          createdAt: task.createdAt,
        ).toMap(),
      );
      if (task.completedAt != null) {
        await db.insert(
          _activities,
          TaskActivity(
            taskId: taskId,
            message: 'Status changed to ${TaskStatus.done.label}',
            createdAt: task.completedAt!,
          ).toMap(),
        );
      }
    }
  }
}
