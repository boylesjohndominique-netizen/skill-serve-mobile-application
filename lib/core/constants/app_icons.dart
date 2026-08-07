// Names intentionally mirror the Material icons they replace (e.g.
// `star_rounded`), so the lint for snake_case identifiers is disabled here.
// ignore_for_file: constant_identifier_names

import 'package:hugeicons/hugeicons.dart';

/// Icon data type used by HugeIcons (SVG path data).
typedef AppIconData = List<List<dynamic>>;

/// Central registry of app icons (HugeIcons stroke-rounded style).
///
/// Names mirror the Material icons they replace (`Icons.star_rounded` →
/// `AppIcons.star_rounded`) so every screen can migrate with a simple
/// find-and-replace. Swap the underlying glyph here to restyle the whole app.
abstract final class AppIcons {
  AppIcons._();

  // ── Time / calendar ────────────────────────────────────────────────
  static const AppIconData access_time_rounded = HugeIcons.strokeRoundedClock01;
  static const AppIconData calendar_month_outlined = HugeIcons.strokeRoundedCalendar01;
  static const AppIconData calendar_month_rounded = HugeIcons.strokeRoundedCalendar01;
  static const AppIconData calendar_today_outlined = HugeIcons.strokeRoundedCalendar01;
  static const AppIconData calendar_today_rounded = HugeIcons.strokeRoundedCalendar01;
  static const AppIconData schedule_outlined = HugeIcons.strokeRoundedClock03;
  static const AppIconData schedule_rounded = HugeIcons.strokeRoundedClock03;
  static const AppIconData timer_outlined = HugeIcons.strokeRoundedTimer01;
  static const AppIconData hourglass_top_rounded = HugeIcons.strokeRoundedHourglass;
  static const AppIconData history_rounded = HugeIcons.strokeRoundedClock02;
  static const AppIconData pending_actions_rounded = HugeIcons.strokeRoundedClock03;
  static const AppIconData event_available_outlined = HugeIcons.strokeRoundedCalendarCheckIn01;
  static const AppIconData event_available_rounded = HugeIcons.strokeRoundedCalendarCheckIn01;
  static const AppIconData event_busy_rounded = HugeIcons.strokeRoundedCalendarBlock01;
  static const AppIconData event_note_outlined = HugeIcons.strokeRoundedCalendar01;

  // ── Navigation / shell ─────────────────────────────────────────────
  static const AppIconData home_outlined = HugeIcons.strokeRoundedHome01;
  static const AppIconData home_rounded = HugeIcons.strokeRoundedHome01;
  static const AppIconData explore_outlined = HugeIcons.strokeRoundedCompass01;
  static const AppIconData explore_rounded = HugeIcons.strokeRoundedCompass01;
  static const AppIconData grid_view_outlined = HugeIcons.strokeRoundedGrid02;
  static const AppIconData grid_view_rounded = HugeIcons.strokeRoundedGrid02;
  static const AppIconData apps_rounded = HugeIcons.strokeRoundedGrid02;
  static const AppIconData person = HugeIcons.strokeRoundedUser;
  static const AppIconData person_rounded = HugeIcons.strokeRoundedUser;
  static const AppIconData person_outline_rounded = HugeIcons.strokeRoundedUserCircle;
  static const AppIconData person_search_rounded = HugeIcons.strokeRoundedUserSearch01;
  static const AppIconData notifications_outlined = HugeIcons.strokeRoundedNotification01;
  static const AppIconData notifications_rounded = HugeIcons.strokeRoundedNotification01;
  static const AppIconData notifications_none_rounded = HugeIcons.strokeRoundedNotification01;

  // ── Communication ──────────────────────────────────────────────────
  static const AppIconData chat_bubble_outline_rounded = HugeIcons.strokeRoundedMessage01;
  static const AppIconData chat_bubble_rounded = HugeIcons.strokeRoundedMessage02;
  static const AppIconData inbox_outlined = HugeIcons.strokeRoundedInbox;
  static const AppIconData mail_outline_rounded = HugeIcons.strokeRoundedMail01;
  static const AppIconData send_rounded = HugeIcons.strokeRoundedTelegram;
  static const AppIconData support_agent_rounded = HugeIcons.strokeRoundedHeadset;
  static const AppIconData call_outlined = HugeIcons.strokeRoundedCall;
  static const AppIconData phone_outlined = HugeIcons.strokeRoundedCall02;

