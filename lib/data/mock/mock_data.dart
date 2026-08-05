import 'dart:math';
import '../../models/user_model.dart';
import '../../models/provider_model.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';
import '../../models/booking_model.dart';
import '../../models/review_model.dart';
import '../../models/message_model.dart';
import '../../models/notification_model.dart';
import '../../models/portfolio_model.dart';
import '../../models/payment_model.dart';
import '../../models/report_model.dart';
import '../../models/verification_document_model.dart';
import '../../models/badge_model.dart';

/// In-memory sample data standing in for the future Laravel REST API.
/// Every placeholder service in lib/services reads from here.
class MockData {
  MockData._();

  static final Random _rand = Random(7);

  // ---- Current signed-in user (swap based on login flow selection) ----
  static final UserModel currentClient = UserModel(
    id: 'CL-1001',
    role: UserRole.client,
    firstName: 'Andrea',
    lastName: 'Santos',
    email: 'andrea.santos@mail.com',
    phone: '09171234567',
    address: 'Lahug, Cebu City',
    createdAt: DateTime.now().subtract(const Duration(days: 210)),
  );

  static final UserModel currentProvider = UserModel(
    id: 'PR-2001',
    role: UserRole.provider,
    firstName: 'Miguel',
    lastName: 'Reyes',
    email: 'miguel.reyes@mail.com',
    phone: '09181234567',
    address: 'Tagbilaran City, Bohol',
    createdAt: DateTime.now().subtract(const Duration(days: 380)),
  );

  // ---- Categories ----
  static const List<CategoryModel> categories = [
    CategoryModel(id: '1', name: 'Plumbing', icon: 'plumbing', providerCount: 42),
    CategoryModel(id: '2', name: 'Electrician', icon: 'bolt', providerCount: 37),
    CategoryModel(id: '3', name: 'Tutor', icon: 'school', providerCount: 58),
    CategoryModel(id: '4', name: 'Graphic Designer', icon: 'brush', providerCount: 29),
    CategoryModel(id: '5', name: 'Photographer', icon: 'photo_camera', providerCount: 24),
    CategoryModel(id: '6', name: 'Carpenter', icon: 'carpenter', providerCount: 33),
  ];

  static final List<String> _firstNames = [
    'Josh', 'Kim', 'Ella', 'Rafael', 'Bea', 'Carlo', 'Nadine', 'Paolo',
    'Trisha', 'Ivan', 'Mika', 'Diego', 'Sofia', 'Liam', 'Chloe', 'Marco',
  ];
  static final List<String> _lastNames = [
    'Cruz', 'Bautista', 'Ocampo', 'Torres', 'Garcia', 'Mendoza', 'Aquino',
    'Villanueva', 'Navarro', 'Castillo', 'Domingo', 'Ramos',
  ];

  static T _pick<T>(List<T> list) => list[_rand.nextInt(list.length)];

  static const List<String> paymentMethods = ['GCash', 'Maya', 'Cash on hand', 'Card'];
  static const List<String> reportReasons = [
    'No-show for scheduled booking',
    'Inappropriate messages',
    'Overcharging beyond quote',
    'Fake portfolio images',
    'Harassment',
    'Poor workmanship / unresolved damage',
  ];

  /// Builds a plausible status timeline for a booking at a given status.
  static List<BookingTimelineEntry> _timelineFor(BookingStatus status, DateTime bookingDate) {
    final entries = <BookingTimelineEntry>[
      BookingTimelineEntry(
        label: 'Booking requested',
        at: bookingDate.subtract(const Duration(days: 5)),
        status: 'pending',
      ),
    ];
    if (status == BookingStatus.pending) return entries;
    entries.add(BookingTimelineEntry(
      label: 'Accepted by provider',
      at: bookingDate.subtract(const Duration(days: 3)),
      status: 'confirmed',
    ));
    if (status == BookingStatus.confirmed) return entries;
    entries.add(BookingTimelineEntry(
      label: 'Job in progress',
      at: bookingDate.subtract(const Duration(days: 1)),
      status: 'inProgress',
    ));
    if (status == BookingStatus.inProgress) return entries;
    if (status == BookingStatus.completed) {
      entries.add(BookingTimelineEntry(label: 'Completed', at: bookingDate, status: 'completed'));
    } else if (status == BookingStatus.cancelled) {
      entries.add(BookingTimelineEntry(
        label: 'Cancelled',
        at: bookingDate.subtract(const Duration(days: 2)),
        status: 'cancelled',
      ));
    } else if (status == BookingStatus.disputed) {
      entries.add(BookingTimelineEntry(label: 'Disputed', at: bookingDate, status: 'disputed'));
    }
    return entries;
  }

