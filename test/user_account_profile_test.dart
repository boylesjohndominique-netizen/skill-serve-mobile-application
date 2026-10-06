import 'package:flutter_test/flutter_test.dart';

import 'package:skillserve_mobile/features/auth/models/user_model.dart';

void main() {
  final user = UserModel(
    id: 'CL-1',
    role: UserRole.client,
    firstName: 'Andrea',
    lastName: 'Santos',
    email: 'andrea@example.com',
    createdAt: DateTime(2025, 1, 1),
  );

  test('profile copyWith updates permitted fields and preserves account data',
      () {
    final updated = user.copyWith(
      firstName: 'Mia',
      profilePicture: '/tmp/avatar.jpg',
      status: 'suspended',
    );

    expect(updated.firstName, 'Mia');
    expect(updated.lastName, user.lastName);
    expect(updated.email, user.email);
    expect(updated.profilePicture, '/tmp/avatar.jpg');
    expect(updated.status, 'suspended');
  });

  test('a profile from the API carries the photo URL the avatar renders', () {
    // Mirrors ClientUserResource: `profile_picture` is an absolute URL, or
    // null when no photo is set.
    final parsed = UserModel.fromJson(const {
      'id': 7,
      'role_id': 4,
      'first_name': 'Andrea',
      'last_name': 'Santos',
      'email': 'andrea@example.com',
      'phone': '09171234567',
      'address': '123 Mabini St',
      'profile_picture': 'https://api.example.com/storage/profile-photos/a.jpg',
      'status': 'active',
    });

    expect(parsed.role, UserRole.client);
    expect(parsed.phone, '09171234567');
    expect(parsed.address, '123 Mabini St');
    expect(parsed.profilePicture,
        'https://api.example.com/storage/profile-photos/a.jpg');
  });

  test('a profile with no photo falls back to initials', () {
    final parsed = UserModel.fromJson(const {
      'id': 8,
      'role_id': 4,
      'first_name': 'Andrea',
      'last_name': 'Santos',
      'email': 'andrea@example.com',
      'profile_picture': null,
    });

    expect(parsed.profilePicture, isNull);
    expect(parsed.initials, 'AS');
  });
}
