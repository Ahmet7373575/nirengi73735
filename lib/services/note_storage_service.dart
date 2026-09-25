import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Supabase CRUD operations for bilgi_notu_drafts, submitted_notes, pdf_records.
class NoteStorageService {
  static NoteStorageService? _instance;
  static NoteStorageService get instance =>
      _instance ??= NoteStorageService._();
  NoteStorageService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Returns the current authenticated user's UUID, or null.
  String? get _currentUserId => _client.auth.currentUser?.id;

  // ── Drafts ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> upsertDraft(Map<String, dynamic> draft) async {
    final payload = Map<String, dynamic>.from(draft);
    payload['updated_at'] = DateTime.now().toIso8601String();
    payload['is_synced'] = true;

    // Remove local-only fields not in DB schema
    payload.remove('remote_id');

    // Attach authenticated user ID
    final userId = _currentUserId;
    if (userId != null) payload['user_id'] = userId;

    final response = await _client
        .from('bilgi_notu_drafts')
        .upsert(payload, onConflict: 'local_id')
        .select()
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchDrafts() async {
    var query = _client
        .from('bilgi_notu_drafts')
        .select()
        .eq('status', 'draft');

    final userId = _currentUserId;
    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final response = await query.order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteDraft(String localId) async {
    await _client.from('bilgi_notu_drafts').delete().eq('local_id', localId);
  }

  Future<void> markDraftSubmitted(String localId) async {
    await _client
        .from('bilgi_notu_drafts')
        .update({'status': 'submitted', 'is_synced': true})
        .eq('local_id', localId);
  }

  /// Fetches a single draft from Supabase by its local_id.
  /// Returns null if not found.
  Future<Map<String, dynamic>?> fetchDraftByLocalId(String localId) async {
    final response = await _client
        .from('bilgi_notu_drafts')
        .select()
        .eq('local_id', localId)
        .maybeSingle();
    return response;
  }

  // ── Submitted notes ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> upsertSubmittedNote(
    Map<String, dynamic> note,
  ) async {
    final payload = Map<String, dynamic>.from(note);
    payload.remove('remote_id');

    // Attach authenticated user ID
    final userId = _currentUserId;
    if (userId != null) payload['user_id'] = userId;

    final response = await _client
        .from('submitted_notes')
        .upsert(payload, onConflict: 'local_id')
        .select()
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchSubmittedNotes() async {
    var query = _client.from('submitted_notes').select();

    final userId = _currentUserId;
    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final response = await query.order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ── PDF records ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> upsertPdfRecord(
    Map<String, dynamic> record,
  ) async {
    final payload = Map<String, dynamic>.from(record);
    payload.remove('remote_id');

    // Attach authenticated user ID
    final userId = _currentUserId;
    if (userId != null) payload['user_id'] = userId;

    final response = await _client
        .from('pdf_records')
        .upsert(payload, onConflict: 'local_id')
        .select()
        .maybeSingle();

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchPdfRecords() async {
    var query = _client.from('pdf_records').select();

    final userId = _currentUserId;
    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updatePdfStatus(
    String localId,
    String status, {
    String? filePath,
    int? fileSizeBytes,
  }) async {
    final update = <String, dynamic>{'pdf_status': status};
    if (status == 'generated') {
      update['generated_at'] = DateTime.now().toIso8601String();
    }
    if (filePath != null) update['file_path'] = filePath;
    if (fileSizeBytes != null) update['file_size_bytes'] = fileSizeBytes;

    await _client.from('pdf_records').update(update).eq('local_id', localId);
  }
}
