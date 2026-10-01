import 'package:shared_preferences/shared_preferences.dart';

/// Stores the officer's last confirmed field values so the form and profile
/// stay consistent even when a team_members row is not available offline.
class OfficerProfileStorage {
  static const _nameKey = 'officer_profile_name';
  static const _badgeKey = 'officer_profile_badge';
  static const _teamKey = 'officer_profile_team';
  static const _rankKey = 'officer_profile_rank';
  static const _shiftKey = 'officer_profile_shift';

  Future<Map<String, String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? '',
      'badge_number': prefs.getString(_badgeKey) ?? '',
      'team_name': prefs.getString(_teamKey) ?? '',
      'rank': prefs.getString(_rankKey) ?? '',
      'shift_status': prefs.getString(_shiftKey) ?? '',
    };
  }

  Future<void> save({
    String? name,
    String? badgeNumber,
    String? teamName,
    String? rank,
    String? shiftStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> put(String key, String? value) async {
      if (value != null && value.trim().isNotEmpty) {
        await prefs.setString(key, value.trim());
      }
    }

    await put(_nameKey, name);
    await put(_badgeKey, badgeNumber);
    await put(_teamKey, teamName);
    await put(_rankKey, rank);
    await put(_shiftKey, shiftStatus);
  }

  static OfficerProfileStorage? _instance;
  static OfficerProfileStorage get instance =>
      _instance ??= OfficerProfileStorage._();
  OfficerProfileStorage._();
}
