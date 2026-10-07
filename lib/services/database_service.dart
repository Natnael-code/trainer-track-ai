import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client_model.dart';
import '../models/fitness_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // Web memory cache snapshots
  static final List<ClientModel> _webClientsCache = [];
  static final List<GroupModel> _webGroupsCache = [];
  static final List<ScheduleDayModel> _webSchedulesCache = [];
  static final List<WorkoutPlanModel> _webWorkoutPlansCache = [];
  static final List<Map<String, String>> _webGroupMembersCache = [];
  static final List<GroupAttendanceModel> _webAttendanceCache = [];
  static final List<ClientProgressModel> _webProgressCache = [];

  DatabaseService._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Native database access is disabled on Web.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('trainer_track.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        startingWeight REAL NOT NULL,
        height REAL NOT NULL,
        startingBodyFat TEXT,
        localProfileImagePath TEXT,
        injuries TEXT NOT NULL,
        medicalConditions TEXT NOT NULL,
        experienceLevel TEXT NOT NULL,
        lifestyleType TEXT NOT NULL,
        joinedDate TEXT NOT NULL,
        status TEXT NOT NULL,
        groupId TEXT,
        availableDaysPerWeek INTEGER DEFAULT 5,
        workoutSessionsPerDay INTEGER DEFAULT 1,
        fitnessGoal TEXT DEFAULT 'Lose Weight'
      )
    ''');

    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        groupName TEXT NOT NULL,
        createdDate TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE group_members (
        groupId TEXT NOT NULL,
        clientId TEXT NOT NULL,
        PRIMARY KEY (groupId, clientId)
      )
    ''');

    await db.execute('''
      CREATE TABLE group_attendance (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        dayScheduleId TEXT NOT NULL,
        clientId TEXT NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        clientId TEXT,
        groupId TEXT,
        dayNumber INTEGER NOT NULL,
        isWorkDay INTEGER NOT NULL,
        absoluteDate TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_plans (
        id TEXT PRIMARY KEY,
        dayScheduleId TEXT NOT NULL,
        routineName TEXT NOT NULL,
        exercisesJson TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE client_progress (
        id TEXT PRIMARY KEY,
        clientId TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        bmi REAL NOT NULL,
        imagePath TEXT,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE schedules ADD COLUMN absoluteDate TEXT NOT NULL DEFAULT "";',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE clients ADD COLUMN availableDaysPerWeek INTEGER DEFAULT 5;',
        );
        await db.execute(
          'ALTER TABLE clients ADD COLUMN workoutSessionsPerDay INTEGER DEFAULT 1;',
        );
        await db.execute(
          'ALTER TABLE clients ADD COLUMN fitnessGoal TEXT DEFAULT "Lose Weight";',
        );
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS group_members (
            groupId TEXT NOT NULL,
            clientId TEXT NOT NULL,
            PRIMARY KEY (groupId, clientId)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS group_attendance (
            id TEXT PRIMARY KEY,
            groupId TEXT NOT NULL,
            dayScheduleId TEXT NOT NULL,
            clientId TEXT NOT NULL,
            status TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS client_progress (
            id TEXT PRIMARY KEY,
            clientId TEXT NOT NULL,
            weight REAL NOT NULL,
            height REAL NOT NULL,
            bmi REAL NOT NULL,
            imagePath TEXT,
            date TEXT NOT NULL,
            notes TEXT
          )
        ''');
      } catch (_) {}
    }
  }

  // --- CLIENT OPERATIONS ---
  Future<void> insertClient(ClientModel client) async {
    if (kIsWeb) {
      _webClientsCache.removeWhere((c) => c.id == client.id);
      _webClientsCache.add(client);
      return;
    }
    final db = await instance.database;
    await db.insert(
      'clients',
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ClientModel>> fetchAllClients() async {
    if (kIsWeb) return _webClientsCache;
    final db = await instance.database;
    final result = await db.query('clients', orderBy: 'name ASC');
    return result.map((json) => ClientModel.fromMap(json)).toList();
  }

  Future<void> deleteClient(String clientId) async {
    if (kIsWeb) {
      _webClientsCache.removeWhere((c) => c.id == clientId);
      _webGroupMembersCache.removeWhere((m) => m['clientId'] == clientId);
      _webSchedulesCache.removeWhere((s) => s.clientId == clientId);
      _webProgressCache.removeWhere((p) => p.clientId == clientId);
      return;
    }
    final db = await instance.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [clientId]);
    await db.delete(
      'group_members',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    await db.delete('schedules', where: 'clientId = ?', whereArgs: [clientId]);
    await db.delete(
      'client_progress',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
  }

  // --- CLIENT PROGRESS OPERATIONS ---
  Future<void> insertClientProgress(ClientProgressModel progress) async {
    if (kIsWeb) {
      _webProgressCache.removeWhere((p) => p.id == progress.id);
      _webProgressCache.add(progress);
      return;
    }
    final db = await instance.database;
    await db.insert(
      'client_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ClientProgressModel>> fetchProgressForClient(
    String clientId,
  ) async {
    if (kIsWeb) {
      return _webProgressCache.where((p) => p.clientId == clientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await instance.database;
    final result = await db.query(
      'client_progress',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    return result.map((json) => ClientProgressModel.fromMap(json)).toList();
  }

  // --- GROUP OPERATIONS & MEMBERSHIP ---
  Future<void> insertGroup(GroupModel group) async {
    if (kIsWeb) {
      _webGroupsCache.removeWhere((g) => g.id == group.id);
      _webGroupsCache.add(group);
      return;
    }
    final db = await instance.database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GroupModel>> fetchAllGroups() async {
    if (kIsWeb) return _webGroupsCache;
    final db = await instance.database;
    final result = await db.query('groups', orderBy: 'groupName ASC');
    return result.map((map) => GroupModel.fromMap(map)).toList();
  }

  Future<void> addClientToGroup(String clientId, String groupId) async {
    if (kIsWeb) {
      _webGroupMembersCache.removeWhere(
        (m) => m['clientId'] == clientId && m['groupId'] == groupId,
      );
      _webGroupMembersCache.add({'groupId': groupId, 'clientId': clientId});
      final index = _webClientsCache.indexWhere((c) => c.id == clientId);
      if (index != -1) {
        final c = _webClientsCache[index];
        _webClientsCache[index] = ClientModel(
          id: c.id,
          name: c.name,
          phoneNumber: c.phoneNumber,
          age: c.age,
          gender: c.gender,
          startingWeight: c.startingWeight,
          height: c.height,
          startingBodyFat: c.startingBodyFat,
          localProfileImagePath: c.localProfileImagePath,
          injuries: c.injuries,
          medicalConditions: c.medicalConditions,
          experienceLevel: c.experienceLevel,
          lifestyleType: c.lifestyleType,
          joinedDate: c.joinedDate,
          status: c.status,
          groupId: groupId,
          availableDaysPerWeek: c.availableDaysPerWeek,
          workoutSessionsPerDay: c.workoutSessionsPerDay,
          fitnessGoal: c.fitnessGoal,
        );
      }
      return;
    }
    final db = await instance.database;
    await db.insert('group_members', {
      'groupId': groupId,
      'clientId': clientId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.update(
      'clients',
      {'groupId': groupId},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  Future<void> removeClientFromGroup(String clientId, String groupId) async {
    if (kIsWeb) {
      _webGroupMembersCache.removeWhere(
        (m) => m['clientId'] == clientId && m['groupId'] == groupId,
      );
      return;
    }
    final db = await instance.database;
    await db.delete(
      'group_members',
      where: 'groupId = ? AND clientId = ?',
      whereArgs: [groupId, clientId],
    );
    await db.update(
      'clients',
      {'groupId': null},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  Future<List<ClientModel>> fetchClientsForGroup(String groupId) async {
    if (kIsWeb) {
      final memberIds = _webGroupMembersCache
          .where((m) => m['groupId'] == groupId)
          .map((m) => m['clientId'])
          .toSet();
      return _webClientsCache.where((c) => memberIds.contains(c.id)).toList();
    }
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT c.* FROM clients c
      INNER JOIN group_members gm ON c.id = gm.clientId
      WHERE gm.groupId = ?
      ORDER BY c.name ASC
    ''',
      [groupId],
    );
    return result.map((json) => ClientModel.fromMap(json)).toList();
  }

  // --- ATTENDANCE TRACKING ---
  Future<void> saveGroupAttendance(List<GroupAttendanceModel> records) async {
    if (kIsWeb) {
      for (var r in records) {
        _webAttendanceCache.removeWhere((a) => a.id == r.id);
        _webAttendanceCache.add(r);
      }
      return;
    }
    final db = await instance.database;
    final batch = db.batch();
    for (var r in records) {
      batch.insert(
        'group_attendance',
        r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<GroupAttendanceModel>> fetchAttendanceForDay(
    String groupId,
    String dayScheduleId,
  ) async {
    if (kIsWeb) {
      return _webAttendanceCache
          .where(
            (a) => a.groupId == groupId && a.dayScheduleId == dayScheduleId,
          )
          .toList();
    }
    final db = await instance.database;
    final result = await db.query(
      'group_attendance',
      where: 'groupId = ? AND dayScheduleId = ?',
      whereArgs: [groupId, dayScheduleId],
    );
    return result.map((map) => GroupAttendanceModel.fromMap(map)).toList();
  }

  // --- SCHEDULE & WORKOUT PLAN OPERATIONS ---
  Future<void> saveMonthlySchedule({
    required List<ScheduleDayModel> days,
    required List<WorkoutPlanModel> plans,
  }) async {
    if (kIsWeb) {
      for (var day in days) {
        _webSchedulesCache.removeWhere((d) => d.id == day.id);
        _webSchedulesCache.add(day);
      }
      for (var plan in plans) {
        _webWorkoutPlansCache.removeWhere((p) => p.id == plan.id);
        _webWorkoutPlansCache.add(plan);
      }
      return;
    }

    final db = await instance.database;
    final batch = db.batch();
    for (var day in days) {
      batch.insert(
        'schedules',
        day.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (var plan in plans) {
      batch.insert(
        'workout_plans',
        plan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateScheduleDayStatus(String dayId, String status) async {
    if (kIsWeb) {
      final index = _webSchedulesCache.indexWhere((d) => d.id == dayId);
      if (index != -1) {
        final current = _webSchedulesCache[index];
        _webSchedulesCache[index] = ScheduleDayModel(
          id: current.id,
          clientId: current.clientId,
          groupId: current.groupId,
          dayNumber: current.dayNumber,
          isWorkDay: current.isWorkDay,
          absoluteDate: current.absoluteDate,
          status: status,
        );
      }
      return;
    }
    final db = await instance.database;
    await db.update(
      'schedules',
      {'status': status},
      where: 'id = ?',
      whereArgs: [dayId],
    );
  }

  Future<List<ScheduleDayModel>> fetchScheduleForEntity({
    String? clientId,
    String? groupId,
  }) async {
    if (kIsWeb) {
      return _webSchedulesCache
          .where(
            (d) =>
                (clientId != null && d.clientId == clientId) ||
                (groupId != null && d.groupId == groupId),
          )
          .toList()
        ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    }

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: clientId != null ? 'clientId = ?' : 'groupId = ?',
      whereArgs: clientId != null ? [clientId] : [groupId],
      orderBy: 'dayNumber ASC',
    );
    return maps.map((map) => ScheduleDayModel.fromMap(map)).toList();
  }

  Future<WorkoutPlanModel?> fetchWorkoutPlanForDay(String dayScheduleId) async {
    if (kIsWeb) {
      final matches = _webWorkoutPlansCache.where(
        (p) => p.dayScheduleId == dayScheduleId,
      );
      return matches.isEmpty ? null : matches.first;
    }
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workout_plans',
      where: 'dayScheduleId = ?',
      whereArgs: [dayScheduleId],
    );
    if (maps.isEmpty) return null;
    return WorkoutPlanModel.fromMap(maps.first);
  }

  Future<void> exportDatabaseBackup() async {
    if (kIsWeb) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trainer_track.db');
    final dbFile = File(path);
    if (await dbFile.exists()) {
      await Share.shareXFiles([XFile(path)], text: 'TrainerTrack AI Backup');
    }
  }
}
