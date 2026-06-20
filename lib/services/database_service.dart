import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client_model.dart';

class DatabaseService {
  // Singleton pattern architecture
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trainer_track.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Define SQL Schema Table on first creation execution
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
        status TEXT NOT NULL
      )
    ''');
  }

  // --- CRUD FUNCTIONS ---

  Future<void> insertClient(ClientModel client) async {
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ClientModel>> fetchAllClients() async {
    final db = await instance.database;
    final orderBy = 'name ASC';
    final result = await db.query('clients', orderBy: orderBy);

    return result
        .map(
          (json) => ClientModel(
            id: json['id'] as String,
            name: json['name'] as String,
            phoneNumber: json['phoneNumber'] as String,
            age: json['age'] as int,
            gender: json['gender'] as String,
            startingWeight: json['startingWeight'] as double,
            height: json['height'] as double,
            startingBodyFat: json['startingBodyFat'] as double?,
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

  // --- DATA SAFETY PROTOCOL: BACKUP ENGINE ---

  Future<void> exportDatabaseBackup() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trainer_track.db');
    final dbFile = File(path);

    if (await dbFile.exists()) {
      // Open Android native share sheet allowing transmission to Google Drive, Telegram, Email, etc.
      await Share.shareXFiles([
        XFile(path),
      ], text: 'TrainerTrack AI System Safety Backup File (Keep Secure)');
    }
  }
}
