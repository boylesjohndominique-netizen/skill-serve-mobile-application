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
  final String? profilePicture;
  final String status;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    this.address = '',
    this.profilePicture,
    this.status = 'active',
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  /// Placeholder — maps a future `GET /me` / `GET /users/:id` JSON payload.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        role: UserRole.values.byName(json['role'] as String? ?? 'client'),
        firstName: json['firstname'] as String? ?? '',
        lastName: json['lastname'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        profilePicture: json['profile_picture'] as String?,
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phone': phone,
        'address': address,
        'profile_picture': profilePicture,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
