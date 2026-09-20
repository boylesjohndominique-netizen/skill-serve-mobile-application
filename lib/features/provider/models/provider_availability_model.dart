/// One weekday window of a provider's published hours.
///
/// Mirrors `ProviderAvailabilityWindow` in api-docs/openapi.json. Times are
/// wall clock (`HH:mm`) in the platform's timezone — the same basis booking
/// times use — so nothing is converted here.
class ProviderAvailabilityModel {
  /// 0 = Sunday … 6 = Saturday, matching the API and `DateTime.weekday % 7`.
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  const ProviderAvailabilityModel({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  static const dayNames = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get dayName => dayNames[dayOfWeek.clamp(0, 6)];

  String get shortDayName => dayName.substring(0, 3);

  /// "9:00 AM – 5:00 PM" for display.
  String get label => '${_display(startTime)} – ${_display(endTime)}';

  factory ProviderAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return ProviderAvailabilityModel(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
      startTime: _hhmm(json['start_time'] as String? ?? '09:00'),
      endTime: _hhmm(json['end_time'] as String? ?? '17:00'),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
      };

  ProviderAvailabilityModel copyWith({String? startTime, String? endTime}) {
    return ProviderAvailabilityModel(
      dayOfWeek: dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// The API sends `HH:mm`, but a database round trip can surface
  /// `HH:mm:ss`; the app always stores and sends `HH:mm`.
  static String _hhmm(String time) => time.length >= 5 ? time.substring(0, 5) : time;

  static String _display(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final suffix = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

/// The signed-in provider's whole schedule: the windows plus the flag that
/// decides whether new bookings are accepted at all.
///
/// Mirrors the `data` object of `GET/PUT /api/client/v1/provider/availability`.
class ProviderAvailability {
  final bool isAcceptingBookings;
  final List<ProviderAvailabilityModel> windows;

  const ProviderAvailability({
    this.isAcceptingBookings = true,
    this.windows = const [],
  });

  factory ProviderAvailability.fromJson(Map<String, dynamic> json) {
    return ProviderAvailability(
      isAcceptingBookings: json['is_accepting_bookings'] != false,
      windows: [
        for (final item in (json['availability'] as List? ?? const []))
          ProviderAvailabilityModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// The window published for [dayOfWeek], or null when that day is off.
  ProviderAvailabilityModel? windowFor(int dayOfWeek) {
    for (final window in windows) {
      if (window.dayOfWeek == dayOfWeek) return window;
    }
    return null;
  }
}
