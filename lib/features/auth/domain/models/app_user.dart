import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported RBAC user & donor roles matching Firebase Auth custom claims.
enum UserRole {
  donor('individual_donor', 'Individual Donor'),
  corporateDonor('corporate_donor', 'Corporate Donor'),
  partnerNgo('partner_ngo', 'Partner NGO'),
  admin('admin', 'Admin');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'individual_donor':
      case 'donor':
        return UserRole.donor;
      case 'corporate_donor':
      case 'corporate_sponsor':
        return UserRole.corporateDonor;
      case 'partner_ngo':
      case 'field_agent':
        return UserRole.partnerNgo;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.donor;
    }
  }
}

/// Domain model for `users/{userId}` document in Cloud Firestore.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? panOrTaxId;
  final bool verified;
  final num totalContributed;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.panOrTaxId,
    required this.verified,
    required this.totalContributed,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, {String? id}) {
    return AppUser(
      uid: id ?? (json['uid'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      panOrTaxId: json['pan_or_tax_id'] as String?,
      verified: json['verified'] as bool? ?? false,
      totalContributed: json['totalContributed'] as num? ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'pan_or_tax_id': panOrTaxId,
      'verified': verified,
      'totalContributed': totalContributed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? panOrTaxId,
    bool? verified,
    num? totalContributed,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      panOrTaxId: panOrTaxId ?? this.panOrTaxId,
      verified: verified ?? this.verified,
      totalContributed: totalContributed ?? this.totalContributed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.now();
  }
}
