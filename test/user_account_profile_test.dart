import 'package:flutter_test/flutter_test.dart';

import 'package:skilllink_mobile/features/auth/models/user_model.dart';
import 'package:skilllink_mobile/features/profile/services/profile_service.dart';

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

  test('profile service persists a selected photo in the mock profile result',
      () async {
    final updated = await ProfileService().updateProfile(
      user,
      profilePicture: '/tmp/avatar.jpg',
    );

    expect(updated.profilePicture, '/tmp/avatar.jpg');
    expect(updated.id, user.id);
    expect(updated.role, user.role);
  });
}
