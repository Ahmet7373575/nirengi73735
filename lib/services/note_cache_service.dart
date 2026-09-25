import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './note_storage_service.dart';

/// Local-first caching layer for bilgi notu data.
/// Stores drafts, submitted notes, and PDF records in SharedPreferences
/// and syncs to Supabase when connectivity is restored.
class NoteCacheService {
  static NoteCacheService? _instance;
  static NoteCacheService get instance => _instance ??= NoteCacheService._();
  NoteCacheService._();

  static const String _draftsKey = 'bilgi_notu_drafts';
  static const String _submittedKey = 'bilgi_notu_submitted';
  static const String _pdfRecordsKey = 'bilgi_notu_pdf_records';
  static const String _pendingSyncKey = 'bilgi_notu_pending_sync';

  // ── Connectivity listener ─────────────────────────────────────────────────

  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        _syncPendingItems();
      }
    });
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // ── Draft operations ──────────────────────────────────────────────────────

  Future<void> saveDraftLocally(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getLocalDrafts();
    final localId = draft['local_id'] as String;

    final idx = drafts.indexWhere((d) => d['local_id'] == localId);
    if (idx >= 0) {
      drafts[idx] = draft;
    } else {
      drafts.add(draft);
    }

    await prefs.setString(_draftsKey, jsonEncode(drafts));
    await _markPendingSync('draft', localId);
  }

  Future<List<Map<String, dynamic>>> getLocalDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> deleteDraftLocally(String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getLocalDrafts();
    drafts.removeWhere((d) => d['local_id'] == localId);
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  // ── Submitted note operations ─────────────────────────────────────────────

  Future<void> saveSubmittedNoteLocally(Map<String, dynamic> note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getLocalSubmittedNotes();
    final localId = note['local_id'] as String;

    final idx = notes.indexWhere((n) => n['local_id'] == localId);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }

    await prefs.setString(_submittedKey, jsonEncode(notes));
    await _markPendingSync('submitted', localId);
  }

  Future<List<Map<String, dynamic>>> getLocalSubmittedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_submittedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ── PDF record operations ─────────────────────────────────────────────────

  Future<void> savePdfRecordLocally(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getLocalPdfRecords();
    final localId = record['local_id'] as String;

    final idx = records.indexWhere((r) => r['local_id'] == localId);
    if (idx >= 0) {
      records[idx] = record;
    } else {
      records.add(record);
    }

    await prefs.setString(_pdfRecordsKey, jsonEncode(records));
    await _markPendingSync('pdf', localId);
  }

  Future<List<Map<String, dynamic>>> getLocalPdfRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pdfRecordsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Pending sync tracking ─────────────────────────────────────────────────

  Future<void> _markPendingSync(String type, String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingSyncKey);
    final pending = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final exists = pending.any(
      (p) => p['type'] == type && p['local_id'] == localId,
    );
    if (!exists) {
      pending.add({'type': type, 'local_id': localId});
      await prefs.setString(_pendingSyncKey, jsonEncode(pending));
    }
  }

  Future<void> _removePendingSync(String type, String localId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingSyncKey);
    if (raw == null) return;
    final pending = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    pending.removeWhere((p) => p['type'] == type && p['local_id'] == localId);
    await prefs.setString(_pendingSyncKey, jsonEncode(pending));
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingSyncKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  // ── Sync logic ────────────────────────────────────────────────────────────

  Future<void> _syncPendingItems() async {
    final pending = await getPendingSyncItems();
    if (pending.isEmpty) return;

    final storageService = NoteStorageService.instance;

    for (final item in List.from(pending)) {
      final type = item['type'] as String;
      final localId = item['local_id'] as String;

      try {
        if (type == 'draft') {
          final drafts = await getLocalDrafts();
          final draft = drafts.firstWhere(
            (d) => d['local_id'] == localId,
            orElse: () => {},
          );
          if (draft.isNotEmpty) {
            await storageService.upsertDraft(draft);
            await _removePendingSync(type, localId);
          }
        } else if (type == 'submitted') {
          final notes = await getLocalSubmittedNotes();
          final note = notes.firstWhere(
            (n) => n['local_id'] == localId,
            orElse: () => {},
          );
          if (note.isNotEmpty) {
            await storageService.upsertSubmittedNote(note);
            await _removePendingSync(type, localId);
          }
        } else if (type == 'pdf') {
          final records = await getLocalPdfRecords();
          final record = records.firstWhere(
            (r) => r['local_id'] == localId,
            orElse: () => {},
          );
          if (record.isNotEmpty) {
            await storageService.upsertPdfRecord(record);
            await _removePendingSync(type, localId);
          }
        }
      } catch (_) {
        // Keep in pending queue — will retry on next connectivity event
      }
    }
  }

  /// Force sync all pending items (call when app resumes or user requests)
  Future<SyncResult> syncNow() async {
    if (!await _isOnline()) {
      return SyncResult(success: false, message: 'Çevrimdışı — sync ertelendi');
    }
    final pendingBefore = await getPendingSyncItems();
    await _syncPendingItems();
    final pendingAfter = await getPendingSyncItems();
    final synced = pendingBefore.length - pendingAfter.length;
    return SyncResult(
      success: true,
      message: synced > 0
          ? '$synced kayıt senkronize edildi'
          : 'Tüm kayıtlar güncel',
      syncedCount: synced,
    );
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });
}
