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
        await _postCrop(newCrop);
        final syncedCrop = newCrop.copyWith(syncStatus: 'SYNCED');
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
        await _postCrop(crop);
        await CropDao.updateSyncStatus(crop.id!, 'SYNCED');
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

  Future<void> updateCrop(CropModel crop) async {
    await CropDao.update(crop);
  }

  Future<void> deleteCrop(String id) async {
    await CropDao.delete(id);
  }

  Future<void> _postCrop(CropModel crop) async {
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

    await ApiService.post('/crops', formData);
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
      final syncedFarmer = await _farmerRepository.syncFarmerByLocalId(farmer.id!);
      final syncedServerId = syncedFarmer?.serverId?.trim();
      if (syncedServerId != null && syncedServerId.isNotEmpty) {
        return syncedServerId;
      }
    }

    throw Exception('Farmer must be synced to MongoDB before syncing crops');
  }
}
