import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  const ChatConversationScreen({super.key, required this.conversationId});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().openConversation(widget.conversationId);
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatController>().send(widget.conversationId, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(radius: 17, backgroundColor: AppColors.primary, child: AppIcon(AppIcons.person, color: Colors.white, size: 18)),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conversation', style: TextStyle(fontSize: 15)),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Active now', style: TextStyle(fontSize: 11, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: chat.isLoading
            ? const LoadingState()
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: false,
                      padding: const EdgeInsets.all(AppSizes.pageHPad),
                      itemCount: chat.activeMessages.length,
                      itemBuilder: (context, i) {
                        final m = chat.activeMessages[i];
                        final fromMe = m.senderId == 'me' || m.senderId.startsWith('CL-1001');
                        return Align(
                          alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSizes.sm),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              color: fromMe ? AppColors.secondary : inputBg,
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
                                Text(
                                  m.content,
                                  style: AppTextStyles.bodyLarge.copyWith(color: fromMe ? Colors.white : (isDark ? AppColors.textOnDark : AppColors.textPrimary)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.time(m.sentAt),
                                  style: AppTextStyles.caption.copyWith(color: fromMe ? Colors.white70 : AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i.clamp(0, 12) * 30), duration: 250.ms)
                            .slideX(begin: fromMe ? 0.08 : -0.08, end: 0);
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surface,
                        border: Border(top: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(hintText: 'Type a message…', border: InputBorder.none),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          InkWell(
                            onTap: _send,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: const AppIcon(AppIcons.send_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
