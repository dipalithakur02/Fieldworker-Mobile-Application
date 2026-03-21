import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';


class LocalDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE farmers (
        id TEXT PRIMARY KEY,
        serverId TEXT,
        name TEXT NOT NULL,
        village TEXT NOT NULL,
        mobile TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        syncStatus TEXT DEFAULT 'PENDING',
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crops (
        id TEXT PRIMARY KEY,
        farmerId TEXT NOT NULL,
        cropName TEXT NOT NULL,
        cropType TEXT NOT NULL,
        area REAL NOT NULL,
        season TEXT NOT NULL,
        sowingDate TEXT NOT NULL,
        imagePath TEXT,
        syncStatus TEXT DEFAULT 'PENDING',
        FOREIGN KEY (farmerId) REFERENCES farmers (id)
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE farmers ADD COLUMN serverId TEXT',
      );
    }
  }
}
