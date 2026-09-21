import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/support_ticket_model.dart';
import '../services/support_service.dart';

/// State for the support inbox, a new ticket, and an open ticket's thread.
class SupportController extends ChangeNotifier {
  final SupportService _service = SupportService();

  List<SupportTicketModel> tickets = [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  /// The ticket currently on screen, with its replies.
  SupportTicketModel? activeTicket;
  bool isTicketLoading = false;
  String? ticketErrorMessage;

  List<SupportTicketModel> get openTickets => tickets.where((t) => t.isOpen).toList();

  List<SupportTicketModel> get resolvedTickets =>
      tickets.where((t) => !t.isOpen).toList();

  Future<void> loadTickets() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tickets = await _service.getTickets();
    } catch (e) {
      tickets = [];
      errorMessage = apiErrorMessage(e, 'Unable to load your support tickets.');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> openTicket(String id) async {
    isTicketLoading = true;
    ticketErrorMessage = null;
    activeTicket = null;
    notifyListeners();
    try {
      activeTicket = await _service.getTicket(id);
    } catch (e) {
      ticketErrorMessage = apiErrorMessage(e, 'Unable to load this ticket.');
    }
    isTicketLoading = false;
    notifyListeners();
  }

  /// Returns the new ticket, or null with [errorMessage] set.
  Future<SupportTicketModel?> createTicket({
    required String subject,
    required String description,
    required TicketCategory category,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final ticket = await _service.createTicket(
        subject: subject,
        description: description,
        category: category,
      );
      tickets = [ticket, ...tickets];
      return ticket;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to create this ticket.');
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Adds a reply to the open ticket. The API returns the whole ticket, so the
  /// thread and the inbox row are both refreshed from one response.
  Future<bool> reply(String id, String body) async {
    if (body.trim().isEmpty) return false;
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _service.reply(id, body.trim());
      activeTicket = updated;
      final index = tickets.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        tickets = [...tickets]..[index] = updated;
      }
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to send this reply.');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
