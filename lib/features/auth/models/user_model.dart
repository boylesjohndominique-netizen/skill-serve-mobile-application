import '../../locations/models/ph_address.dart';
/// Mirrors the `users` table. Shared by both Client and Provider accounts;
/// [UserRole] narrows behavior across the app.
enum UserRole { guest, client, provider, admin }

class UserModel {
  final String id;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;

  /// [address] as Region → Province → City → Barangay, to pre-fill the
  /// picker; null when only free text was ever entered.
  final PhAddress? addressDetails;
  final String? profilePicture;
  final String status;
  final DateTime createdAt;

  /// Provider accounts only: verification state and an administrator's
  /// suspension, which applies while the account itself stays active (M 9.6).
  final String? providerVerificationStatus;
  final bool providerSuspended;
  final String? providerSuspensionReason;

  const UserModel({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    this.address = '',
    this.addressDetails,
    this.profilePicture,
    this.status = 'active',
    required this.createdAt,
    this.providerVerificationStatus,
    this.providerSuspended = false,
    this.providerSuspensionReason,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    PhAddress? addressDetails,
    bool clearAddressDetails = false,
    String? profilePicture,
    bool clearProfilePicture = false,
    String? status,
  }) =>
      UserModel(
        id: id,
        role: role,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        addressDetails: clearAddressDetails ? null : addressDetails ?? this.addressDetails,
        profilePicture:
            clearProfilePicture ? null : profilePicture ?? this.profilePicture,
        status: status ?? this.status,
        createdAt: createdAt,
        providerVerificationStatus: providerVerificationStatus,
        providerSuspended: providerSuspended,
        providerSuspensionReason: providerSuspensionReason,
      );

  /// Maps the `GET /api/client/v1/auth/me` payload, or a session cached by
  /// [toJson].
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = roleFromJson(json);
    final provider = json['provider'] is Map ? Map<String, dynamic>.from(json['provider'] as Map) : null;
    return UserModel(
      id: json['id'].toString(),
      role: role,
      firstName: (json['first_name'] ?? json['firstname']) as String? ?? '',
      lastName: (json['last_name'] ?? json['lastname']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      addressDetails: PhAddress.fromJson(json['address_details']),
      profilePicture: json['profile_picture'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      providerVerificationStatus: provider?['verification_status'] as String?,
      providerSuspended: provider?['suspended'] == true,
      providerSuspensionReason: provider?['suspension_reason'] as String?,
    );
  }

  /// Account role from the API (`role_id`: 1 super-admin, 2 admin,
  /// 3 provider, 4 customer; or `role_name`/`user_type`), or from a session
  /// saved by [toJson] (`role`: guest/client/provider/admin).
  static UserRole roleFromJson(Map<String, dynamic> json) {
    final roleId = int.tryParse('${json['role_id'] ?? ''}');
    if (roleId != null) {
      return switch (roleId) {
        3 => UserRole.provider,
        4 => UserRole.client,
        _ => UserRole.admin,
      };
    }

    final name = (json['role_name'] ?? json['role'] ?? json['user_type'])?.toString();
    return switch (name) {
      'provider' => UserRole.provider,
      'super-admin' || 'admin' => UserRole.admin,
      'guest' => UserRole.guest,
      _ => UserRole.client,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'role_id': switch (role) {
          UserRole.provider => 3,
          UserRole.client => 4,
          UserRole.admin => 2,
          UserRole.guest => null,
        },
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phone': phone,
        'address': address,
        'address_details': addressDetails?.toJson(),
        'profile_picture': profilePicture,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        if (role == UserRole.provider)
          'provider': {
            'verification_status': providerVerificationStatus,
            'suspended': providerSuspended,
            'suspension_reason': providerSuspensionReason,
          },
      };
}
