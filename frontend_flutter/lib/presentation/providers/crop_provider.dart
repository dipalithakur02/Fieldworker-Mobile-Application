import 'package:flutter/material.dart';
import '../../data/models/crop_model.dart';
import '../../data/repositories/crop_repository.dart';

class CropProvider with ChangeNotifier {
  final CropRepository _repository = CropRepository();
  List<CropModel> _crops = [];
  bool _isLoading = false;

  List<CropModel> get crops => _crops;
  bool get isLoading => _isLoading;

  Future<void> loadCrops() async {
    _isLoading = true;
    notifyListeners();

    try {
      _crops = await _repository.getAllCrops();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCropsByFarmer(String farmerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _crops = await _repository.getCropsByFarmer(farmerId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCrop(CropModel crop) async {
    await _repository.createCrop(crop);
    await loadCrops();
  }

  Future<void> updateCrop(CropModel crop) async {
    await _repository.updateCrop(crop);
    await loadCropsByFarmer(crop.farmerId);
  }
}
