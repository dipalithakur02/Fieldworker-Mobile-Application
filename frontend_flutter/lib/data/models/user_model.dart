class UserModel {
  final String? id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? farmerId;
  final String? profileImagePath;
  final String? token;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.farmerId,
    this.profileImagePath,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'fieldworker',
      phone: json['phone'] ?? json['mobile'],
      farmerId: json['farmerId'],
      profileImagePath: json['profileImagePath'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'farmerId': farmerId,
      'profileImagePath': profileImagePath,
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? farmerId,
    String? profileImagePath,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      farmerId: farmerId ?? this.farmerId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      token: token ?? this.token,
    );
  }
}
