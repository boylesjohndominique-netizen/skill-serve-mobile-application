import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../controllers/support_controller.dart';
import '../models/support_ticket_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/inputs/photo_attachments_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/private_photo_strip.dart';
import '../../../core/utils/photo_picker.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/feedback/app_notice.dart';
import '../../../core/theme/app_palette.dart';

/// One support ticket and its conversation with staff.
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _replyController = TextEditingController();

  /// Photos picked for the next reply.
  List<String> _photos = const [];
  static const _maxPhotos = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportController>().openTicket(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    final photos = _photos;
    if (text.isEmpty && photos.isEmpty) return;

    final support = context.read<SupportController>();
    _replyController.clear();
    setState(() => _photos = const []);
    final ok = await support.reply(widget.ticketId, text, photoPaths: photos);
    if (!mounted) return;

    if (!ok) {
      // Give the text and photos back so nothing the user added is lost.
      _replyController.text = text;
      setState(() => _photos = photos);
      AppSnackbar.error(context, support.errorMessage ?? 'Unable to send this reply.');
    }
  }

  Future<void> _addPhotos() async {
    final picked = await pickPhotos(context, max: _maxPhotos - _photos.length);
    if (picked.isNotEmpty && mounted) {
      setState(() => _photos = [..._photos, ...picked].take(_maxPhotos).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();
    final ticket = support.activeTicket;
    final myId = context.read<AuthController>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(ticket?.ticketNumber.isNotEmpty == true
          ? ticket!.ticketNumber
          : 'Customer Support')),
      body: SafeArea(
        child: support.isTicketLoading
            ? const LoadingState()
            : ticket == null
                ? ErrorState(
                    message: support.ticketErrorMessage ?? 'This conversation could not be loaded.',
                    onRetry: () => support.openTicket(widget.ticketId),
                  )
                : Column(
                    children: [
                      Expanded(child: _buildThread(ticket, myId)),
                      if (ticket.isOpen)
                        _buildComposer(support)
                      else
                        _buildClosedNotice(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildThread(SupportTicketModel ticket, String myId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      children: [
        Row(
          children: [
            Expanded(child: Text(ticket.subject, style: AppTextStyles.titleLarge)),
            const SizedBox(width: AppSizes.sm),
            StatusBadge.fromStatus(ticket.status.name),
          ],
        ),
        const SizedBox(height: 2),
        Text('${ticket.categoryLabel} · opened ${Formatters.relative(ticket.createdAt)}',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSizes.lg),

        // The original request reads as the first message in the thread.
        _Bubble(
          body: ticket.description,
          photoUrls: ticket.photoUrls,
          author: 'You',
          at: ticket.createdAt,
          fromMe: true,
          isDark: isDark,
        ),
        for (final reply in ticket.replies)
          _Bubble(
            body: reply.body,
            photoUrls: reply.photoUrls,
            author: reply.authorId == myId
                ? 'You'
                : (reply.authorName.isEmpty ? 'Customer Support' : reply.authorName),
            at: reply.createdAt,
            fromMe: reply.authorId == myId,
            isDark: isDark,
          ),

        if (ticket.resolutionNote != null && ticket.resolutionNote!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          AppNotice(
            tone: NoticeTone.success,
            icon: AppIcons.task_alt_rounded,
            title: 'Resolution',
            message: ticket.resolutionNote!,
          ).animate().fadeIn(duration: 300.ms),
        ],
      ],
    );
  }

  Widget _buildComposer(SupportController support) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_photos.isNotEmpty) ...[
              PhotoAttachmentsField(
                paths: _photos,
                max: _maxPhotos,
                enabled: !support.isSubmitting,
                helper: '${_photos.length} of $_maxPhotos photos · sent with your reply',
                onChanged: (photos) => setState(() => _photos = photos),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            Row(
          children: [
            if (_photos.isEmpty)
              IconButton(
                tooltip: 'Add photos',
                onPressed: support.isSubmitting ? null : _addPhotos,
                icon: AppIcon(AppIcons.add_photo_alternate_outlined, color: context.accentInk),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: TextField(
                  controller: _replyController,
                  // The API caps a reply at 5000 characters.
                  maxLength: 5000,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Write a reply…',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Semantics(
              button: true,
              label: 'Send reply',
              child: InkWell(
                onTap: support.isSubmitting ? null : _sendReply,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: support.isSubmitting ? AppColors.neutral300 : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: support.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : const AppIcon(AppIcons.send_rounded,
                          color: AppColors.primary, size: 18),
                ),
              ),
            ),
          ],
            ),
          ],
        ),
      ),
    );
  }

  /// A resolved ticket takes no more replies — the API refuses them, so the
  /// composer is replaced by an explanation rather than a field that fails.
  Widget _buildClosedNotice() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const AppIcon(AppIcons.check_circle_rounded, size: 18, color: AppColors.success),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                'This conversation is resolved. Contact Customer Support again if you need more help.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String body;
  final List<String> photoUrls;
  final String author;
  final DateTime at;
  final bool fromMe;
  final bool isDark;

  const _Bubble({
    required this.body,
    this.photoUrls = const [],
    required this.author,
    required this.at,
    required this.fromMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        fromMe ? AppColors.secondary : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt);
    final textColor =
        fromMe ? AppColors.primary : (isDark ? AppColors.textOnDark : AppColors.textPrimary);

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSizes.radiusMd),
            topRight: const Radius.circular(AppSizes.radiusMd),
            bottomLeft: Radius.circular(fromMe ? AppSizes.radiusMd : 2),
            bottomRight: Radius.circular(fromMe ? 2 : AppSizes.radiusMd),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(author,
                style: AppTextStyles.caption.copyWith(
                  color: textColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 2),
            if (body.isNotEmpty) Text(body, style: AppTextStyles.bodyLarge.copyWith(color: textColor)),
            if (photoUrls.isNotEmpty) ...[
              const SizedBox(height: 6),
              PrivatePhotoStrip(urls: photoUrls),
            ],
            const SizedBox(height: 4),
            Text(Formatters.relative(at),
                style: AppTextStyles.caption.copyWith(color: textColor.withValues(alpha: 0.65))),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: fromMe ? 0.06 : -0.06, end: 0);
  }
}
