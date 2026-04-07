import '../local/local_database.dart';
import '../models/crop_model.dart';

class CropDao {
  static Future<int> insert(CropModel crop) async {
    final db = await LocalDatabase.database;
    return await db.insert('crops', crop.toMap());
  }

  static Future<List<CropModel>> getAll() async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query('crops');
    return List.generate(maps.length, (i) => CropModel.fromMap(maps[i]));
  }

  static Future<List<CropModel>> getByFarmerId(String farmerId) async {
    final db = await LocalDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'crops',
      where: 'farmerId = ?',
      whereArgs: [farmerId],
    );
    return List.generate(maps.length, (i) => CropModel.fromMap(maps[i]));
  }

  static Future<CropModel?> getById(String id) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'crops',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return CropModel.fromMap(maps.first);
  }

  static Future<int> update(CropModel crop) async {
    final db = await LocalDatabase.database;
    return await db.update(
      'crops',
      crop.toMap(),
      where: 'id = ?',
      whereArgs: [crop.id],
    );
  }

  static Future<int> delete(String id) async {
    final db = await LocalDatabase.database;
    return await db.delete('crops', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<CropModel>> getPending() async {
    final db = await LocalDatabase.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'crops',
      where: 'syncStatus = ?',
      whereArgs: ['PENDING'],
    );

    return List.generate(maps.length, (i) {
      return CropModel.fromMap(maps[i]);
    });
  }

  static Future<void> updateSyncStatus(String id, String status) async {
    final db = await LocalDatabase.database;
    await db.update(
      'crops',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
