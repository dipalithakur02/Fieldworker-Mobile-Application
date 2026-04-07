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
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE farmers (
        id TEXT PRIMARY KEY,
        serverId TEXT,
        userId TEXT,
        profileImagePath TEXT,
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
        serverId TEXT,
        farmerId TEXT NOT NULL,
        cropName TEXT NOT NULL,
        cropType TEXT NOT NULL,
        area REAL NOT NULL,
        season TEXT NOT NULL,
        sowingDate TEXT NOT NULL,
        imagePath TEXT,
        syncStatus TEXT DEFAULT 'PENDING',
        FOREIGN KEY (farmerId) REFERENCES farmers (id) ON DELETE CASCADE
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

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE crops RENAME TO crops_old');
      await db.execute('''
        CREATE TABLE crops (
          id TEXT PRIMARY KEY,
          serverId TEXT,
          farmerId TEXT NOT NULL,
          cropName TEXT NOT NULL,
          cropType TEXT NOT NULL,
          area REAL NOT NULL,
          season TEXT NOT NULL,
          sowingDate TEXT NOT NULL,
          imagePath TEXT,
          syncStatus TEXT DEFAULT 'PENDING',
          FOREIGN KEY (farmerId) REFERENCES farmers (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        INSERT INTO crops (
          id,
          serverId,
          farmerId,
          cropName,
          cropType,
          area,
          season,
          sowingDate,
          imagePath,
          syncStatus
        )
        SELECT
          id,
          NULL,
          farmerId,
          cropName,
          cropType,
          area,
          season,
          sowingDate,
          imagePath,
          syncStatus
        FROM crops_old
        WHERE farmerId IN (SELECT id FROM farmers)
      ''');
      await db.execute('DROP TABLE crops_old');
    }

    if (oldVersion >= 3 && oldVersion < 4) {
      await db.execute('ALTER TABLE crops ADD COLUMN serverId TEXT');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE farmers ADD COLUMN userId TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE farmers ADD COLUMN profileImagePath TEXT');
    }
  }
}
