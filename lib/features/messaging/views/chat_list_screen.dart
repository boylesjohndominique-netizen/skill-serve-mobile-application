import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../messaging/controllers/chat_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/inputs/app_search_bar.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../models/chat_thread.dart';
import '../models/message_model.dart';
import '../../../core/constants/app_icons.dart';

/// The Messages inbox: one row per booking conversation.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().loadConversations();
    });
  }

  Future<void> _reload() => context.read<ChatController>().loadConversations();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matches = chat.search(_query);
    final failed = chat.errorMessage != null && chat.conversations.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: AppSizes.md),
              AppSearchBar(
                hint: 'Search conversations…',
                onChanged: (value) => setState(() => _query = value),
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.lg),
              Expanded(
                child: chat.isLoading
                    ? const ShimmerCardList(itemHeight: 64)
                    : failed
                        ? ErrorState(message: chat.errorMessage!, onRetry: _reload)
                        : RefreshIndicator(
                            onRefresh: _reload,
                            child: matches.isEmpty
                                ? ListView(
                                    padding: const EdgeInsets.only(top: AppSizes.xl),
                                    children: [
                                      _query.isEmpty
                                          ? const EmptyState(
                                              icon: AppIcons.chat_bubble_outline_rounded,
                                              title: 'No messages yet',
                                              message:
                                                  'Once you book a service, you can message the provider here.',
                                            )
                                          : EmptyState(
                                              icon: AppIcons.search_rounded,
                                              title: 'No matches',
                                              message: 'No conversation matches "$_query".',
                                            ),
                                    ],
                                  )
                                : ListView.separated(
                                    itemCount: matches.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: AppSizes.lg,
                                      color: isDark ? AppColors.lineDark : AppColors.line,
                                    ),
                                    itemBuilder: (context, i) => _ConversationRow(
                                      conversation: matches[i],
                                      isDark: isDark,
                                    )
                                        .animate()
                                        .fadeIn(
                                            delay: Duration(milliseconds: 150 + i.clamp(0, 8) * 60),
                                            duration: 350.ms)
                                        .slideX(begin: 0.06, end: 0),
                                  ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final ConversationModel conversation;
  final bool isDark;

  const _ConversationRow({required this.conversation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () => context.push(ChatThread.route(conversation.threadKey)),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _Avatar(conversation: conversation),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.participantName.isEmpty
                              ? 'Conversation'
                              : conversation.participantName,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.bookingStatus.isNotEmpty) ...[
                        const SizedBox(width: AppSizes.sm),
                        StatusBadge.fromStatus(conversation.bookingStatus),
                      ],
                    ],
                  ),
                  if (conversation.topic.isNotEmpty)
                    Text(
                      conversation.topic,
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.preview,
                    style: unread
                        ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)
                        : AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (conversation.lastMessageAt != null)
                  Text(Formatters.relative(conversation.lastMessageAt!),
                      style: AppTextStyles.bodySmall),
                if (unread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${conversation.unreadCount}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ).animate().scale(
                      begin: const Offset(0.5, 0.5), duration: 300.ms, curve: Curves.easeOutBack),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The other party's photo. For a customer it opens the provider's full
/// profile; the rest of the row still opens the conversation.
class _Avatar extends StatelessWidget {
  final ConversationModel conversation;
  const _Avatar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatar(
      name: conversation.participantName,
      photoUrl: conversation.participantAvatar,
      radius: 24,
    );
    final id = conversation.providerProfileId;
    final isClient = context.select<AuthController, bool>((auth) => auth.isClient);
    if (!isClient || id == null || id.isEmpty) return avatar;

    return Semantics(
      button: true,
      label: 'View ${conversation.participantName}\'s profile',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/provider-profile/$id'),
        child: avatar,
      ),
    );
  }
}
