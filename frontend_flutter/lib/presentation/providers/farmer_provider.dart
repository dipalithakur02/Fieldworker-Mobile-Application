import 'package:flutter/material.dart';
import '../../data/models/farmer_model.dart';
import '../../data/repositories/farmer_repository.dart';

class FarmerProvider with ChangeNotifier {
  final FarmerRepository _repository = FarmerRepository();
  List<FarmerModel> _farmers = [];
  bool _isLoading = false;

  List<FarmerModel> get farmers => _farmers;
  bool get isLoading => _isLoading;

  Future<void> loadFarmers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _farmers = await _repository.getAllFarmers();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFarmer(
    FarmerModel farmer, {
    bool createLoginAccount = false,
    String? accountPassword,
  }) async {
    await _repository.createFarmer(
      farmer,
      createLoginAccount: createLoginAccount,
      accountPassword: accountPassword,
    );
    await loadFarmers();
  }

  Future<void> updateFarmer(
    FarmerModel farmer, {
    bool createLoginAccount = false,
    String? accountPassword,
  }) async {
    if (createLoginAccount) {
      await _repository.updateFarmerWithAccountOptions(
        farmer,
        createLoginAccount: createLoginAccount,
        accountPassword: accountPassword,
      );
    } else {
      await _repository.updateFarmer(farmer);
    }
    await loadFarmers();
  }

  Future<void> deleteFarmer(String farmerId) async {
    await _repository.deleteFarmer(farmerId);
    _farmers = _farmers.where((farmer) => farmer.id != farmerId).toList();
    notifyListeners();
  }

  Future<void> syncFarmers() async {
    await _repository.syncPendingFarmers();
    await loadFarmers();
  }
}
