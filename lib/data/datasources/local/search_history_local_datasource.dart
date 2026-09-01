import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/exceptions.dart';

/// Persistencia local del historial de búsquedas.
abstract class SearchHistoryLocalDataSource {
  Future<List<String>> getSearchHistory();
  Future<void> saveSearchTerm(String term);
}

class SearchHistoryLocalDataSourceImpl implements SearchHistoryLocalDataSource {
  const SearchHistoryLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'search_history';

  /// Tope de términos guardados: el historial es una comodidad, no un archivo.
  static const int _maxEntries = 20;

  @override
  Future<List<String>> getSearchHistory() async {
    final String? raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const <String>[];

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded.whereType<String>().toList(growable: false);
    } on FormatException catch (error) {
      throw CacheException('Historial ilegible: ${error.message}');
    }
  }

  @override
  Future<void> saveSearchTerm(String term) async {
    final String normalized = term.trim();
    if (normalized.isEmpty) return;

    final List<String> history = await getSearchHistory();
    // El repetido no se duplica: se saca de donde estaba y vuelve al principio.
    final List<String> updated = <String>[
      normalized,
      ...history.where(
        (String entry) => entry.toLowerCase() != normalized.toLowerCase(),
      ),
    ];
    if (updated.length > _maxEntries) {
      updated.removeRange(_maxEntries, updated.length);
    }

    final bool saved = await _prefs.setString(_storageKey, jsonEncode(updated));
    if (!saved) {
      throw const CacheException('No se pudo escribir el historial.');
    }
  }
}