  // ---- Providers ----
  // Index 0 is the signed-in demo provider (Miguel Reyes) so the Provider
  // app's own profile preview, dashboard, and services stay coherent.
  static final List<ProviderModel> providers = List.generate(16, (i) {
    final cat = i == 0 ? categories[1] : _pick(categories);
    final user = i == 0
        ? currentProvider
        : UserModel(
            id: 'PR-${3000 + i}',
            role: UserRole.provider,
            firstName: _pick(_firstNames),
            lastName: _pick(_lastNames),
            email: 'provider$i@mail.com',
            phone: '09${100000000 + i}',
            address: _pick(['Cebu City', 'Mandaue City', 'Tagbilaran, Bohol', 'Dumaguete', 'Lapu-Lapu City']),
            createdAt: DateTime.now().subtract(Duration(days: 30 + i * 11)),
          );
    return ProviderModel(
      id: 'PV-${100 + i}',
      user: user,
      bio: i == 0
          ? 'Licensed electrician serving households and small businesses across Bohol for 9 years. Licensed, insured, and background-checked — safety first on every job.'
          : 'Reliable, background-checked ${cat.name.toLowerCase()} professional serving the Visayas region.',
      yearsExperience: i == 0 ? 9 : 1 + _rand.nextInt(14),
      verificationStatus: i == 0 ? 'verified' : (i % 5 == 0 ? 'pending' : 'verified'),
      averageRating: i == 0 ? 4.8 : 3.5 + _rand.nextDouble() * 1.5,
      reviewCount: i == 0 ? 156 : 5 + _rand.nextInt(120),
      completedJobs: i == 0 ? 118 : 10 + _rand.nextInt(200),
      categoryName: cat.name,
      portfolioImages: List.generate(4, (j) => 'https://picsum.photos/seed/${cat.name}$i$j/500/400'),
      startingPrice: i == 0 ? 550 : (250 + _rand.nextInt(2500)).toDouble(),
    );
  });

  // ---- Services ----
  static final List<ServiceModel> services = List.generate(providers.length, (i) {
    final p = providers[i];
    return ServiceModel(
      id: 'SV-${i + 1}',
      providerId: p.id,
      categoryId: categories.firstWhere((c) => c.name == p.categoryName).id,
      title: '${p.categoryName} Service — ${p.user.firstName}',
      description:
          'Professional ${p.categoryName.toLowerCase()} service covering diagnostics, repair, and clean finishing. Satisfaction guaranteed.',
      price: p.startingPrice ?? 500,
      duration: '${1 + _rand.nextInt(3)}–${2 + _rand.nextInt(4)} hrs',
      coverImage: 'https://picsum.photos/seed/service$i/600/400',
    );
  });

  // ---- Bookings ----
  static final List<BookingModel> bookingsForClient = List.generate(9, (i) {
    final p = _pick(providers);
    final status = BookingStatus.values[_rand.nextInt(BookingStatus.values.length)];
    final date = DateTime.now().add(Duration(days: i - 4));
    return BookingModel(
      id: 'BK-${5000 + i}',
      clientId: currentClient.id,
      clientName: currentClient.fullName,
      providerId: p.id,
      providerName: p.user.fullName,
      serviceId: 'SV-$i',
      serviceTitle: '${p.categoryName} Service',
      bookingDate: date,
      schedule: '${9 + _rand.nextInt(8)}:00 AM',
      status: status,
      amount: (400 + _rand.nextInt(4000)).toDouble(),
      address: currentClient.address,
      paymentMethod: paymentMethods[i % paymentMethods.length],
      timeline: _timelineFor(status, date),
    );
  });

