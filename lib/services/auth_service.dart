import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Supabase authentication service for field officers.
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Returns the currently authenticated user, or null if not signed in.
  User? get currentUser => SupabaseService.isInitialized
      ? _client.auth.currentUser
      : null;

  /// Returns the current user's UUID, or null.
  String? get currentUserId => currentUser?.id;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Loads the officer/team row so profile fields are not limited to auth metadata.
  Future<Map<String, dynamic>?> fetchCurrentTeamMember() async {
    final userId = currentUserId;
    if (userId == null) return null;
    final result = await _client
        .from('team_members')
        .select('name, badge_number, rank, team_name, shift_status, email')
        .eq('user_id', userId)
        .maybeSingle();
    return result;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Giriş sırasında bir hata oluştu: ${e.toString()}');
    }
  }

  /// Sign in using badge number and password.
  Future<AuthResponse> signInWithBadge({
    required String badgeNumber,
    required String password,
  }) async {
    try {
      final result = await _client
          .from('team_members')
          .select('user_id')
          .eq('badge_number', badgeNumber.trim())
          .maybeSingle();

      if (result == null || result['user_id'] == null) {
        throw AuthException('Bu sicil numarasına kayıtlı hesap bulunamadı.');
      }

      final userId = result['user_id'] as String;

      final emailResult = await _client
          .from('team_members')
          .select('email')
          .eq('user_id', userId)
          .maybeSingle();

      final email = emailResult?['email'] as String?;
      if (email == null || email.isEmpty) {
        throw AuthException(
          'Bu sicil numarasına bağlı e-posta adresi bulunamadı. Lütfen e-posta ile giriş yapın.',
        );
      }

      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sicil numarası ile giriş hatası: ${e.toString()}');
    }
  }

  /// Sign up a new field officer account.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? badgeNumber,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (badgeNumber != null && badgeNumber.isNotEmpty)
            'badge_number': badgeNumber,
        },
      );

      if (response.user != null &&
          badgeNumber != null &&
          badgeNumber.isNotEmpty) {
        try {
          await _client.from('team_members').upsert({
            'user_id': response.user!.id,
            'badge_number': badgeNumber.trim(),
            'name': fullName ?? email.split('@').first,
            'email': email.trim(),
          }, onConflict: 'badge_number');
        } catch (_) {
          // Non-fatal: team_members upsert failure doesn't block auth
        }
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Kayıt sırasında bir hata oluştu: ${e.toString()}');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      // Ignore sign-out errors — local session is cleared regardless
    }
  }

  /// Returns true if a user is currently signed in.
  bool get isAuthenticated => currentUser != null;
}
