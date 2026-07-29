/// Central registry of asset paths. Keep every reference here so a renamed
/// or moved asset only needs to be updated in one place.
class AppAssets {
  AppAssets._();

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';

  // Branding
  static const String logo = '$_images/logo.png';
  static const String logoMark = '$_images/logo_mark.png';

  // Onboarding illustrations (placeholders — drop matching SVG/PNG files in assets/images)
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';

  // Empty / error states
  static const String emptyBox = '$_images/empty_state.png';
  static const String errorIllustration = '$_images/error_state.png';

  // Lottie animations
  static const String lottieLoading = '$_animations/loading.json';
  static const String lottieSuccess = '$_animations/success.json';
  static const String lottieEmptyChat = '$_animations/empty_chat.json';

  // Icons (SVG)
  static const String icHome = '$_icons/ic_home.svg';
  static const String icSearch = '$_icons/ic_search.svg';
  static const String icBookings = '$_icons/ic_bookings.svg';
  static const String icChat = '$_icons/ic_chat.svg';
  static const String icProfile = '$_icons/ic_profile.svg';

  /// Fallback avatar used in cached_network_image errorWidget builders.
  static const String avatarPlaceholder = '$_images/avatar_placeholder.png';
}
