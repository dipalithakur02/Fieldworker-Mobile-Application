class QueryModel {
  final String id;
  final String farmerId;
  final String cropId;
  final String? fieldworkerId;
  final String description;
  final String status;
  final String? resolutionNote;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final String? farmerName;
  final String? farmerVillage;
  final String? farmerMobile;
  final String? cropName;
  final String? cropType;
  final String? cropSeason;

  QueryModel({
    required this.id,
    required this.farmerId,
    required this.cropId,
    this.fieldworkerId,
    required this.description,
    required this.status,
    this.resolutionNote,
    this.resolvedAt,
    this.createdAt,
    this.farmerName,
    this.farmerVillage,
    this.farmerMobile,
    this.cropName,
    this.cropType,
    this.cropSeason,
  });

  bool get isResolved => status == 'RESOLVED';

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    final farmerValue = json['farmerId'];
    final cropValue = json['cropId'];

    return QueryModel(
      id: json['_id'] ?? json['id'] ?? '',
      farmerId: farmerValue is Map<String, dynamic>
          ? (farmerValue['_id'] ?? farmerValue['id'] ?? '')
          : farmerValue ?? '',
      cropId: cropValue is Map<String, dynamic>
          ? (cropValue['_id'] ?? cropValue['id'] ?? '')
          : cropValue ?? '',
      fieldworkerId: json['fieldworkerId']?.toString(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'OPEN',
      resolutionNote: json['resolutionNote'],
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      farmerName:
          farmerValue is Map<String, dynamic> ? farmerValue['name'] : null,
      farmerVillage:
          farmerValue is Map<String, dynamic> ? farmerValue['village'] : null,
      farmerMobile:
          farmerValue is Map<String, dynamic> ? farmerValue['mobile'] : null,
      cropName:
          cropValue is Map<String, dynamic> ? cropValue['cropName'] : null,
      cropType:
          cropValue is Map<String, dynamic> ? cropValue['cropType'] : null,
      cropSeason:
          cropValue is Map<String, dynamic> ? cropValue['season'] : null,
    );
  }
}