  // ── Money / payments ───────────────────────────────────────────────
  static const AppIconData account_balance_wallet_outlined = HugeIcons.strokeRoundedWallet01;
  static const AppIconData account_balance_wallet_rounded = HugeIcons.strokeRoundedWallet01;
  static const AppIconData credit_card_rounded = HugeIcons.strokeRoundedCreditCard;
  static const AppIconData payments_outlined = HugeIcons.strokeRoundedMoney01;
  static const AppIconData payments_rounded = HugeIcons.strokeRoundedMoney01;
  static const AppIconData currency_exchange_rounded = HugeIcons.strokeRoundedMoneyExchange01;
  static const AppIconData receipt_long_outlined = HugeIcons.strokeRoundedInvoice01;

  // ── Verification / trust ───────────────────────────────────────────
  static const AppIconData verified_rounded = HugeIcons.strokeRoundedCheckmarkBadge01;
  static const AppIconData verified_user_outlined = HugeIcons.strokeRoundedUserShield01;
  static const AppIconData verified_user_rounded = HugeIcons.strokeRoundedUserShield01;
  static const AppIconData badge_outlined = HugeIcons.strokeRoundedId;
  static const AppIconData description_outlined = HugeIcons.strokeRoundedFile01;
  static const AppIconData workspace_premium_outlined = HugeIcons.strokeRoundedCertificate01;
  static const AppIconData workspace_premium_rounded = HugeIcons.strokeRoundedAward01;
  static const AppIconData military_tech_rounded = HugeIcons.strokeRoundedMedal01;
  static const AppIconData privacy_tip_outlined = HugeIcons.strokeRoundedShield01;
  static const AppIconData lock_outline_rounded = HugeIcons.strokeRoundedLock;
  static const AppIconData help_outline_rounded = HugeIcons.strokeRoundedHelpCircle;
  static const AppIconData upload_file_rounded = HugeIcons.strokeRoundedFileUpload;

  // ── Feedback / status ──────────────────────────────────────────────
  static const AppIconData check_rounded = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const AppIconData check_circle_rounded = HugeIcons.strokeRoundedCheckmarkCircle01;
  static const AppIconData close_rounded = HugeIcons.strokeRoundedCancel01;
  static const AppIconData cancel_outlined = HugeIcons.strokeRoundedCancel01;
  static const AppIconData error_rounded = HugeIcons.strokeRoundedAlertCircle;
  static const AppIconData info_outline_rounded = HugeIcons.strokeRoundedInformationCircle;
  static const AppIconData info_rounded = HugeIcons.strokeRoundedInformationCircle;
  static const AppIconData warning_amber_rounded = HugeIcons.strokeRoundedAlert01;
  static const AppIconData star_rounded = HugeIcons.strokeRoundedStar;
  static const AppIconData star_border_rounded = HugeIcons.strokeRoundedStar;
  static const AppIconData star_outline_rounded = HugeIcons.strokeRoundedStar;
  static const AppIconData favorite_rounded = HugeIcons.strokeRoundedFavourite;
  static const AppIconData favorite_border_rounded = HugeIcons.strokeRoundedFavourite;
  static const AppIconData flag_outlined = HugeIcons.strokeRoundedFlag01;
  static const AppIconData flag_rounded = HugeIcons.strokeRoundedFlag01;
  static const AppIconData block_rounded = HugeIcons.strokeRoundedBlocked;
  static const AppIconData task_alt_rounded = HugeIcons.strokeRoundedTaskDone01;
  static const AppIconData refresh_rounded = HugeIcons.strokeRoundedRefresh01;
  static const AppIconData rotate_left_rounded = HugeIcons.strokeRoundedRotateLeft01;
  static const AppIconData radio_button_checked_rounded = HugeIcons.strokeRoundedRadioButton;
  static const AppIconData radio_button_off_rounded = HugeIcons.strokeRoundedCircle;
  static const AppIconData wifi_off_rounded = HugeIcons.strokeRoundedWifiDisconnected01;
  static const AppIconData dark_mode_outlined = HugeIcons.strokeRoundedMoon01;
  static const AppIconData visibility_outlined = HugeIcons.strokeRoundedEye;
  static const AppIconData visibility_off_outlined = HugeIcons.strokeRoundedViewOff;
  static const AppIconData local_offer_rounded = HugeIcons.strokeRoundedTag01;

