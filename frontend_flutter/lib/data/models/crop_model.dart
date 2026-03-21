class CropModel {
  final String? id;
  final String farmerId;
  final String cropName;
  final String cropType;
  final double area;
  final String season;
  final DateTime sowingDate;
  final String? imagePath;
  final String syncStatus;

  CropModel({
    this.id,
    required this.farmerId,
    required this.cropName,
    required this.cropType,
    required this.area,
    required this.season,
    required this.sowingDate,
    this.imagePath,
    this.syncStatus = 'PENDING',
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    final farmerValue = json['farmerId'];

    return CropModel(
      id: json['_id'] ?? json['id'],
      farmerId: farmerValue is Map<String, dynamic>
          ? (farmerValue['_id'] ?? farmerValue['id'] ?? '')
          : farmerValue,
      cropName: json['cropName'],
      cropType: json['cropType'],
      area: json['area'].toDouble(),
      season: json['season'],
      sowingDate: DateTime.parse(json['sowingDate']),
      imagePath: json['imagePath'],
      syncStatus: json['syncStatus'] ?? 'SYNCED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'cropName': cropName,
      'cropType': cropType,
      'area': area,
      'season': season,
      'sowingDate': sowingDate.toIso8601String(),
      'imagePath': imagePath,
      'syncStatus': syncStatus,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'cropName': cropName,
      'cropType': cropType,
      'area': area,
      'season': season,
      'sowingDate': sowingDate.toIso8601String(),
      'imagePath': imagePath,
      'syncStatus': syncStatus,
    };
  }

  factory CropModel.fromMap(Map<String, dynamic> map) {
    return CropModel(
      id: map['id'],
      farmerId: map['farmerId'],
      cropName: map['cropName'],
      cropType: map['cropType'],
      area: (map['area'] as num).toDouble(),
      season: map['season'],
      sowingDate: DateTime.parse(map['sowingDate']),
      imagePath: map['imagePath'],
      syncStatus: map['syncStatus'] ?? 'PENDING',
    );
  }

  CropModel copyWith({
    String? id,
    String? farmerId,
    String? cropName,
    String? cropType,
    double? area,
    String? season,
    DateTime? sowingDate,
    String? imagePath,
    String? syncStatus,
  }) {
    return CropModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropName: cropName ?? this.cropName,
      cropType: cropType ?? this.cropType,
      area: area ?? this.area,
      season: season ?? this.season,
      sowingDate: sowingDate ?? this.sowingDate,
      imagePath: imagePath ?? this.imagePath,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

}
