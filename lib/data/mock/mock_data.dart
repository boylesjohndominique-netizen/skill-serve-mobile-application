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

  // ---- Providers ----
  static final List<ProviderModel> providers = List.generate(16, (i) {
    final cat = _pick(categories);
    final user = UserModel(
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
      bio: 'Reliable, background-checked ${cat.name.toLowerCase()} professional serving the Visayas region.',
      yearsExperience: 1 + _rand.nextInt(14),
      verificationStatus: i % 5 == 0 ? 'pending' : 'verified',
      averageRating: 3.5 + _rand.nextDouble() * 1.5,
      reviewCount: 5 + _rand.nextInt(120),
      completedJobs: 10 + _rand.nextInt(200),
      categoryName: cat.name,
      portfolioImages: List.generate(4, (j) => 'https://picsum.photos/seed/${cat.name}$i$j/500/400'),
      startingPrice: (250 + _rand.nextInt(2500)).toDouble(),
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
    return BookingModel(
      id: 'BK-${5000 + i}',
      clientId: currentClient.id,
      clientName: currentClient.fullName,
      providerId: p.id,
      providerName: p.user.fullName,
      serviceId: 'SV-$i',
      serviceTitle: '${p.categoryName} Service',
      bookingDate: DateTime.now().add(Duration(days: i - 4)),
      schedule: '${9 + _rand.nextInt(8)}:00 AM',
      status: BookingStatus.values[_rand.nextInt(BookingStatus.values.length)],
      amount: (400 + _rand.nextInt(4000)).toDouble(),
      address: currentClient.address,
    );
  });

  static final List<BookingModel> bookingsForProvider = List.generate(11, (i) {
    return BookingModel(
      id: 'BK-${6000 + i}',
      clientId: 'CL-${1100 + i}',
      clientName: '${_pick(_firstNames)} ${_pick(_lastNames)}',
      providerId: currentProvider.id,
      providerName: currentProvider.fullName,
      serviceId: 'SV-p$i',
      serviceTitle: '${_pick(categories).name} Service',
      bookingDate: DateTime.now().add(Duration(days: i - 5)),
      schedule: '${9 + _rand.nextInt(8)}:00 AM',
      status: BookingStatus.values[_rand.nextInt(BookingStatus.values.length)],
      amount: (400 + _rand.nextInt(4000)).toDouble(),
      address: _pick(['Lahug, Cebu City', 'IT Park, Cebu City', 'Talisay, Cebu']),
    );
  });

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
        status: i == 0 ? 'pending' : 'approved',
      ));
}
