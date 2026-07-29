import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/inputs/app_search_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages', style: AppTextStyles.displayMedium),
              const SizedBox(height: AppSizes.md),
              const AppSearchBar(hint: 'Search conversations…'),
              const SizedBox(height: AppSizes.lg),
              Expanded(
                child: chat.isLoading
                    ? const ShimmerCardList(itemHeight: 64)
                    : chat.conversations.isEmpty
                        ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No messages yet', message: 'Your conversations with providers will appear here.')
                        : ListView.separated(
                            itemCount: chat.conversations.length,
                            separatorBuilder: (_, __) => const Divider(height: AppSizes.lg),
                            itemBuilder: (context, i) {
                              final c = chat.conversations[i];
                              return InkWell(
                                onTap: () => context.push('/chat-conversation/${c.id}'),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppColors.primary,
                                          child: Text(c.participantName[0], style: const TextStyle(color: Colors.white)),
                                        ),
                                        if (c.isOnline)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: AppColors.success,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: AppSizes.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.participantName, style: AppTextStyles.titleMedium),
                                          const SizedBox(height: 2),
                                          Text(c.lastMessage, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(Formatters.relative(c.lastMessageAt), style: AppTextStyles.bodySmall),
                                        if (c.unreadCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(999)),
                                            child: Text('${c.unreadCount}', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
