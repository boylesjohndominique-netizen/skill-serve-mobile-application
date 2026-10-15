import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/utils/photo_picker.dart';
import '../../../core/widgets/feedback/app_bottom_sheet.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/widgets/misc/private_image.dart';
import '../models/chat_thread.dart';
import '../models/message_model.dart';
import '../../reports/views/report_content_sheet.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/feedback/app_notice.dart';
import '../../../core/theme/app_palette.dart';

/// One conversation: a booking's chat, or a conversation with a provider
/// before booking. [threadKey] addresses it ([ChatThread]).
class ChatConversationScreen extends StatefulWidget {
  final String threadKey;
  const ChatConversationScreen({super.key, required this.threadKey});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _renderedCount = 0;

  /// A photo picked for the next message, shown above the composer until it
  /// is sent or removed.
  String? _attachment;

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

  String get _presenceChannel => ChatThread.presenceChannel(widget.threadKey);

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatController>();
    _myId = context.read<AuthController>().currentUser?.id ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chat.openConversation(widget.threadKey);
      // Opened from a notification, a booking or a profile before the
      // Messages tab: the header needs this thread's participant (name,
      // photo, profile link) from the inbox.
      if (_chat.conversationFor(widget.threadKey) == null && !_chat.isLoading) {
        _chat.loadConversations();
      }
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
    final photo = _attachment;
    if (text.isEmpty && photo == null) return;
    final chat = context.read<ChatController>();
    final myId = context.read<AuthController>().currentUser?.id ?? '';

    _controller.clear();
    setState(() => _attachment = null);
    _stoppedTyping();
    await chat.send(widget.threadKey, text, myUserId: myId, imagePath: photo);
  }

  /// Picks a photo for the next message — taken now, or from the gallery.
  Future<void> _pickPhoto() async {
    final picked = await pickPhotos(context);
    if (picked.isNotEmpty && mounted) setState(() => _attachment = picked.first);
  }

  Future<void> _retry(MessageModel failed) async {
    final chat = context.read<ChatController>();
    final myId = context.read<AuthController>().currentUser?.id ?? '';
    await chat.retry(widget.threadKey, failed, myUserId: myId);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final myId = context.read<AuthController>().currentUser?.id ?? '';
    final conversation = chat.conversationFor(widget.threadKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    _scrollToBottomIfNeeded(chat.activeMessages.length);

    // A customer opens the provider's full profile from the header; the
    // provider's side has no public profile to open for a customer.
    final providerProfileId =
        context.select<AuthController, bool>((auth) => auth.isClient) ? conversation?.providerProfileId : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _ProfileLink(
          providerProfileId: providerProfileId,
          name: conversation?.participantName ?? '',
          child: Row(
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
                      conversation?.participantName.isNotEmpty == true ? conversation!.participantName : 'Conversation',
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
                    else if (conversation?.topic.isNotEmpty == true)
                      Text(
                        conversation!.topic,
                        style: TextStyle(fontSize: 11, color: context.textMutedColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (providerProfileId != null && providerProfileId.isNotEmpty)
            IconButton(
              tooltip: 'View provider profile',
              onPressed: () => context.push('/provider-profile/$providerProfileId'),
              icon: const AppIcon(AppIcons.person_outline_rounded, size: 20),
            ),
          // A conversation before booking has no booking to open yet.
          if (!ChatThread.isInquiry(widget.threadKey))
            IconButton(
              tooltip: 'View booking',
              onPressed: () => context.push('/booking-details/${widget.threadKey}'),
              icon: const AppIcon(AppIcons.calendar_today_rounded, size: 18),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // The provider was suspended, banned or deleted: messages may
            // never be read, so say so above the thread.
            if (conversation != null && conversation.isProviderUnavailable)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.sm, AppSizes.pageHPad, 0),
                child: AppNotice(
                  tone: NoticeTone.error,
                  icon: AppIcons.block_rounded,
                  message: conversation.providerAccountNotice ?? 'This provider can no longer use SkillServe.',
                ),
              ),
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
        onRetry: () => chat.openConversation(widget.threadKey),
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
          onOpenPhoto: message.imageUrl != null || message.localImagePath != null ? () => _openPhoto(message) : null,
          onLongPress: _messageActionsFor(message, fromMe: fromMe),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: i.clamp(0, 12) * 30), duration: 250.ms)
            .slideX(begin: fromMe ? 0.08 : -0.08, end: 0);
      },
    );
  }

  /// The long-press menu on a message: copy its text, and report it when it
  /// is one you received. Null when neither applies (a photo you sent).
  VoidCallback? _messageActionsFor(MessageModel message, {required bool fromMe}) {
    final canCopy = message.content.isNotEmpty;
    // Only a message you received, and the API has stored, can be reported.
    final canReport = !fromMe && !message.isPending;
    if (!canCopy && !canReport) return null;

    return () async {
      final action = await AppBottomSheet.show<_MessageAction>(
        context,
        child: _MessageActionsSheet(canCopy: canCopy, canReport: canReport),
      );
      if (action == null || !mounted) return;
      switch (action) {
        case _MessageAction.copy:
          await Clipboard.setData(ClipboardData(text: message.content));
          if (mounted) AppSnackbar.success(context, 'Message copied.');
        case _MessageAction.report:
          showReportContentSheet(context, messageId: message.id, title: 'Report this message');
      }
    };
  }

  void _openPhoto(MessageModel message) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenPhoto(message: message),
    ));
  }

  Widget _buildComposer(ChatController chat, bool isDark, Color inputBg) {
    final attachment = _attachment;
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
          children: [
            if (attachment != null)
              _AttachmentPreview(path: attachment, onRemove: () => setState(() => _attachment = null)),
            Row(
              children: [
                IconButton(
                  tooltip: 'Send a photo',
                  onPressed: chat.isSending ? null : _pickPhoto,
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
                      controller: _controller,
                      // The API caps a message at 5000 characters; stop at the
                      // limit rather than let the server reject the send.
                      maxLength: 5000,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: attachment != null ? 'Add a caption…' : 'Type a message…',
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
          ],
        ),
      ),
    );
  }
}

