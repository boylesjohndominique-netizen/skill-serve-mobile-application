import 'package:shared_preferences/shared_preferences.dart';

/// The client's recent search terms.
///
/// Search history is a device convenience rather than account data — the API
/// documents no endpoint for it — so it is stored locally with the other
/// on-device preferences and can be cleared by the user at any time.
class RecentSearchesService {
  static const storageKey = 'skillserve.search.recent';

  /// Keeps the list short enough to render as chips without scrolling.
  static const maxEntries = 8;

  Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(storageKey) ?? const [];
  }

  /// Stores [term] as the newest entry, de-duplicated case-insensitively and
  /// capped at [maxEntries]. Blank terms are ignored.
  Future<List<String>> add(String term) async {
    final value = term.trim();
    if (value.isEmpty) return read();

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(storageKey) ?? const <String>[];
    final updated = <String>[
      value,
      ...existing.where((entry) => entry.toLowerCase() != value.toLowerCase()),
    ].take(maxEntries).toList();

    await prefs.setStringList(storageKey, updated);
    return updated;
  }

  Future<List<String>> remove(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = (prefs.getStringList(storageKey) ?? const <String>[])
        .where((entry) => entry.toLowerCase() != term.trim().toLowerCase())
        .toList();
    await prefs.setStringList(storageKey, updated);
    return updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
