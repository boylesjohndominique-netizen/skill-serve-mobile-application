/// The signed-in provider's performance, from
/// `GET /api/client/v1/provider/statistics` — computed by the API from their
/// own bookings and reviews, so nothing here is estimated by the app.
class ProviderStatistics {
  final double averageRating;
  final int totalReviews;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int pendingRequests;
  final int activeBookings;

  /// Completed / (completed + cancelled), in percent; null before either.
  final double? completionRate;
  final double earningsTotal;
  final double earningsThisMonth;
  final int completedThisMonth;

  /// Bookings per status (`pending`, `confirmed`, `active`, `completed`,
  /// `cancelled`, `disputed`).
  final Map<String, int> statusBreakdown;

  /// One entry per calendar month in the business timezone, oldest first,
  /// ending with the current month.
  final List<MonthlyStat> monthly;

  /// Published reviews per star, 5 down to 1.
  final Map<int, int> ratingBreakdown;
  final List<TopService> topServices;
  final DateTime? generatedAt;

  const ProviderStatistics({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.pendingRequests = 0,
    this.activeBookings = 0,
    this.completionRate,
    this.earningsTotal = 0,
    this.earningsThisMonth = 0,
    this.completedThisMonth = 0,
    this.statusBreakdown = const {},
    this.monthly = const [],
    this.ratingBreakdown = const {},
    this.topServices = const [],
    this.generatedAt,
  });

  /// The month the provider is in — the last entry of [monthly].
  MonthlyStat? get currentMonth => monthly.isEmpty ? null : monthly.last;

  factory ProviderStatistics.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final status = (json['status_breakdown'] as Map?) ?? const {};
    final ratings = (json['rating_breakdown'] as Map?) ?? const {};

    return ProviderStatistics(
      averageRating: _double(summary['average_rating']),
      totalReviews: _int(summary['total_reviews']),
      totalBookings: _int(summary['total_bookings']),
      completedBookings: _int(summary['completed_bookings']),
      cancelledBookings: _int(summary['cancelled_bookings']),
      pendingRequests: _int(summary['pending_requests']),
      activeBookings: _int(summary['active_bookings']),
      completionRate: summary['completion_rate'] == null ? null : _double(summary['completion_rate']),
      earningsTotal: _double(summary['earnings_total']),
      earningsThisMonth: _double(summary['earnings_this_month']),
      completedThisMonth: _int(summary['completed_this_month']),
      statusBreakdown: {for (final e in status.entries) '${e.key}': _int(e.value)},
      monthly: [
        for (final item in (json['monthly'] as List? ?? const []))
          MonthlyStat.fromJson((item as Map).cast<String, dynamic>()),
      ],
      ratingBreakdown: {
        for (final e in ratings.entries)
          if (int.tryParse('${e.key}') != null) int.parse('${e.key}'): _int(e.value),
      },
      topServices: [
        for (final item in (json['top_services'] as List? ?? const []))
          TopService.fromJson((item as Map).cast<String, dynamic>()),
      ],
      generatedAt: DateTime.tryParse('${json['generated_at'] ?? ''}')?.toLocal(),
    );
  }
}

class MonthlyStat {
  /// `2026-10`.
  final String month;

  /// `Oct`.
  final String label;
  final int year;
  final int completed;
  final int received;
  final double earnings;

  const MonthlyStat({
    required this.month,
    required this.label,
    required this.year,
    this.completed = 0,
    this.received = 0,
    this.earnings = 0,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> json) => MonthlyStat(
        month: '${json['month'] ?? ''}',
        label: '${json['label'] ?? ''}',
        year: _int(json['year']),
        completed: _int(json['completed']),
        received: _int(json['received']),
        earnings: _double(json['earnings']),
      );
}

class TopService {
  final String id;
  final String title;
  final double averageRating;
  final int completed;

  const TopService({required this.id, required this.title, this.averageRating = 0, this.completed = 0});

  factory TopService.fromJson(Map<String, dynamic> json) => TopService(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        averageRating: _double(json['average_rating']),
        completed: _int(json['completed']),
      );
}

int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _double(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
