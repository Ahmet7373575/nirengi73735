import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Model for a rapid incident submission.
class IncidentModel {
  final String? id;
  final String localId;
  final String title;
  final String description;
  final String? location;
  final String? reporterName;
  final String priority; // 'low' | 'medium' | 'high' | 'critical'
  final String incidentStatus; // 'open' | 'in_progress' | 'resolved' | 'closed'
  final String? assignedTeamId;
  final String? assignedTeamName;
  final String? aiSuggestedPriority;
  final String? aiSuggestedCategory;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAccuracy;
  final DateTime? gpsPingedAt;
  final DateTime? submittedAt;
  final String? userId;

  const IncidentModel({
    this.id,
    required this.localId,
    required this.title,
    required this.description,
    this.location,
    this.reporterName,
    required this.priority,
    required this.incidentStatus,
    this.assignedTeamId,
    this.assignedTeamName,
    this.aiSuggestedPriority,
    this.aiSuggestedCategory,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAccuracy,
    this.gpsPingedAt,
    this.submittedAt,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'title': title,
    'description': description,
    if (location != null) 'location': location,
    if (reporterName != null) 'reporter_name': reporterName,
    'priority': priority,
    'incident_status': incidentStatus,
    if (assignedTeamId != null) 'assigned_team_id': assignedTeamId,
    if (assignedTeamName != null) 'assigned_team_name': assignedTeamName,
    if (aiSuggestedPriority != null)
      'ai_suggested_priority': aiSuggestedPriority,
    if (aiSuggestedCategory != null)
      'ai_suggested_category': aiSuggestedCategory,
    if (gpsLatitude != null) 'gps_latitude': gpsLatitude,
    if (gpsLongitude != null) 'gps_longitude': gpsLongitude,
    if (gpsAccuracy != null) 'gps_accuracy': gpsAccuracy,
    if (gpsPingedAt != null) 'gps_pinged_at': gpsPingedAt!.toIso8601String(),
    if (userId != null) 'user_id': userId,
  };

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
    id: json['id'] as String?,
    localId: json['local_id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    location: json['location'] as String?,
    reporterName: json['reporter_name'] as String?,
    priority: json['priority'] as String? ?? 'medium',
    incidentStatus: json['incident_status'] as String? ?? 'open',
    assignedTeamId: json['assigned_team_id'] as String?,
    assignedTeamName: json['assigned_team_name'] as String?,
    aiSuggestedPriority: json['ai_suggested_priority'] as String?,
    aiSuggestedCategory: json['ai_suggested_category'] as String?,
    gpsLatitude: (json['gps_latitude'] as num?)?.toDouble(),
    gpsLongitude: (json['gps_longitude'] as num?)?.toDouble(),
    gpsAccuracy: (json['gps_accuracy'] as num?)?.toDouble(),
    gpsPingedAt: json['gps_pinged_at'] != null
        ? DateTime.tryParse(json['gps_pinged_at'] as String)
        : null,
    submittedAt: json['submitted_at'] != null
        ? DateTime.tryParse(json['submitted_at'] as String)
        : null,
    userId: json['user_id'] as String?,
  );
}

/// Model for a GPS ping record.
class GpsPingModel {
  final String? teamMemberId;
  final String? incidentId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? locationLabel;
  final String? userId;

  const GpsPingModel({
    this.teamMemberId,
    this.incidentId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.locationLabel,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    if (teamMemberId != null) 'team_member_id': teamMemberId,
    if (incidentId != null) 'incident_id': incidentId,
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (locationLabel != null) 'location_label': locationLabel,
    if (userId != null) 'user_id': userId,
  };
}

/// Service for syncing incidents and GPS pings to Supabase.
class IncidentService {
  static IncidentService? _instance;
  static IncidentService get instance => _instance ??= IncidentService._();
  IncidentService._();

  static const _pendingKey = 'nirengi_pending_incidents';
  bool _syncInProgress = false;

  SupabaseClient get _client => SupabaseService.instance.client;

  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        syncPendingIncidents();
      }
    });
  }

  // ── Incidents ─────────────────────────────────────────────────────────────

  /// Submit a new incident to Supabase. Returns the created incident's UUID.
  Future<String?> submitIncident(IncidentModel incident) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final payload = incident.toJson();
      if (userId != null) payload['user_id'] = userId;

      final response = await _client
          .from('incidents')
          .insert(payload)
          .select('id')
          .single();

      return response['id'] as String?;
    } on PostgrestException catch (e) {
      // Log but don't crash — local flow continues
      // ignore: avoid_print
      print('[IncidentService] submitIncident error: ${e.message}');
      await _queueLocally(incident);
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[IncidentService] submitIncident unexpected error: $e');
      await _queueLocally(incident);
      return null;
    }
  }

  Future<void> _queueLocally(IncidentModel incident) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    final pending = raw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final payload = incident.toJson();
    if (SupabaseService.isInitialized) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) payload['user_id'] = userId;
    }
    pending.removeWhere((item) => item['local_id'] == incident.localId);
    pending.add(payload);
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  Future<int> syncPendingIncidents() async {
    if (_syncInProgress || !SupabaseService.isInitialized) return 0;
    _syncInProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey);
      if (raw == null) return 0;
      final pending = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final remaining = <Map<String, dynamic>>[];
      var synced = 0;
      for (final payload in pending) {
        try {
          await _client.from('incidents').upsert(
                payload,
                onConflict: 'local_id',
              );
          synced++;
        } catch (_) {
          remaining.add(payload);
        }
      }
      await prefs.setString(_pendingKey, jsonEncode(remaining));
      return synced;
    } finally {
      _syncInProgress = false;
    }
  }

  /// Update GPS coordinates on an existing incident record.
  Future<void> updateIncidentGps({
    required String incidentId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      await _client
          .from('incidents')
          .update({
            'gps_latitude': latitude,
            'gps_longitude': longitude,
            if (accuracy != null) 'gps_accuracy': accuracy,
            'gps_pinged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incidentId);
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[IncidentService] updateIncidentGps error: ${e.message}');
    }
  }

  /// Fetch recent incidents for the current user.
  Future<List<IncidentModel>> fetchMyIncidents({int limit = 20}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('incidents')
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => IncidentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[IncidentService] fetchMyIncidents error: $e');
      return [];
    }
  }

  // ── GPS Pings ─────────────────────────────────────────────────────────────

  /// Record a GPS ping for a team member or incident.
  Future<void> recordGpsPing(GpsPingModel ping) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final payload = ping.toJson();
      if (userId != null) payload['user_id'] = userId;

      await _client.from('gps_pings').insert(payload);
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[IncidentService] recordGpsPing error: ${e.message}');
    }
  }
}
