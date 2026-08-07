import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../models/booking_model.dart';
import '../misc/status_badge.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Booking summary card used in Booking History (client) and
/// Booking Requests / Active / Completed lists (provider).
///
/// Features soft shadow, press-scale animation, and dark-mode-aware colors.
class BookingCard extends StatefulWidget {
  final BookingModel booking;
  final bool isProviderView;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.isProviderView = false, this.onTap});

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.cardPressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
            boxShadow: _pressed
                ? AppSizes.shadowFor(context, level: ShadowLevel.sm)
                : AppSizes.shadowFor(context, level: ShadowLevel.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(widget.booking.serviceTitle, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                  ),
                  StatusBadge.fromStatus(widget.booking.status.name),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.isProviderView ? 'Client: ${widget.booking.clientName}' : 'Provider: ${widget.booking.providerName}',
                style: AppTextStyles.bodyMedium,
              ),
              Divider(height: AppSizes.lg, color: lineColor),
              Row(
                children: [
                  const AppIcon(AppIcons.calendar_today_rounded, size: 14, color: AppColors.neutral300),
                  const SizedBox(width: 6),
                  Text(Formatters.dateShort(widget.booking.bookingDate), style: AppTextStyles.bodySmall),
                  const SizedBox(width: 14),
                  const AppIcon(AppIcons.access_time_rounded, size: 14, color: AppColors.neutral300),
                  const SizedBox(width: 6),
                  Text(widget.booking.schedule, style: AppTextStyles.bodySmall),
                  const Spacer(),
                  Text(
                    Formatters.peso(widget.booking.amount),
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
