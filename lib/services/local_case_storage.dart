import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-first storage for case folders and their related records.
///
/// Every write is committed to the device before a best-effort Supabase sync.
/// This keeps the field workflow usable without an account or network.
class LocalCaseStorage {
  LocalCaseStorage._();

  static const _incidentsKey = 'bekci_local_incidents';
  static const _entitiesKey = 'bekci_local_case_entities';

  static Future<List<Map<String, dynamic>>> incidents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_incidentsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveIncident(Map<String, dynamic> incident) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await incidents();
    final localId = incident['local_id']?.toString() ?? '';
    final index = items.indexWhere((item) => item['local_id'] == localId);
    if (index >= 0) {
      items[index] = {...items[index], ...incident};
    } else {
      items.insert(0, incident);
    }
    await prefs.setString(_incidentsKey, jsonEncode(items));
  }

  static Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _entities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entitiesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, Map<String, List<Map<String, dynamic>>>>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        final groups = value is Map ? value : <dynamic, dynamic>{};
        result[key] = {
          'persons': _asList(groups['persons']),
          'vehicles': _asList(groups['vehicles']),
          'documents': _asList(groups['documents']),
          'media': _asList(groups['media']),
          'history': _asList(groups['history']),
        };
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> _saveEntities(
    Map<String, Map<String, List<Map<String, dynamic>>>> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entitiesKey, jsonEncode(values));
  }

  static Future<List<Map<String, dynamic>>> list(
    String incidentId,
    String collection,
  ) async {
    final values = await _entities();
    return List<Map<String, dynamic>>.from(
      values[incidentId]?[collection] ?? const <Map<String, dynamic>>[],
    );
  }

  static Future<Map<String, dynamic>> add(
    String incidentId,
    String collection,
    Map<String, dynamic> value,
  ) async {
    final values = await _entities();
    final groups = values.putIfAbsent(
      incidentId,
      () => {
        'persons': <Map<String, dynamic>>[],
        'vehicles': <Map<String, dynamic>>[],
        'documents': <Map<String, dynamic>>[],
        'media': <Map<String, dynamic>>[],
        'history': <Map<String, dynamic>>[],
      },
    );
    final row = {
      'local_id': '${collection}_$incidentId_${DateTime.now().microsecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
      ...value,
    };
    groups[collection] ??= <Map<String, dynamic>>[];
    groups[collection]!.insert(0, row);
    await _saveEntities(values);
    return row;
  }
}