  // ── Actions ────────────────────────────────────────────────────────
  static const AppIconData add_rounded = HugeIcons.strokeRoundedAdd01;
  static const AppIconData add_circle_outline_rounded = HugeIcons.strokeRoundedAddCircle;
  static const AppIconData add_circle_rounded = HugeIcons.strokeRoundedAddCircle;
  static const AppIconData remove_circle_outline_rounded = HugeIcons.strokeRoundedRemoveCircle;
  static const AppIconData delete_outline_rounded = HugeIcons.strokeRoundedDelete01;
  static const AppIconData edit_outlined = HugeIcons.strokeRoundedEdit01;
  static const AppIconData edit_rounded = HugeIcons.strokeRoundedEdit01;
  static const AppIconData arrow_back_rounded = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIconData arrow_forward_rounded = HugeIcons.strokeRoundedArrowRight01;
  static const AppIconData arrow_forward_ios_rounded = HugeIcons.strokeRoundedArrowRight01;
  static const AppIconData arrow_downward_rounded = HugeIcons.strokeRoundedArrowDown01;
  static const AppIconData chevron_left_rounded = HugeIcons.strokeRoundedArrowLeft01;
  static const AppIconData chevron_right_rounded = HugeIcons.strokeRoundedArrowRight01;
  static const AppIconData login_rounded = HugeIcons.strokeRoundedLogin01;
  static const AppIconData logout_rounded = HugeIcons.strokeRoundedLogout01;
  static const AppIconData play_arrow_rounded = HugeIcons.strokeRoundedPlay;
  static const AppIconData ios_share_rounded = HugeIcons.strokeRoundedShare01;
  static const AppIconData link_rounded = HugeIcons.strokeRoundedLink01;
  static const AppIconData camera_alt_rounded = HugeIcons.strokeRoundedCamera01;
  static const AppIconData add_photo_alternate_outlined = HugeIcons.strokeRoundedImageAdd01;
  static const AppIconData photo_library_outlined = HugeIcons.strokeRoundedAlbum01;
  static const AppIconData image_outlined = HugeIcons.strokeRoundedImage01;
  static const AppIconData broken_image_outlined = HugeIcons.strokeRoundedImageNotFound01;
  static const AppIconData search_rounded = HugeIcons.strokeRoundedSearch01;
  static const AppIconData search_off_rounded = HugeIcons.strokeRoundedSearchCircle;
  static const AppIconData manage_search_rounded = HugeIcons.strokeRoundedSearchList01;
  static const AppIconData tune_rounded = HugeIcons.strokeRoundedSlidersHorizontal;
  static const AppIconData location_on_outlined = HugeIcons.strokeRoundedLocation01;

  // ── Work / trades / categories ─────────────────────────────────────
  static const AppIconData work_outline_rounded = HugeIcons.strokeRoundedBriefcase01;
  static const AppIconData work_rounded = HugeIcons.strokeRoundedBriefcase01;
  static const AppIconData handyman_outlined = HugeIcons.strokeRoundedTools;
  static const AppIconData handyman_rounded = HugeIcons.strokeRoundedTools;
  static const AppIconData plumbing_rounded = HugeIcons.strokeRoundedWrench01;
  static const AppIconData bolt_rounded = HugeIcons.strokeRoundedZap;
  static const AppIconData school_rounded = HugeIcons.strokeRoundedSchool01;
  static const AppIconData brush_rounded = HugeIcons.strokeRoundedPaintBrush01;
  static const AppIconData photo_camera_rounded = HugeIcons.strokeRoundedCamera01;
  static const AppIconData carpenter_rounded = HugeIcons.strokeRoundedToolbox;
  static const AppIconData storefront_rounded = HugeIcons.strokeRoundedStore01;
  static const AppIconData gavel_rounded = HugeIcons.strokeRoundedJudge;
  static const AppIconData design_services_outlined = HugeIcons.strokeRoundedPenTool01;
  static const AppIconData design_services_rounded = HugeIcons.strokeRoundedPenTool01;
  static const AppIconData bar_chart_rounded = HugeIcons.strokeRoundedBarChart;
  static const AppIconData timeline_rounded = HugeIcons.strokeRoundedTimeline;
  static const AppIconData trending_up_rounded = HugeIcons.strokeRoundedArrowUpRight01;
  static const AppIconData reviews_outlined = HugeIcons.strokeRoundedMessage01;
  static const AppIconData reviews_rounded = HugeIcons.strokeRoundedMessage02;
}
