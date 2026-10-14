import 'package:flutter/material.dart';

import '../../constants/app_text_styles.dart';
import '../../theme/app_palette.dart';

/// "On a job now": the provider is working a booking in progress. Shown on
/// provider cards and the profile so a customer knows before booking — it
/// never stops them booking or messaging.
class OnJobBadge extends StatelessWidget {
  /// Adds "— you can still book" for the profile, where there is room.
  final bool long;

  const OnJobBadge({super.key, this.long = false});

  @override
  Widget build(BuildContext context) {
    final color = context.warningColor;

    return Semantics(
      label: 'This provider is on a job right now',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              long ? 'On a job right now — you can still book or message' : 'On a job now',
              style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w600),
              maxLines: long ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
