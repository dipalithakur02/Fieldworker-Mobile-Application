import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/crop_model.dart';
import '../../data/repositories/crop_repository.dart';

class CropsScreen extends StatefulWidget {
  final String? farmerId;

  const CropsScreen({super.key, this.farmerId});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final CropRepository _repository = CropRepository();
  List<CropModel> _crops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    final crops = widget.farmerId == null
        ? await _repository.getAllCrops()
        : await _repository.getCropsByFarmer(widget.farmerId!);

    setState(() {
      _crops = crops;
      _loading = false;
    });
  }

  Future<void> _deleteCrop(String id) async {
    await _repository.deleteCrop(id);
    _loadCrops();
  }

  Widget _buildCropCard(CropModel crop) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(AppConstants.primaryColor),
          child: const Icon(Icons.grass, color: Colors.white),
        ),
        title: Text(
          crop.cropName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${crop.cropType} • ${crop.area} acres",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              if (crop.id == null) return;
              _deleteCrop(crop.id!);
            }
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.secondaryColor).withOpacity(0.1),
      appBar: AppBar(
        title: Text(widget.farmerId == null ? "Crops" : "Farmer Crops"),
        backgroundColor: const Color(AppConstants.primaryColor),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _crops.isEmpty
          ? const Center(
        child: Text(
          "No crops found",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: _crops.length,
        itemBuilder: (context, index) {
          return _buildCropCard(_crops[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(AppConstants.primaryColor),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/farmers');
        },
      ),
    );
  }
}