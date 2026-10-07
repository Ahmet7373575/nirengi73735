import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_case_storage.dart';
import 'supabase_service.dart';

/// Case-folder entity service.
///
/// Related records are always written to the device first. Supabase is used
/// when an authenticated session is available, but it is never required for
/// creating or reviewing a field case.
class CaseFolderService {
  static CaseFolderService? _instance;
  static CaseFolderService get instance => _instance ??= CaseFolderService._();
  CaseFolderService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  String? get _userId => _client.auth.currentUser?.id;
  bool get _cloudReady =>
      SupabaseService.isInitialized && _client.auth.currentUser != null;

  Future<List<Map<String, dynamic>>> _read(
    String incidentId,
    String collection,
    Future<List<Map<String, dynamic>>> Function() cloudReader,
  ) async {
    final local = await LocalCaseStorage.list(incidentId, collection);
    if (!_cloudReady) return local;
    try {
      final cloud = await cloudReader();
      return _merge(cloud, local);
    } catch (_) {
      return local;
    }
  }

  List<Map<String, dynamic>> _merge(
    List<Map<String, dynamic>> cloud,
    List<Map<String, dynamic>> local,
  ) {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final row in [...cloud, ...local]) {
      final key = row['id']?.toString() ??
          row['local_id']?.toString() ??
          '${row['title'] ?? row['full_name'] ?? row['plate'] ?? row['file_name']}|${row['created_at'] ?? ''}';
      if (seen.add(key)) result.add(row);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> persons(String incidentId) => _read(
        incidentId,
        'persons',
        () async => List<Map<String, dynamic>>.from(
          await _client
              .from('case_persons')
              .select()
              .eq('incident_id', incidentId)
              .order('created_at'),
        ),
      );

  Future<List<Map<String, dynamic>>> vehicles(String incidentId) => _read(
        incidentId,
        'vehicles',
        () async => List<Map<String, dynamic>>.from(
          await _client
              .from('case_vehicles')
              .select()
              .eq('incident_id', incidentId)
              .order('created_at'),
        ),
      );

  Future<List<Map<String, dynamic>>> documents(String incidentId) => _read(
        incidentId,
        'documents',
        () async => List<Map<String, dynamic>>.from(
          await _client
              .from('case_documents')
              .select()
              .eq('incident_id', incidentId)
              .order('created_at', ascending: false),
        ),
      );

  Future<List<Map<String, dynamic>>> media(String incidentId) => _read(
        incidentId,
        'media',
        () async => List<Map<String, dynamic>>.from(
          await _client
              .from('case_media')
              .select()
              .eq('incident_id', incidentId)
              .order('created_at', ascending: false),
        ),
      );

  Future<List<Map<String, dynamic>>> history(String incidentId) => _read(
        incidentId,
        'history',
        () async => List<Map<String, dynamic>>.from(
          await _client
              .from('case_activity_log')
              .select()
              .eq('incident_id', incidentId)
              .order('created_at', ascending: false),
        ),
      );

  Future<void> addPerson({
    required String incidentId,
    required String role,
    required String fullName,
    String? nationalId,
    String? phone,
    String? address,
    String? notes,
  }) async {
    await LocalCaseStorage.add(incidentId, 'persons', {
      'role': role,
      'full_name': fullName,
      'national_id': nationalId,
      'phone': phone,
      'address': address,
      'notes': notes,
    });
    if (!_cloudReady) return;
    try {
      await _client.from('case_persons').insert({
        'incident_id': incidentId,
        'role': role,
        'full_name': fullName,
        'national_id': nationalId,
        'phone': phone,
        'address': address,
        'notes': notes,
        'user_id': _userId,
      });
    } catch (_) {
      // The local record remains available and will be retried by sync later.
    }
  }

  Future<void> addVehicle({
    required String incidentId,
    String? plate,
    String? makeModel,
    String? color,
    String? ownerName,
    String? notes,
  }) async {
    await LocalCaseStorage.add(incidentId, 'vehicles', {
      'plate': plate,
      'make_model': makeModel,
      'color': color,
      'owner_name': ownerName,
      'notes': notes,
    });
    if (!_cloudReady) return;
    try {
      await _client.from('case_vehicles').insert({
        'incident_id': incidentId,
        'plate': plate,
        'make_model': makeModel,
        'color': color,
        'owner_name': ownerName,
        'notes': notes,
        'user_id': _userId,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> addDocument({
    required String incidentId,
    required String documentType,
    required String title,
    String? fileName,
    String? filePath,
  }) async {
    final local = await LocalCaseStorage.add(incidentId, 'documents', {
      'document_type': documentType,
      'title': title,
      'file_name': fileName,
      'file_path': filePath,
      'status': 'draft',
    });
    if (!_cloudReady) return local;
    try {
      final row = await _client.from('case_documents').insert({
        'incident_id': incidentId,
        'document_type': documentType,
        'title': title,
        'file_name': fileName,
        'file_path': filePath,
        'status': 'draft',
        'created_by': _userId,
      }).select().single();
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return local;
    }
  }

  Future<Map<String, dynamic>> addMedia({
    required String incidentId,
    required String fileName,
    required Uint8List bytes,
    String? sourcePath,
    double? latitude,
    double? longitude,
  }) async {
    Map<String, dynamic>? local;
    local = await LocalCaseStorage.add(incidentId, 'media', {
      'media_type': 'photo',
      'file_name': fileName,
      'file_path': sourcePath ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': DateTime.now().toIso8601String(),
    });
    if (!_cloudReady || _userId == null) return local;
    try {
      final path = '${_userId!}/$incidentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _client.storage.from('case-media').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: false, contentType: 'image/jpeg'),
      );
      final publicUrl = _client.storage.from('case-media').getPublicUrl(path);
      final row = await _client.from('case_media').insert({
        'incident_id': incidentId,
        'media_type': 'photo',
        'file_name': fileName,
        'file_path': publicUrl,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': DateTime.now().toIso8601String(),
        'created_by': _userId,
      }).select().single();
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return local;
    }
  }

  Future<void> addActivity({
    required String incidentId,
    required String action,
    required String description,
  }) async {
    await LocalCaseStorage.add(incidentId, 'history', {
      'action': action,
      'description': description,
      'actor_id': _userId,
    });
    if (!_cloudReady) return;
    try {
      await _client.from('case_activity_log').insert({
        'incident_id': incidentId,
        'action': action,
        'description': description,
        'actor_id': _userId,
      });
    } catch (_) {}
  }
}
