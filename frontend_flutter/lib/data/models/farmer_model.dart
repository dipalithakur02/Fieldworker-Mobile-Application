class FarmerModel {
  final String? id;
  final String? serverId;
  final String? userId;
  final String? profileImagePath;
  final String name;
  final String village;
  final String mobile;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String syncStatus;
  final DateTime? createdAt;

  FarmerModel({
    this.id,
    this.serverId,
    this.userId,
    this.profileImagePath,
    required this.name,
    required this.village,
    required this.mobile,
    this.address,
    this.latitude,
    this.longitude,
    this.syncStatus = 'PENDING',
    this.createdAt,
  });

  /// API / MongoDB → Model
  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id: json['id'] ?? json['_id'],
      serverId: json['serverId'] ?? json['_id'],
      userId: json['userId'] is Map<String, dynamic>
          ? (json['userId']['_id'] ?? json['userId']['id'])
          : json['userId'],
      profileImagePath: json['profileImagePath'],
      name: json['name'],
      village: json['village'],
      mobile: json['mobile'],
      address: json['address'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      syncStatus: json['syncStatus'] ?? 'SYNCED',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  /// SQLite → Model
  factory FarmerModel.fromMap(Map<String, dynamic> map) {
    return FarmerModel(
      id: map['id'],
      serverId: map['serverId'],
      userId: map['userId'],
      profileImagePath: map['profileImagePath'],
      name: map['name'],
      village: map['village'],
      mobile: map['mobile'],
      address: map['address'],
      latitude:
          map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      syncStatus: map['syncStatus'] ?? 'PENDING',
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  /// Model → API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userId': userId,
      'village': village,
      'mobile': mobile,
      if (profileImagePath != null && profileImagePath!.isNotEmpty)
        'profileImagePath': profileImagePath,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'syncStatus': syncStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Model → SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serverId': serverId,
      'userId': userId,
      'profileImagePath': profileImagePath,
      'name': name,
      'village': village,
      'mobile': mobile,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'syncStatus': syncStatus,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Helpful for updates
  FarmerModel copyWith({
    String? id,
    String? serverId,
    String? userId,
    String? profileImagePath,
    String? name,
    String? village,
    String? mobile,
    String? address,
    double? latitude,
    double? longitude,
    String? syncStatus,
    DateTime? createdAt,
  }) {
    return FarmerModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      name: name ?? this.name,
      village: village ?? this.village,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
