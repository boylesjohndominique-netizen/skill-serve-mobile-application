import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_palette.dart';
import '../../utils/photo_picker.dart';
import '../misc/app_icon.dart';

/// Photos picked on this phone to send as proof (with a report, a dispute or
/// a support ticket): thumbnails with a remove button, and a tile to add more
/// from the camera or gallery, up to [max].
class PhotoAttachmentsField extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final bool enabled;
  final String? helper;

  const PhotoAttachmentsField({
    super.key,
    required this.paths,
    required this.onChanged,
    this.max = 5,
    this.enabled = true,
    this.helper,
  });

  Future<void> _add(BuildContext context) async {
    final picked = await pickPhotos(context, max: max - paths.length);
    if (picked.isNotEmpty) onChanged([...paths, ...picked].take(max).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helper ?? 'Optional · up to $max photos',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (var i = 0; i < paths.length; i++)
              _Thumb(
                path: paths[i],
                number: i + 1,
                onRemove: enabled ? () => onChanged([...paths]..removeAt(i)) : null,
              ),
            if (paths.length < max)
              Semantics(
                button: true,
                label: 'Add a photo',
                child: InkWell(
                  onTap: enabled ? () => _add(context) : null,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: context.accentSoftColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(AppIcons.add_photo_alternate_outlined, color: context.onAccentSoftColor, size: 22),
                        const SizedBox(height: 2),
                        Text(
                          'Add photo',
                          style: AppTextStyles.caption.copyWith(color: context.onAccentSoftColor, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final String path;
  final int number;
  final VoidCallback? onRemove;
  const _Thumb({required this.path, required this.number, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: 'Remove photo $number',
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                    child: const AppIcon(AppIcons.close_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
