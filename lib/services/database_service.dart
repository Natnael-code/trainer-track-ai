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

  // --- WEB MEMORY FALLBACK STORAGE SNAPSHOTS ---
  static final List<ClientModel> _webClientsCache = [
    ClientModel(
      id: 'web_client_1',
      name: 'Alex Mercer',
      phoneNumber: '+251911223344',
      age: 24,
      gender: 'Male',
      startingWeight: 78.5,
      height: 175.0,
      experienceLevel: 'Intermediate',
      lifestyleType: 'Active',
      injuries: 'None',
      medicalConditions: 'None',
      joinedDate: DateTime.now(),
      status: 'active',
    ),
    ClientModel(
      id: 'web_client_2',
      name: 'Sara Connor',
      phoneNumber: '+251922334455',
      age: 22,
      gender: 'Female',
      startingWeight: 62.0,
      height: 168.0,
      experienceLevel: 'Advanced',
      lifestyleType: 'Sedentary',
      injuries: 'Knee Discomfort',
      medicalConditions: 'Asthma',
      joinedDate: DateTime.now(),
      status: 'active',
    ),
  ];

  static final List<GroupModel> _webGroupsCache = [
    GroupModel(
      id: 'morning_elite_shred',
      groupName: 'Morning Elite Shred',
      createdDate: DateTime.now(),
    ),
    GroupModel(
      id: 'calisthenics_advanced',
      groupName: 'Calisthenics Advanced',
      createdDate: DateTime.now(),
    ),
  ];

  static final List<ScheduleDayModel> _webSchedulesCache = [];
  static final List<WorkoutPlanModel> _webWorkoutPlansCache = [];

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
      version: 4, // Bumped to handle absoluteDate architecture safely
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
        startingBodyFat REAL,
        localProfileImagePath TEXT,
        injuries TEXT NOT NULL,
        medicalConditions TEXT NOT NULL,
        experienceLevel TEXT NOT NULL,
        lifestyleType TEXT NOT NULL,
        joinedDate TEXT NOT NULL,
        status TEXT NOT NULL,
        groupId TEXT
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
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE schedules ADD COLUMN absoluteDate TEXT NOT NULL DEFAULT "";',
        );
      } catch (_) {}
    }
  }

  // --- CLIENTS OPERATIONS ---
  Future<void> insertClient(ClientModel client) async {
    if (kIsWeb) {
      _webClientsCache.removeWhere((c) => c.id == client.id);
      _webClientsCache.add(client);
      return;
    }
    final db = await instance.database;
    await db.insert('clients', {
      'id': client.id,
      'name': client.name,
      'phoneNumber': client.phoneNumber,
      'age': client.age,
      'gender': client.gender,
      'startingWeight': client.startingWeight,
      'height': client.height,
      'startingBodyFat': client.startingBodyFat,
      'localProfileImagePath': client.localProfileImagePath,
      'injuries': client.injuries,
      'medicalConditions': client.medicalConditions,
      'experienceLevel': client.experienceLevel,
      'lifestyleType': client.lifestyleType,
      'joinedDate': client.joinedDate.toIso8601String(),
      'status': client.status,
      'groupId': client.id.contains('_group_')
          ? client.id.split('_group_')[1]
          : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ClientModel>> fetchAllClients() async {
    if (kIsWeb) return _webClientsCache;
    final db = await instance.database;
    final result = await db.query('clients', orderBy: 'name ASC');
    return result
        .map(
          (json) => ClientModel(
            id: json['id'] as String,
            name: json['name'] as String,
            phoneNumber: json['phoneNumber'] as String,
            age: json['age'] as int,
            gender: json['gender'] as String,
            startingWeight: (json['startingWeight'] as num).toDouble(),
            height: (json['height'] as num).toDouble(),
            startingBodyFat: json['startingBodyFat'] != null
                ? (json['startingBodyFat'] as num).toDouble()
                : null,
            localProfileImagePath: json['localProfileImagePath'] as String?,
            injuries: json['injuries'] as String,
            medicalConditions: json['medicalConditions'] as String,
            experienceLevel: json['experienceLevel'] as String,
            lifestyleType: json['lifestyleType'] as String,
            joinedDate: DateTime.parse(json['joinedDate'] as String),
            status: json['status'] as String,
          ),
        )
        .toList();
  }

  // --- GROUPS OPERATIONS ---
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

  // --- CALENDAR GRID ENGINE ACTIONS ---
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
      await Share.shareXFiles([XFile(path)], text: 'TrainerTrack AI Snapshot');
    }
  }
}
