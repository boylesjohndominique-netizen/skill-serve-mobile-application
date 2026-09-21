import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/feedback/app_snackbar.dart';
import '../controllers/favorites_controller.dart';
import '../models/provider_model.dart';

/// The heart button's action on every screen that shows one: save or remove
/// [provider], and explain when that did not work (signed out, offline, …).
Future<void> toggleFavorite(BuildContext context, ProviderModel provider) async {
  final favorites = context.read<FavoritesController>();
  final ok = await favorites.toggle(provider);
  if (!ok && context.mounted) {
    AppSnackbar.error(context, favorites.errorMessage ?? 'That did not work. Please try again.');
  }
}
