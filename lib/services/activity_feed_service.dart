import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Types of live activity events broadcast on the home feed.
enum ActivityEventType {
  noteSubmitted,
  draftSaved,
  draftUpdated,
  pdfGenerated,
  profileUpdated,
  syncCompleted,
}

/// A single live activity event shown in the home feed.
class ActivityEvent {
  final String id;
  final ActivityEventType type;
  final String title;
  final String subtitle;
  final String iconName;
  final int iconColorHex;
  final DateTime timestamp;
  final String? officerName;
  final String? badgeNumber;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.iconColorHex,
    required this.timestamp,
    this.officerName,
    this.badgeNumber,
  });

  static ActivityEvent fromSubmittedNote(Map<String, dynamic> record) {
    final name = record['personnel_name'] as String? ?? 'Memur';
    final badge = record['badge_number'] as String? ?? '';
    final subject = record['subject'] as String? ?? 'Bilgi Notu';
    final id = record['id'] as String? ?? DateTime.now().toIso8601String();
    return ActivityEvent(
      id: 'sub_$id',
      type: ActivityEventType.noteSubmitted,
      title: 'Not Gönderildi',
      subtitle: subject,
      iconName: 'send',
      iconColorHex: 0xFF22C55E,
      timestamp:
          DateTime.tryParse(record['submitted_at'] as String? ?? '') ??
          DateTime.now(),
      officerName: name,
      badgeNumber: badge,
    );
  }

  static ActivityEvent fromDraftChange(
    Map<String, dynamic> record,
    bool isNew,
  ) {
    final name = record['personnel_name'] as String? ?? 'Memur';
    final badge = record['badge_number'] as String? ?? '';
    final subject = record['subject'] as String? ?? 'Taslak';
    final id = record['id'] as String? ?? DateTime.now().toIso8601String();
    return ActivityEvent(
      id: 'draft_$id',
      type: isNew
          ? ActivityEventType.draftSaved
          : ActivityEventType.draftUpdated,
      title: isNew ? 'Taslak Kaydedildi' : 'Taslak Güncellendi',
      subtitle: subject,
      iconName: isNew ? 'save' : 'edit',
      iconColorHex: isNew ? 0xFF3B82F6 : 0xFFF59E0B,
      timestamp:
          DateTime.tryParse(record['updated_at'] as String? ?? '') ??
          DateTime.now(),
      officerName: name,
      badgeNumber: badge,
    );
  }

  static ActivityEvent fromPdfRecord(Map<String, dynamic> record) {
    final fileName = record['file_name'] as String? ?? 'Belge';
    final id = record['id'] as String? ?? DateTime.now().toIso8601String();
    return ActivityEvent(
      id: 'pdf_$id',
      type: ActivityEventType.pdfGenerated,
      title: 'PDF Oluşturuldu',
      subtitle: fileName,
      iconName: 'picture_as_pdf',
      iconColorHex: 0xFFEF4444,
      timestamp:
          DateTime.tryParse(
            record['generated_at'] as String? ??
                record['created_at'] as String? ??
                '',
          ) ??
          DateTime.now(),
    );
  }
}

/// Manages Supabase realtime subscriptions and exposes a broadcast stream
/// of [ActivityEvent]s for the home feed.
class ActivityFeedService {
  static ActivityFeedService? _instance;
  static ActivityFeedService get instance =>
      _instance ??= ActivityFeedService._();
  ActivityFeedService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  final _controller = StreamController<ActivityEvent>.broadcast();

  /// Stream of live activity events. Listen to this in the home screen.
  Stream<ActivityEvent> get events => _controller.stream;

  RealtimeChannel? _submittedNotesChannel;
  RealtimeChannel? _draftsChannel;
  RealtimeChannel? _pdfChannel;

  bool _isSubscribed = false;

  /// Start listening to all three tables. Safe to call multiple times.
  void subscribe() {
    if (_isSubscribed) return;
    _isSubscribed = true;

    // ── submitted_notes ───────────────────────────────────────────────────
    _submittedNotesChannel = _client
        .channel('activity_submitted_notes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'submitted_notes',
          callback: (payload) {
            if (!_controller.isClosed) {
              _controller.add(
                ActivityEvent.fromSubmittedNote(payload.newRecord),
              );
            }
          },
        )
        .subscribe();

    // ── bilgi_notu_drafts ─────────────────────────────────────────────────
    _draftsChannel = _client
        .channel('activity_drafts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bilgi_notu_drafts',
          callback: (payload) {
            if (!_controller.isClosed) {
              _controller.add(
                ActivityEvent.fromDraftChange(payload.newRecord, true),
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bilgi_notu_drafts',
          callback: (payload) {
            if (!_controller.isClosed) {
              _controller.add(
                ActivityEvent.fromDraftChange(payload.newRecord, false),
              );
            }
          },
        )
        .subscribe();

    // ── pdf_records ───────────────────────────────────────────────────────
    _pdfChannel = _client
        .channel('activity_pdf_records')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pdf_records',
          callback: (payload) {
            if (!_controller.isClosed) {
              _controller.add(ActivityEvent.fromPdfRecord(payload.newRecord));
            }
          },
        )
        .subscribe();
  }

  /// Stop all subscriptions and release resources.
  void unsubscribe() {
    _submittedNotesChannel?.unsubscribe();
    _draftsChannel?.unsubscribe();
    _pdfChannel?.unsubscribe();
    _submittedNotesChannel = null;
    _draftsChannel = null;
    _pdfChannel = null;
    _isSubscribed = false;
  }

  /// Dispose the service entirely (call when app is shutting down).
  void dispose() {
    unsubscribe();
    _controller.close();
    _instance = null;
  }
}
