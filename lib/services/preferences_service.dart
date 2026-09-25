import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Service for syncing notification preferences to Supabase user_preferences table.
class PreferencesService {
  static PreferencesService? _instance;
  static PreferencesService get instance =>
      _instance ??= PreferencesService._();
  PreferencesService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Upsert the current user's notification preferences to Supabase.
  Future<void> savePreferences({
    required bool criticalIncidents,
    required bool teamUpdates,
    required bool assignments,
    required bool quietHoursEnabled,
    required int quietHoursStart,
    required int quietHoursEnd,
    required int priorityThreshold,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('user_preferences').upsert({
        'user_id': userId,
        'notif_critical_incidents': criticalIncidents,
        'notif_team_updates': teamUpdates,
        'notif_assignments': assignments,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'priority_threshold': priorityThreshold,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[PreferencesService] savePreferences error: ${e.message}');
    } catch (e) {
      // ignore: avoid_print
      print('[PreferencesService] savePreferences unexpected error: $e');
    }
  }

  /// Load preferences from Supabase for the current user.
  /// Returns null if no record exists yet.
  Future<Map<String, dynamic>?> loadPreferences() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[PreferencesService] loadPreferences error: ${e.message}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[PreferencesService] loadPreferences unexpected error: $e');
      return null;
    }
  }
}
