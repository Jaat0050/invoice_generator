class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'owner', 'admin', 'staff'
  final DateTime? emailVerifiedAt;
  final bool isActive;
  final bool isDeleted;

  // Convenience getter for isDelete
  bool get isDelete => isDeleted;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'owner',
    this.emailVerifiedAt,
    this.isActive = true,
    this.isDeleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '') ?? json['id']?.hashCode ?? 1),
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      role: (json['role'] as String?) ?? 'owner',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'] as String)
          : null,
      isActive: (json['is_active'] as bool?) ?? true,
      isDeleted: (json['is_deleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'is_active': isActive,
      'is_deleted': isDeleted,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? emailVerifiedAt,
    bool? isActive,
    bool? isDeleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

