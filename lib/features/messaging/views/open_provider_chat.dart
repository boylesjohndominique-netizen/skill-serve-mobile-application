import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_thread.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';

/// Opens the customer's conversation with provider [providerId] — no booking
/// needed, so they can ask before booking. The first time starts it.
Future<void> openProviderChat(BuildContext context, String providerId) async {
  // Guests browse the marketplace too; messaging needs a customer account.
  if (!context.read<AuthController>().isClient) {
    AppSnackbar.error(context, 'Sign in with a customer account to message providers.');
    return;
  }

  final chat = context.read<ChatController>();
  final conversation = await chat.startInquiry(providerId);
  if (!context.mounted) return;
  if (conversation == null) {
    AppSnackbar.error(context, chat.errorMessage ?? 'Unable to start this conversation.');
    return;
  }
  context.push(ChatThread.route(conversation.threadKey));
}