  static final List<BookingModel> bookingsForProvider = List.generate(11, (i) {
    final status = BookingStatus.values[_rand.nextInt(BookingStatus.values.length)];
    final date = DateTime.now().add(Duration(days: i - 5));
    return BookingModel(
      id: 'BK-${6000 + i}',
      clientId: 'CL-${1100 + i}',
      clientName: '${_pick(_firstNames)} ${_pick(_lastNames)}',
      providerId: currentProvider.id,
      providerName: currentProvider.fullName,
      serviceId: 'SV-p$i',
      serviceTitle: '${_pick(categories).name} Service',
      bookingDate: date,
      schedule: '${9 + _rand.nextInt(8)}:00 AM',
      status: status,
      amount: (400 + _rand.nextInt(4000)).toDouble(),
      address: _pick(['Lahug, Cebu City', 'IT Park, Cebu City', 'Talisay, Cebu']),
      paymentMethod: paymentMethods[(i + 1) % paymentMethods.length],
      timeline: _timelineFor(status, date),
    );
  });

  // ---- Payments ----
  static final List<PaymentModel> payments = List.generate(8, (i) {
    final booking = bookingsForClient.length > i ? bookingsForClient[i] : bookingsForClient.first;
    final status = PaymentStatus.values[i % PaymentStatus.values.length];
    final method = paymentMethods[i % paymentMethods.length];
    final isCash = method == 'Cash on hand';
    return PaymentModel(
      id: 'PAY-${8000 + i}',
      bookingId: booking.id,
      clientName: currentClient.fullName,
      providerName: booking.providerName,
      method: method,
      amount: booking.amount,
      status: status,
      reference: '${isCash ? 'COD' : 'TXN'}-${123456 + i * 1001}',
      paidAt: DateTime.now().subtract(Duration(days: i * 3 + 1)),
    );
  });

  // ---- Reports (complaints / disputes) ----
  static final List<ReportModel> reports = [
    ReportModel(
      id: 'RP-1001',
      reporterName: currentClient.fullName,
      reportedName: 'Miguel Reyes',
      reason: 'Overcharging beyond quote',
      details: 'I was quoted ₱800 but charged ₱1,500 after the job was done without any prior notice.',
      status: ReportStatus.investigating,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updates: [
        ReportUpdate(label: 'Report filed', at: DateTime.now().subtract(const Duration(days: 6)), status: 'open'),
        ReportUpdate(label: 'Under investigation', at: DateTime.now().subtract(const Duration(days: 4)), status: 'investigating'),
      ],
    ),
    ReportModel(
      id: 'RP-1002',
      reporterName: currentClient.fullName,
      reportedName: 'Jose Garcia',
      reason: 'No-show for scheduled booking',
      details: 'The provider never arrived at the agreed schedule and did not respond to messages.',
      status: ReportStatus.closed,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updates: [
        ReportUpdate(label: 'Report filed', at: DateTime.now().subtract(const Duration(days: 20)), status: 'open'),
        ReportUpdate(label: 'Provider warned', at: DateTime.now().subtract(const Duration(days: 15)), status: 'warned'),
        ReportUpdate(label: 'Report closed', at: DateTime.now().subtract(const Duration(days: 12)), status: 'closed'),
      ],
    ),
  ];

