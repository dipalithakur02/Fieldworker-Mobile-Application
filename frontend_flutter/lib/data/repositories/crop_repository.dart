import '../../core/services/api_service.dart';
import '../../core/utils/network_checker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../local/crop_dao.dart';
import '../local/farmer_dao.dart';
import '../models/crop_model.dart';
import 'farmer_repository.dart';
import 'package:uuid/uuid.dart';

class CropRepository {
  static final RegExp _objectIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');
  final FarmerRepository _farmerRepository = FarmerRepository();

  Future<CropModel> createCrop(CropModel crop) async {
    final id = Uuid().v4();
    final newCrop = CropModel(
      id: id,
      serverId: null,
      farmerId: crop.farmerId,
      cropName: crop.cropName,
      cropType: crop.cropType,
      area: crop.area,
      season: crop.season,
      sowingDate: crop.sowingDate,
      imagePath: crop.imagePath,
      syncStatus: 'PENDING',
    );

    await CropDao.insert(newCrop);

    if (await NetworkChecker.isConnected()) {
      try {
        final serverId = await _postCrop(newCrop);
        if (serverId == null || serverId.isEmpty) {
          throw Exception('Unable to read MongoDB crop ID from response');
        }
        final syncedCrop = newCrop.copyWith(
          serverId: serverId,
          syncStatus: 'SYNCED',
        );
        await CropDao.update(syncedCrop);
        return syncedCrop;
      } catch (e) {
        return newCrop;
      }
    }

    return newCrop;
  }

  Future<void> syncPendingCrops() async {
    final pendingCrops = await CropDao.getPending();

    for (final crop in pendingCrops) {
      try {
        final serverId = crop.serverId?.trim().isNotEmpty == true
            ? crop.serverId
            : await _postCrop(crop);
        if (serverId == null || serverId.isEmpty) {
          continue;
        }
        await CropDao.update(
          crop.copyWith(
            serverId: serverId,
            syncStatus: 'SYNCED',
          ),
        );
      } catch (e) {
        // Keep as PENDING; it will retry on next sync cycle.
      }
    }
  }

  Future<List<CropModel>> getCropsByFarmer(String farmerId) async {
    return await CropDao.getByFarmerId(farmerId);
  }

  Future<List<CropModel>> getAllCrops() async {
    return await CropDao.getAll();
  }

  Future<List<CropModel>> fetchAssignedCrops() async {
    final response = await ApiService.get('/crops');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CropModel.fromJson)
        .toList();
  }

  Future<void> updateCrop(CropModel crop) async {
    final hasServerId = crop.serverId?.trim().isNotEmpty == true;
    final shouldAttemptRemoteSync = hasServerId || crop.syncStatus != 'SYNCED';
    final updatedCrop = crop.copyWith(
      syncStatus: shouldAttemptRemoteSync ? 'PENDING' : crop.syncStatus,
    );
    await CropDao.update(updatedCrop);

    final serverId = updatedCrop.serverId?.trim();
    if (!shouldAttemptRemoteSync ||
        !await NetworkChecker.isConnected() ||
        serverId == null ||
        serverId.isEmpty) {
      return;
    }

    try {
      await _putCrop(updatedCrop, serverId);
      await CropDao.update(updatedCrop.copyWith(syncStatus: 'SYNCED'));
    } catch (_) {
      // Keep as PENDING and retry later.
    }
  }

  Future<void> deleteCrop(String id) async {
    final crop = await CropDao.getById(id);
    final serverId = crop?.serverId?.trim();

    if (serverId != null &&
        serverId.isNotEmpty &&
        await NetworkChecker.isConnected()) {
      try {
        await ApiService.delete('/crops/$serverId');
      } catch (_) {
        // Local delete should not be blocked by a remote failure.
      }
    }

    await CropDao.delete(id);
  }

  Future<String?> _postCrop(CropModel crop) async {
    final apiFarmerId = await _resolveApiFarmerId(crop.farmerId);

    final payload = {
      'farmerId': apiFarmerId,
      'cropName': crop.cropName,
      'cropType': crop.cropType,
      'area': crop.area.toString(),
      'season': crop.season,
      'sowingDate': crop.sowingDate.toIso8601String(),
    };

    final formData = FormData.fromMap(payload);
    final imagePath = crop.imagePath?.trim();

    if (imagePath != null && imagePath.isNotEmpty) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imagePath),
          ),
        );
      }
    }

    final response = await ApiService.post('/crops', formData);
    return _extractMongoId(response.data);
  }

  Future<void> _putCrop(CropModel crop, String serverId) async {
    final apiFarmerId = await _resolveApiFarmerId(crop.farmerId);

    final payload = {
      'farmerId': apiFarmerId,
      'cropName': crop.cropName,
      'cropType': crop.cropType,
      'area': crop.area.toString(),
      'season': crop.season,
      'sowingDate': crop.sowingDate.toIso8601String(),
    };

    final imagePath = crop.imagePath?.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final formData = FormData.fromMap(payload);
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imagePath),
          ),
        );
        await ApiService.put('/crops/$serverId', formData);
        return;
      }
    }

    await ApiService.put('/crops/$serverId', payload);
  }

  Future<String> _resolveApiFarmerId(String farmerId) async {
    final farmer = await FarmerDao.getById(farmerId);

    if (farmer == null) {
      if (_objectIdPattern.hasMatch(farmerId)) {
        return farmerId;
      }
      throw Exception('Farmer not found locally for ID: $farmerId');
    }

    final serverId = farmer.serverId?.trim();
    if (serverId != null && serverId.isNotEmpty) {
      return serverId;
    }

    if (await NetworkChecker.isConnected() && farmer.id != null) {
      final syncedFarmer =
          await _farmerRepository.syncFarmerByLocalId(farmer.id!);
      final syncedServerId = syncedFarmer?.serverId?.trim();
      if (syncedServerId != null && syncedServerId.isNotEmpty) {
        return syncedServerId;
      }
    }

    throw Exception('Farmer must be synced to MongoDB before syncing crops');
  }

  String? _extractMongoId(dynamic responseData) {
    final candidates = <dynamic>[];

    if (responseData is Map<String, dynamic>) {
      candidates.add(responseData);

      final data = responseData['data'];
      candidates.add(data);

      if (data is Map<String, dynamic>) {
        candidates.add(data['crop']);
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
