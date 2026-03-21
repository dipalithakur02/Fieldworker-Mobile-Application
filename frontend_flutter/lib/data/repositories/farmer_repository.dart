import '../../core/services/api_service.dart';
import '../../core/utils/network_checker.dart';
import '../local/farmer_dao.dart';
import '../models/farmer_model.dart';
import 'package:uuid/uuid.dart';

class FarmerRepository {
  Future<FarmerModel> createFarmer(FarmerModel farmer) async {
    final id = Uuid().v4();
    final newFarmer = FarmerModel(
      id: id,
      serverId: null,
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

    if (await NetworkChecker.isConnected()) {
      try {
        final response = await ApiService.post('/farmers', newFarmer.toJson());
        final serverId = _extractMongoId(response.data);

        if (serverId == null) {
          throw Exception('Unable to read MongoDB farmer ID from response');
        }

        final syncedFarmer = newFarmer.copyWith(
          serverId: serverId,
          syncStatus: 'SYNCED',
        );
        await FarmerDao.update(syncedFarmer);
        return syncedFarmer;
      } catch (e) {
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

        if (serverId == null) {
          continue;
        }

        await FarmerDao.update(
          farmer.copyWith(
            serverId: serverId,
            syncStatus: 'SYNCED',
          ),
        );
      } catch (e) {
        print('Sync failed for farmer: ${farmer.id}');
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

      if (serverId == null) {
        return farmer;
      }

      final syncedFarmer = farmer.copyWith(
        serverId: serverId,
        syncStatus: 'SYNCED',
      );
      await FarmerDao.update(syncedFarmer);
      return syncedFarmer;
    } catch (e) {
      return farmer;
    }
  }

  Future<void> updateFarmer(FarmerModel farmer) async {
    await FarmerDao.update(farmer);
  }

  Future<void> deleteFarmer(String id) async {
    await FarmerDao.delete(id);
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
}
