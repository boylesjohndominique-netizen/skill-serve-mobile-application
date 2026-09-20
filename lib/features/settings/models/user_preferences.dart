import 'package:flutter/material.dart';

/// The account's settings, as stored by `GET/PUT /api/client/v1/preferences`.
///
/// Immutable so a failed save can be rolled back to the previous value by
/// simply restoring the old instance.
@immutable
class UserPreferences {
  final bool bookingNotifications;
  final bool serviceNotifications;
  final bool messageNotifications;
  final bool announcementNotifications;
  final bool privateProfile;
  final bool activityPersonalization;
  final bool reduceMotion;
  final ThemeMode theme;

  const UserPreferences({
    this.bookingNotifications = true,
    this.serviceNotifications = true,
    this.messageNotifications = true,
    this.announcementNotifications = true,
    this.privateProfile = false,
    this.activityPersonalization = true,
    this.reduceMotion = false,
    this.theme = ThemeMode.system,
  });

  /// The platform defaults, matching the server's own.
  static const defaults = UserPreferences();

  UserPreferences copyWith({
    bool? bookingNotifications,
    bool? serviceNotifications,
    bool? messageNotifications,
    bool? announcementNotifications,
    bool? privateProfile,
    bool? activityPersonalization,
    bool? reduceMotion,
    ThemeMode? theme,
  }) =>
      UserPreferences(
        bookingNotifications: bookingNotifications ?? this.bookingNotifications,
        serviceNotifications: serviceNotifications ?? this.serviceNotifications,
        messageNotifications: messageNotifications ?? this.messageNotifications,
        announcementNotifications:
            announcementNotifications ?? this.announcementNotifications,
        privateProfile: privateProfile ?? this.privateProfile,
        activityPersonalization:
            activityPersonalization ?? this.activityPersonalization,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        theme: theme ?? this.theme,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        bookingNotifications: _bool(json['booking_notifications'], true),
        serviceNotifications: _bool(json['service_notifications'], true),
        messageNotifications: _bool(json['message_notifications'], true),
        announcementNotifications:
            _bool(json['announcement_notifications'], true),
        privateProfile: _bool(json['private_profile'], false),
        activityPersonalization: _bool(json['activity_personalization'], true),
        reduceMotion: _bool(json['reduce_motion'], false),
        theme: themeFromName(json['theme'] as String?),
      );

  /// The wire format the API accepts on `PUT /preferences`.
  Map<String, dynamic> toJson() => {
        'booking_notifications': bookingNotifications,
        'service_notifications': serviceNotifications,
        'message_notifications': messageNotifications,
        'announcement_notifications': announcementNotifications,
        'private_profile': privateProfile,
        'activity_personalization': activityPersonalization,
        'reduce_motion': reduceMotion,
        'theme': themeName,
      };

  String get themeName => switch (theme) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode themeFromName(String? name) => switch (name) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// The API sends real booleans, but a cached value can be absent.
  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : (value == 1 ? true : (value == 0 ? false : fallback));

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.bookingNotifications == bookingNotifications &&
      other.serviceNotifications == serviceNotifications &&
      other.messageNotifications == messageNotifications &&
      other.announcementNotifications == announcementNotifications &&
      other.privateProfile == privateProfile &&
      other.activityPersonalization == activityPersonalization &&
      other.reduceMotion == reduceMotion &&
      other.theme == theme;

  @override
  int get hashCode => Object.hash(
        bookingNotifications,
        serviceNotifications,
        messageNotifications,
        announcementNotifications,
        privateProfile,
        activityPersonalization,
        reduceMotion,
        theme,
      );
}
