import 'dart:developer' as developer;

import '../../core/services/api_service.dart';
import '../../core/utils/network_checker.dart';
import '../local/farmer_dao.dart';
import '../local/local_database.dart';
import '../models/farmer_model.dart';
import 'package:uuid/uuid.dart';

class FarmerRepository {
  Future<FarmerModel> createFarmer(
    FarmerModel farmer, {
    bool createLoginAccount = false,
    String? accountPassword,
  }) async {
    final isConnected = await NetworkChecker.isConnected();

    if (createLoginAccount && !isConnected) {
      throw Exception(
        'Internet connection is required to create a farmer login account',
      );
    }

    final id = Uuid().v4();
    final newFarmer = FarmerModel(
      id: id,
      serverId: null,
      userId: null,
      profileImagePath: farmer.profileImagePath,
      name: farmer.name,
      village: farmer.village,
      mobile: farmer.mobile,
      address: farmer.address,
      latitude: farmer.latitude,
      longitude: farmer.longitude,
      syncStatus: 'PENDING',
      createdAt: DateTime.now(),
    );

    await FarmerDao.insert(newFarmer);

    if (isConnected) {
      try {
        final response = await ApiService.post('/farmers', {
          ...newFarmer.toJson(),
          'createLoginAccount': createLoginAccount,
          'accountPassword': accountPassword,
        });
        final serverId = _extractMongoId(response.data);
        final userId = _extractLinkedUserId(response.data);

        if (serverId == null) {
          throw Exception('Unable to read MongoDB farmer ID from response');
        }

        final syncedFarmer = newFarmer.copyWith(
          serverId: serverId,
          userId: userId,
          syncStatus: 'SYNCED',
        );
        await FarmerDao.update(syncedFarmer);
        return syncedFarmer;
      } catch (e) {
        if (createLoginAccount) {
          await FarmerDao.delete(id);
          rethrow;
        }
        return newFarmer;
      }
    }

    return newFarmer;
  }

  Future<List<FarmerModel>> getAllFarmers() async {
    return await FarmerDao.getAll();
  }

  Future<void> syncPendingFarmers() async {
    final pending = await FarmerDao.getPending();
    for (var farmer in pending) {
      final existingServerId = farmer.serverId?.trim();
      if (existingServerId != null && existingServerId.isNotEmpty) {
        await FarmerDao.update(
          farmer.copyWith(
            syncStatus: 'SYNCED',
          ),
        );
        continue;
      }

      try {
        final response = await ApiService.post('/farmers', farmer.toJson());
        final serverId = _extractMongoId(response.data);
        final userId = _extractLinkedUserId(response.data);

        if (serverId == null) {
          continue;
        }

        await FarmerDao.update(
          farmer.copyWith(
            serverId: serverId,
            userId: userId,
            syncStatus: 'SYNCED',
          ),
        );
      } catch (e) {
        developer.log('Sync failed for farmer: ${farmer.id}');
      }
    }
  }

  Future<FarmerModel?> syncFarmerByLocalId(String localFarmerId) async {
    final farmer = await FarmerDao.getById(localFarmerId);

    if (farmer == null) {
      return null;
    }

    final existingServerId = farmer.serverId?.trim();
    if (existingServerId != null && existingServerId.isNotEmpty) {
      if (farmer.syncStatus != 'SYNCED') {
        final updated = farmer.copyWith(syncStatus: 'SYNCED');
        await FarmerDao.update(updated);
        return updated;
      }
      return farmer;
    }

    if (!await NetworkChecker.isConnected()) {
      return farmer;
    }

    try {
      final response = await ApiService.post('/farmers', farmer.toJson());
      final serverId = _extractMongoId(response.data);
      final userId = _extractLinkedUserId(response.data);

      if (serverId == null) {
        return farmer;
      }

      final syncedFarmer = farmer.copyWith(
        serverId: serverId,
        userId: userId ?? farmer.userId,
        syncStatus: 'SYNCED',
      );
      await FarmerDao.update(syncedFarmer);
      return syncedFarmer;
    } catch (e) {
      return farmer;
    }
  }

  Future<void> updateFarmer(FarmerModel farmer) async {
    final updatedFarmer = farmer.copyWith(syncStatus: 'PENDING');
    await FarmerDao.update(updatedFarmer);

    final serverId = updatedFarmer.serverId?.trim();
    if (!await NetworkChecker.isConnected() ||
        serverId == null ||
        serverId.isEmpty) {
      return;
    }

    try {
      final response =
          await ApiService.put('/farmers/$serverId', updatedFarmer.toJson());
      await FarmerDao.update(
        updatedFarmer.copyWith(
          userId: _extractLinkedUserId(response.data) ?? updatedFarmer.userId,
          syncStatus: 'SYNCED',
        ),
      );
    } catch (_) {
      // Keep local record as PENDING and retry on next sync cycle.
    }
  }

  Future<void> updateFarmerWithAccountOptions(
    FarmerModel farmer, {
    required bool createLoginAccount,
    String? accountPassword,
  }) async {
    final updatedFarmer = farmer.copyWith(syncStatus: 'PENDING');
    await FarmerDao.update(updatedFarmer);

    final serverId = updatedFarmer.serverId?.trim();
    if (!await NetworkChecker.isConnected() ||
        serverId == null ||
        serverId.isEmpty) {
      throw Exception(
        'Internet connection is required to update farmer login access',
      );
    }

    final response = await ApiService.put('/farmers/$serverId', {
      ...updatedFarmer.toJson(),
      'createLoginAccount': createLoginAccount,
      'accountPassword': accountPassword,
    });

    await FarmerDao.update(
      updatedFarmer.copyWith(
        userId: _extractLinkedUserId(response.data) ?? updatedFarmer.userId,
        syncStatus: 'SYNCED',
      ),
    );
  }

  Future<void> deleteFarmer(String id) async {
    final farmer = await FarmerDao.getById(id);
    final serverId = farmer?.serverId?.trim();

    if (serverId != null &&
        serverId.isNotEmpty &&
        await NetworkChecker.isConnected()) {
      try {
        await ApiService.delete('/farmers/$serverId');
      } catch (_) {
        // Local cleanup still proceeds to avoid blocking the UI.
      }
    }

    final db = await LocalDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('crops', where: 'farmerId = ?', whereArgs: [id]);
      await txn.delete('farmers', where: 'id = ?', whereArgs: [id]);
    });
  }

  String? _extractMongoId(dynamic responseData) {
    final candidates = <dynamic>[];

    if (responseData is Map<String, dynamic>) {
      candidates.add(responseData);

      final data = responseData['data'];
      candidates.add(data);

      if (data is Map<String, dynamic>) {
        candidates.add(data['farmer']);
        candidates.add(data['item']);
      }
    }

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }

      if (candidate is Map<String, dynamic>) {
        final id = candidate['_id'] ?? candidate['id'] ?? candidate['serverId'];
        if (id is String && id.isNotEmpty) {
          return id;
        }
      }
    }

    return null;
  }

  String? _extractLinkedUserId(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      final userId = data['userId'];
      if (userId is String && userId.isNotEmpty) {
        return userId;
      }
    }

    return null;
  }
}
