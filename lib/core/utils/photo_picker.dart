import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_icons.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/misc/app_icon.dart';

/// Asks whether to take a photo or choose from the gallery, and returns the
/// picked photos' paths — at most [max] (the gallery allows several when
/// [max] > 1). Empty when the user backs out.
///
/// Photos are re-encoded as JPEGs no wider than 2048 px, well inside the
/// API's 5 MB limit for attachments.
Future<List<String>> pickPhotos(BuildContext context, {int max = 1}) async {
  if (max < 1) return const [];
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const AppIcon(AppIcons.camera_alt_rounded),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const AppIcon(AppIcons.photo_library_outlined),
            title: Text(max > 1 ? 'Choose from gallery (up to $max)' : 'Choose from gallery'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return const [];

  final picker = ImagePicker();
  try {
    if (source == ImageSource.gallery && max > 1) {
      final files = await picker.pickMultiImage(imageQuality: 85, maxWidth: 2048, limit: max);
      return [for (final file in files.take(max)) file.path];
    }
    final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 2048);
    return file == null ? const [] : [file.path];
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.error(
        context,
        source == ImageSource.camera ? 'The camera could not be opened.' : 'The gallery could not be opened.',
      );
    }
    return const [];
  }
}
