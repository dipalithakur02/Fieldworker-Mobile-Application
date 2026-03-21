import '../local/local_database.dart';
import '../models/farmer_model.dart';

class FarmerDao {
  static Future<int> insert(FarmerModel farmer) async {
    final db = await LocalDatabase.database;
    return await db.insert('farmers', farmer.toMap());
  }

  static Future<List<FarmerModel>> getAll() async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('farmers');
    return List.generate(maps.length, (i) => FarmerModel.fromMap(maps[i]));
  }

  static Future<FarmerModel?> getById(String id) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'farmers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FarmerModel.fromMap(maps.first);
  }

  static Future<List<FarmerModel>> getPending() async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'farmers',
      where: 'syncStatus = ?',
      whereArgs: ['PENDING'],
    );
    return List.generate(maps.length, (i) => FarmerModel.fromMap(maps[i]));
  }

  static Future<int> update(FarmerModel farmer) async {
    final db = await LocalDatabase.database;
    return await db.update(
      'farmers',
      farmer.toMap(),
      where: 'id = ?',
      whereArgs: [farmer.id],
    );
  }

  static Future<int> delete(String id) async {
    final db = await LocalDatabase.database;
    return await db.delete('farmers', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateSyncStatus(String id, String status) async {
    final db = await LocalDatabase.database;
    await db.update(
      'farmers',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
