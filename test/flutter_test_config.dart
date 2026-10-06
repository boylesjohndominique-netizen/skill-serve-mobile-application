import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/services/token_storage.dart';

/// Runs around every test file. Secure storage is a platform plugin, so each
/// test gets an empty in-memory stand-in, and TokenStorage re-runs its
/// one-time move of tokens left in SharedPreferences by older builds.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TokenStorage.resetForTesting();
  });
  await testMain();
}