/// The photo waiting to go with the next message, with a button to drop it.
class _AttachmentPreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _AttachmentPreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Image.file(File(path), width: 96, height: 96, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: 'Remove photo',
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                    child: const AppIcon(AppIcons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A message's photo — on this phone while sending, else from the API.
class _MessagePhoto extends StatelessWidget {
  final MessageModel message;
  final BoxFit fit;
  final double? width;
  final double? height;
  const _MessagePhoto({required this.message, this.fit = BoxFit.cover, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final local = message.localImagePath;
    if (message.imageUrl == null && local != null) {
      return Image.file(File(local), fit: fit, width: width, height: height);
    }
    return PrivateImage(url: message.imageUrl!, fit: fit, width: width, height: height);
  }
}

/// A chat photo on its own, full screen, with pinch to zoom.
class _FullScreenPhoto extends StatelessWidget {
  final MessageModel message;
  const _FullScreenPhoto({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          message.senderName.isEmpty ? 'Photo' : message.senderName,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      body: InteractiveViewer(
        maxScale: 4,
        child: Center(child: _MessagePhoto(message: message, fit: BoxFit.contain)),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool fromMe;
  final bool isDark;
  final VoidCallback? onRetry;

  /// Opens the message's photo full screen; null when it has none.
  final VoidCallback? onOpenPhoto;

  /// Opens the message's long-press menu (copy, report); null when it has
  /// nothing to offer.
  final VoidCallback? onLongPress;

  const _Bubble({
    required this.message,
    required this.fromMe,
    required this.isDark,
    this.onRetry,
    this.onOpenPhoto,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
    final bubbleColor = message.hasFailed ? context.errorBgColor : (fromMe ? AppColors.secondary : inputBg);
    final textColor = message.hasFailed
        ? context.errorColor
        : (fromMe ? AppColors.primary : (isDark ? AppColors.textOnDark : AppColors.textPrimary));

    final bubble = Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: message.hasImage
          ? const EdgeInsets.fromLTRB(4, 4, 4, 8)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          if (message.hasImage)
            Semantics(
              button: true,
              label: 'Photo. Open full screen',
              child: GestureDetector(
                onTap: onOpenPhoto,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd - 2),
                  child: _MessagePhoto(
                    message: message,
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 220,
                  ),
                ),
              ),
            ),
          if (message.content.isNotEmpty)
            Padding(
              padding: message.hasImage ? const EdgeInsets.fromLTRB(10, 8, 10, 0) : EdgeInsets.zero,
              child: Text(message.content, style: AppTextStyles.bodyLarge.copyWith(color: textColor)),
            ),
          const SizedBox(height: 4),
          Padding(
            padding: message.hasImage ? const EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.zero,
            child: Row(
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
                        : (fromMe ? AppColors.primary.withValues(alpha: 0.65) : context.textMutedColor),
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
          ),
        ],
      ),
    );

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: onLongPress == null
          ? bubble
          : Semantics(
              onLongPressHint: 'Message options',
              child: GestureDetector(onLongPress: onLongPress, child: bubble),
            ),
    );
  }
}

enum _MessageAction { copy, report }

/// What a long-press on a message offers. Pasting needs no menu of its own:
/// the message box takes a paste from its own long-press menu.
class _MessageActionsSheet extends StatelessWidget {
  final bool canCopy;
  final bool canReport;
  const _MessageActionsSheet({required this.canCopy, required this.canReport});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canCopy)
          ListTile(
            leading: AppIcon(AppIcons.content_copy_rounded, color: context.accentInk),
            title: Text('Copy text', style: AppTextStyles.bodyLarge),
            onTap: () => Navigator.of(context).pop(_MessageAction.copy),
          ),
        if (canReport)
          ListTile(
            leading: const AppIcon(AppIcons.flag_outlined, color: AppColors.error),
            title: Text('Report message', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
            onTap: () => Navigator.of(context).pop(_MessageAction.report),
          ),
      ],
    );
  }
}

/// Opens the provider's public profile when [providerProfileId] is set;
/// otherwise just shows [child].
class _ProfileLink extends StatelessWidget {
  final String? providerProfileId;
  final String name;
  final Widget child;

  const _ProfileLink({required this.providerProfileId, required this.name, required this.child});

  @override
  Widget build(BuildContext context) {
    final id = providerProfileId;
    if (id == null || id.isEmpty) return child;

    return Semantics(
      button: true,
      label: name.isEmpty ? 'View provider profile' : 'View $name\'s profile',
      child: InkWell(
        onTap: () => context.push('/provider-profile/$id'),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      ),
    );
  }
}
