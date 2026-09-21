/// Public platform information from `GET /api/client/v1/platform` — what
/// administrators set in System Settings.
class PlatformInfo {
  final String name;
  final String supportEmail;
  final bool maintenanceMode;
  final bool providerRegistrationEnabled;
  final bool bookingEnabled;
  final int cancellationWindowHours;
  final String termsOfService;
  final String privacyPolicy;
  final String communityGuidelines;

  const PlatformInfo({
    this.name = 'SkillServe',
    this.supportEmail = '',
    this.maintenanceMode = false,
    this.providerRegistrationEnabled = true,
    this.bookingEnabled = true,
    this.cancellationWindowHours = 24,
    this.termsOfService = '',
    this.privacyPolicy = '',
    this.communityGuidelines = '',
  });

  /// The admin-written text for [key] (`terms_of_service`, `privacy_policy`,
  /// `community_guidelines`), empty until one is published.
  String policy(String key) => switch (key) {
        'terms_of_service' => termsOfService,
        'privacy_policy' => privacyPolicy,
        'community_guidelines' => communityGuidelines,
        _ => '',
      };

  factory PlatformInfo.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] is Map ? Map<String, dynamic>.from(json['booking'] as Map) : const <String, dynamic>{};
    final policies = json['policies'] is Map ? Map<String, dynamic>.from(json['policies'] as Map) : const <String, dynamic>{};
    return PlatformInfo(
      name: (json['platform_name'] as String?)?.trim().isNotEmpty == true ? json['platform_name'] as String : 'SkillServe',
      supportEmail: json['support_email'] as String? ?? '',
      maintenanceMode: json['maintenance_mode'] == true,
      providerRegistrationEnabled: json['provider_registration_enabled'] != false,
      bookingEnabled: booking['booking_enabled'] != false,
      cancellationWindowHours: (booking['cancellation_window_hours'] as num?)?.toInt() ?? 24,
      termsOfService: policies['terms_of_service'] as String? ?? '',
      privacyPolicy: policies['privacy_policy'] as String? ?? '',
      communityGuidelines: policies['community_guidelines'] as String? ?? '',
    );
  }
}
