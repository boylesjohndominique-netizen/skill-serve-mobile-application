import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/marketplace/controllers/favorites_controller.dart';
import 'package:skilllink_mobile/features/marketplace/models/provider_model.dart';
import 'package:skilllink_mobile/features/marketplace/services/favorites_service.dart';

ProviderModel _provider(int id, String name) =>
    ProviderModel.fromJson({'id': id, 'business_name': name});

/// Stands in for the favorites endpoints; [failNext] makes the next write fail.
class _FakeFavoritesService extends FavoritesService {
  final saved = <String, ProviderModel>{};
  bool failNext = false;

  @override
  Future<List<ProviderModel>> list() async => saved.values.toList().reversed.toList();

  @override
  Future<void> add(String providerId) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    saved[providerId] = _provider(int.parse(providerId), 'P$providerId');
  }

  @override
  Future<void> remove(String providerId) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    saved.remove(providerId);
  }
}

void main() {
  group('FavoritesController', () {
    test('signing in as a customer loads the saved list from the server', () async {
      final service = _FakeFavoritesService()..saved['3'] = _provider(3, 'Juan Aircon');
      final favorites = FavoritesController(service: service);

      await favorites.onAuthChanged(signedInAsClient: true);

      expect(favorites.isFavorite('3'), isTrue);
      expect(favorites.providers.single.id, '3');
    });

    test('a toggle is saved on the server, newest first, and can be undone', () async {
      final service = _FakeFavoritesService();
      final favorites = FavoritesController(service: service);
      await favorites.onAuthChanged(signedInAsClient: true);

      expect(await favorites.toggle(_provider(1, 'One')), isTrue);
      expect(await favorites.toggle(_provider(2, 'Two')), isTrue);
      expect(service.saved.keys, containsAll(['1', '2']));
      expect(favorites.providers.map((p) => p.id), ['2', '1']);

      expect(await favorites.toggle(_provider(1, 'One')), isTrue);
      expect(favorites.isFavorite('1'), isFalse);
      expect(service.saved.keys, ['2']);
    });

    test('a failed save puts the heart back and explains why', () async {
      final service = _FakeFavoritesService()..failNext = true;
      final favorites = FavoritesController(service: service);
      await favorites.onAuthChanged(signedInAsClient: true);

      expect(await favorites.toggle(_provider(1, 'One')), isFalse);
      expect(favorites.isFavorite('1'), isFalse);
      expect(favorites.providers, isEmpty);
      expect(favorites.errorMessage, isNotNull);
    });

    test('guests are asked to sign in, and signing out forgets the list', () async {
      final service = _FakeFavoritesService()..saved['3'] = _provider(3, 'Juan Aircon');
      final favorites = FavoritesController(service: service);

      expect(await favorites.toggle(_provider(1, 'One')), isFalse);
      expect(favorites.errorMessage, contains('Sign in'));
      expect(service.saved.keys, ['3']);

      await favorites.onAuthChanged(signedInAsClient: true);
      await favorites.onAuthChanged(signedInAsClient: false);
      expect(favorites.favoriteIds, isEmpty);
      expect(favorites.providers, isEmpty);
    });
  });
}
