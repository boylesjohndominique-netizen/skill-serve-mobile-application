import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// Why the server refused an account, from `meta.account` on a 403
/// (login, token refresh, or any request once an account is restricted).
class AccountRestriction {
  /// `suspended` or `banned`.
  final String status;
  final String? reason;
  final DateTime? since;

  /// When a temporary ban ends; null for a suspension or a permanent ban.
  final DateTime? until;

  const AccountRestriction({required this.status, this.reason, this.since, this.until});

  bool get isBanned => status == 'banned';
  bool get isPermanent => isBanned && until == null;

  String get title => switch (status) {
        'suspended' => 'Your account is suspended',
        'banned' => isPermanent ? 'Your account is banned' : 'Your account is temporarily banned',
        _ => 'Your account is restricted',
      };

  String get explanation => switch (status) {
        'suspended' => 'An administrator suspended your account. You cannot sign in until it is reactivated.',
        'banned' when until != null =>
          'You can sign in again after ${DateFormat('MMM d, yyyy h:mm a').format(until!)}.',
        'banned' => 'This ban is permanent.',
        _ => 'You cannot sign in right now.',
      };

  factory AccountRestriction.fromJson(Map<String, dynamic> json) => AccountRestriction(
        status: json['status'] as String? ?? 'restricted',
        reason: json['reason'] as String?,
        since: _date(json['since']),
        until: _date(json['until']),
      );

  /// The restriction carried by an API error, or null when it is some other failure.
  static AccountRestriction? fromError(Object error) {
    if (error is! DioException || error.response?.statusCode != 403) return null;
    final data = error.response?.data;
    final account = data is Map ? (data['meta'] is Map ? data['meta']['account'] : null) : null;
    if (account is! Map) return null;
    final restriction = AccountRestriction.fromJson(Map<String, dynamic>.from(account));
    return restriction.status == 'suspended' || restriction.status == 'banned' ? restriction : null;
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