  // ---- Verification documents (current provider) ----
  static final List<VerificationDocumentModel> verificationDocs = [
    VerificationDocumentModel(
      id: 'VD-1',
      providerId: currentProvider.id,
      type: 'ID',
      label: 'Government-issued ID',
      status: 'approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    VerificationDocumentModel(
      id: 'VD-2',
      providerId: currentProvider.id,
      type: 'Certificate',
      label: 'Certificate of training',
      status: 'approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    VerificationDocumentModel(
      id: 'VD-3',
      providerId: currentProvider.id,
      type: 'Document',
      label: 'Proof of address',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  // ---- Recognition badges (current provider) ----
  static final List<BadgeModel> badges = [
    const BadgeModel(
      key: 'verified_pro',
      title: 'Verified Pro',
      criteria: 'Full document verification + approved portfolio',
      earned: true,
      progress: 1,
      progressLabel: 'Complete',
    ),
    const BadgeModel(
      key: 'top_rated',
      title: 'Top Rated',
      criteria: '4.5+ average rating and 20+ completed jobs',
      earned: true,
      progress: 1,
      progressLabel: '4.8 ★ · 156 jobs',
    ),
    const BadgeModel(
      key: 'veteran',
      title: 'Veteran',
      criteria: '5+ years experience and 100+ completed jobs',
      earned: false,
      progress: 0.55,
      progressLabel: '5 yrs · 118/100 jobs',
    ),
    const BadgeModel(
      key: 'rising_star',
      title: 'Rising Star',
      criteria: 'High rating with rapid booking growth in 60 days',
      earned: false,
      progress: 0.7,
      progressLabel: '70% booking growth',
    ),
    const BadgeModel(
      key: 'community_favorite',
      title: 'Community Favorite',
      criteria: 'Most-reviewed provider with positive feedback',
      earned: false,
      progress: 0.4,
      progressLabel: '40% of top reviews',
    ),
  ];

  /// Providers shown in the Discover "Featured" strip (verified only).
  static final List<ProviderModel> featuredProviders =
      providers.where((p) => p.isVerified).take(6).toList();

  // ---- Reviews ----
  static final List<String> _snippets = [
    'Arrived on time and did excellent work. Highly recommended!',
    'Very professional and communicated clearly throughout the job.',
    'Good service overall, would book again.',
    'Fixed the issue quickly and cleaned up afterward.',
    'Friendly and skilled — exceeded expectations.',
  ];
  static final List<ReviewModel> reviews = List.generate(14, (i) => ReviewModel(
        id: 'RV-$i',
        bookingId: 'BK-${5000 + i}',
        clientName: '${_pick(_firstNames)} ${_pick(_lastNames)}',
        rating: (3 + _rand.nextInt(3)).toDouble(),
        comment: _pick(_snippets),
        createdAt: DateTime.now().subtract(Duration(days: _rand.nextInt(60))),
      ));

  // ---- Conversations & messages ----
  static final List<ConversationModel> conversations = List.generate(6, (i) => ConversationModel(
        id: 'CV-$i',
        participantName: '${_pick(_firstNames)} ${_pick(_lastNames)}',
        lastMessage: _pick([
          'Sure, see you at 10 AM tomorrow!',
          'Can you send a photo of the issue?',
          'Thank you for the excellent service!',
          'What time works best for you?',
          'Booking confirmed, thanks!',
        ]),
        lastMessageAt: DateTime.now().subtract(Duration(minutes: i * 47)),
        unreadCount: i < 2 ? 1 + i : 0,
        isOnline: i % 2 == 0,
      ));

  static List<MessageModel> messagesFor(String conversationId) => List.generate(10, (i) {
        final fromMe = i.isEven;
        return MessageModel(
          id: '$conversationId-$i',
          senderId: fromMe ? currentClient.id : 'other',
          receiverId: fromMe ? 'other' : currentClient.id,
          content: _pick([
            'Hi! Is this weekend available for booking?',
            'Yes, Saturday morning works.',
            'Great, I\'ll confirm the booking now.',
            'Thank you, see you then!',
            'Do you provide your own materials?',
          ]),
          sentAt: DateTime.now().subtract(Duration(minutes: (10 - i) * 12)),
          isRead: true,
        );
      });

  // ---- Notifications ----
  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'NT-1',
      title: 'Booking confirmed',
      message: 'Your plumbing service with Miguel Reyes is confirmed for tomorrow, 9:00 AM.',
      type: NotificationType.booking,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'NT-2',
      title: 'New message',
      message: 'Bea Cruz sent you a message about your upcoming booking.',
      type: NotificationType.message,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotificationModel(
      id: 'NT-3',
      title: 'Verification approved',
      message: 'Your provider ID has been verified. You can now accept bookings.',
      type: NotificationType.verification,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: 'NT-4',
      title: 'Weekend promo',
      message: 'Clients get 10% off their first booking this weekend — share the word!',
      type: NotificationType.promo,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  // ---- Portfolio ----
  static final List<PortfolioModel> portfolio = List.generate(8, (i) => PortfolioModel(
        id: 'PF-$i',
        providerId: currentProvider.id,
        image: 'https://picsum.photos/seed/portfolio$i/500/500',
        title: _pick(['Bathroom Repipe', 'Panel Upgrade', 'Cabinet Build', 'Circuit Rewire']),
        description: 'Completed project shared to the public profile.',
        status: i == 0 ? 'pending' : (i == 5 ? 'rejected' : 'approved'),
      ));
}
