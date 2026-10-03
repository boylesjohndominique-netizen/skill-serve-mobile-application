import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../messaging/controllers/chat_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/realtime_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../models/message_model.dart';
import '../../reports/views/report_content_sheet.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// One booking's conversation. [bookingId] addresses the thread, because a
/// booking is the conversation.
class ChatConversationScreen extends StatefulWidget {
  final String bookingId;
  const ChatConversationScreen({super.key, required this.bookingId});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _renderedCount = 0;

  /// Captured in initState so dispose can still reach it: the controller
  /// outlives this screen, but its context does not.
  late final ChatController _chat;
  late final String _myId;

  /// Presence on this booking's chat: whether the other participant has the
  /// conversation open, and whether they are typing. Both are live hints
  /// over Reverb, never stored.
  final _realtime = RealtimeClient.instance;
  bool _otherInChat = false;
  bool _otherTyping = false;
  Timer? _typingExpiry;
  DateTime _lastTypingSent = DateTime(0);

  /// A "typing" hint lapses unless it is renewed; the sender renews it every
  /// few seconds while they keep typing.
  static const _typingTimeout = Duration(seconds: 5);
  static const _typingResend = Duration(seconds: 3);

  String get _presenceChannel => 'booking-chat.${widget.bookingId}';

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatController>();
    _myId = context.read<AuthController>().currentUser?.id ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chat.openConversation(widget.bookingId);
    });
    _realtime.joinPresence(
      _presenceChannel,
      onMembers: (ids) {
        if (!mounted) return;
        final present = ids.any((id) => id != _myId);
        setState(() {
          _otherInChat = present;
          if (!present) _otherTyping = false;
        });
      },
      onClientEvent: (event, data) {
        if (event != 'typing' || data['user_id']?.toString() == _myId || !mounted) return;
        _typingExpiry?.cancel();
        setState(() => _otherTyping = data['typing'] != false);
        if (_otherTyping) {
          _typingExpiry = Timer(_typingTimeout, () {
            if (mounted) setState(() => _otherTyping = false);
          });
        }
      },
    );
  }

  /// Tells the other participant we are typing, at most every few seconds.
  void _onComposerChanged(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < _typingResend) return;
    _lastTypingSent = now;
    _realtime.whisper(_presenceChannel, 'typing', {'user_id': _myId, 'typing': true});
  }

  void _stoppedTyping() {
    _lastTypingSent = DateTime(0);
    _realtime.whisper(_presenceChannel, 'typing', {'user_id': _myId, 'typing': false});
  }

  @override
  void dispose() {
    _typingExpiry?.cancel();
    _realtime.leavePresence(_presenceChannel);
    _controller.dispose();
    _scrollController.dispose();
    // The thread has left the screen, so an incoming message must not be
    // appended to it in the background.
    _chat.closeConversation();
    super.dispose();
  }

  /// Keeps the list pinned to the newest message as it grows.
  void _scrollToBottomIfNeeded(int count) {
    if (count == _renderedCount) return;
    _renderedCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final chat = context.read<ChatController>();
    final myId = context.read<AuthController>().currentUser?.id ?? '';

    _controller.clear();
    _stoppedTyping();
    await chat.send(widget.bookingId, text, myUserId: myId);
  }

  Future<void> _retry(MessageModel failed) async {
    final chat = context.read<ChatController>();
    final myId = context.read<AuthController>().currentUser?.id ?? '';
    await chat.retry(widget.bookingId, failed, myUserId: myId);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final myId = context.read<AuthController>().currentUser?.id ?? '';
    final conversation = chat.conversationFor(widget.bookingId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    _scrollToBottomIfNeeded(chat.activeMessages.length);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              name: conversation?.participantName,
              photoUrl: conversation?.participantAvatar,
              fallbackIcon: AppIcons.person,
              radius: 17,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation?.participantName.isNotEmpty == true
                        ? conversation!.participantName
                        : 'Conversation',
                    style: const TextStyle(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Live status first; the service otherwise.
                  if (_otherTyping || _otherInChat)
                    Text(
                      _otherTyping ? 'typing…' : 'In this chat',
                      style: TextStyle(
                        fontSize: 11,
                        color: _otherTyping ? context.accentInk : AppColors.success,
                        fontStyle: _otherTyping ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 1,
                    )
                  else if (conversation?.serviceTitle.isNotEmpty == true)
                    Text(
                      conversation!.serviceTitle,
                      style: TextStyle(fontSize: 11, color: context.textMutedColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View booking',
            onPressed: () => context.push('/booking-details/${widget.bookingId}'),
            icon: const AppIcon(AppIcons.calendar_today_rounded, size: 18),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildThread(chat, myId, isDark)),
            _buildComposer(chat, isDark, inputBg),
          ],
        ),
      ),
    );
  }

  Widget _buildThread(ChatController chat, String myId, bool isDark) {
    if (chat.isThreadLoading) return const LoadingState();

    if (chat.threadErrorMessage != null && chat.activeMessages.isEmpty) {
      return ErrorState(
        message: chat.threadErrorMessage!,
        onRetry: () => chat.openConversation(widget.bookingId),
      );
    }

    if (chat.activeMessages.isEmpty) {
      return const EmptyState(
        icon: AppIcons.chat_bubble_outline_rounded,
        title: 'No messages yet',
        message: 'Say hello — your message goes straight to the other party.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      itemCount: chat.activeMessages.length,
      itemBuilder: (context, i) {
        final message = chat.activeMessages[i];
        final fromMe = message.senderId == myId;
        return _Bubble(
          message: message,
          fromMe: fromMe,
          isDark: isDark,
          onRetry: message.hasFailed ? () => _retry(message) : null,
          // Only a message you received can be reported.
          onReport: fromMe || message.isPending
              ? null
              : () => showReportContentSheet(
                    context,
                    messageId: message.id,
                    title: 'Report this message',
                  ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: i.clamp(0, 12) * 30), duration: 250.ms)
            .slideX(begin: fromMe ? 0.08 : -0.08, end: 0);
      },
    );
  }

  Widget _buildComposer(ChatController chat, bool isDark, Color inputBg) {
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
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: TextField(
                  controller: _controller,
                  // The API caps a message at 5000 characters; stop at the
                  // limit rather than let the server reject the send.
                  maxLength: 5000,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: _onComposerChanged,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Semantics(
              button: true,
              label: 'Send message',
              child: InkWell(
                onTap: chat.isSending ? null : _send,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: chat.isSending ? AppColors.neutral300 : AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: chat.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const AppIcon(AppIcons.send_rounded, color: AppColors.primary, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool fromMe;
  final bool isDark;
  final VoidCallback? onRetry;

  /// Long-press action on a received message.
  final VoidCallback? onReport;

  const _Bubble({
    required this.message,
    required this.fromMe,
    required this.isDark,
    this.onRetry,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
    final bubbleColor = message.hasFailed
        ? AppColors.errorBg
        : (fromMe ? AppColors.secondary : inputBg);
    final textColor = message.hasFailed
        ? AppColors.error
        : (fromMe ? AppColors.primary : (isDark ? AppColors.textOnDark : AppColors.textPrimary));

    final bubble = Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSizes.radiusMd),
            topRight: const Radius.circular(AppSizes.radiusMd),
            bottomLeft: Radius.circular(fromMe ? AppSizes.radiusMd : 2),
            bottomRight: Radius.circular(fromMe ? 2 : AppSizes.radiusMd),
          ),
          boxShadow: [
            BoxShadow(
              color: (fromMe ? AppColors.secondary : Colors.black).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content, style: AppTextStyles.bodyLarge.copyWith(color: textColor)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.isPending
                      ? 'Sending…'
                      : message.hasFailed
                          ? 'Not sent'
                          : Formatters.time(message.sentAt),
                  style: AppTextStyles.caption.copyWith(
                    color: message.hasFailed
                        ? AppColors.error
                        : (fromMe
                            ? AppColors.primary.withValues(alpha: 0.65)
                            : context.textMutedColor),
                  ),
                ),
                // A read receipt only makes sense on a message you sent.
                if (fromMe && !message.isPending && !message.hasFailed) ...[
                  const SizedBox(width: 4),
                  AppIcon(
                    message.isRead ? AppIcons.check_circle_rounded : AppIcons.check_rounded,
                    size: 12,
                    color: AppColors.primary.withValues(alpha: 0.65),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(width: AppSizes.sm),
                  // A real button, so it is reachable by keyboard and screen
                  // readers and shows a focus state.
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Retry',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: onReport == null
          ? bubble
          : Semantics(
              onLongPressHint: 'Report this message',
              child: GestureDetector(onLongPress: onReport, child: bubble),
            ),
    );
  }
}
