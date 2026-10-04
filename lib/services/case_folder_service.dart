import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'supabase_service.dart';

class CaseFolderService {
  static CaseFolderService? _instance;
  static CaseFolderService get instance => _instance ??= CaseFolderService._();
  CaseFolderService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> persons(String incidentId) async {
    final rows = await _client.from('case_persons').select().eq('incident_id', incidentId).order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> vehicles(String incidentId) async {
    final rows = await _client.from('case_vehicles').select().eq('incident_id', incidentId).order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> documents(String incidentId) async {
    final rows = await _client.from('case_documents').select().eq('incident_id', incidentId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> media(String incidentId) async {
    final rows = await _client.from('case_media').select().eq('incident_id', incidentId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> history(String incidentId) async {
    final rows = await _client.from('case_activity_log').select().eq('incident_id', incidentId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addPerson({required String incidentId, required String role, required String fullName, String? nationalId, String? phone, String? address, String? notes}) async {
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
  }

  Future<void> addVehicle({required String incidentId, String? plate, String? makeModel, String? color, String? ownerName, String? notes}) async {
    await _client.from('case_vehicles').insert({
      'incident_id': incidentId,
      'plate': plate,
      'make_model': makeModel,
      'color': color,
      'owner_name': ownerName,
      'notes': notes,
      'user_id': _userId,
    });
  }

  Future<Map<String, dynamic>> addDocument({
    required String incidentId,
    required String documentType,
    required String title,
    String? fileName,
    String? filePath,
  }) async {
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
  }

  Future<Map<String, dynamic>> addMedia({
    required String incidentId,
    required String fileName,
    required Uint8List bytes,
    double? latitude,
    double? longitude,
  }) async {
    final userId = _userId;
    if (userId == null) throw StateError('Oturum açılmadan medya eklenemez.');
    final path = '$userId/$incidentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
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
      'created_by': userId,
    }).select().single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> addActivity({required String incidentId, required String action, required String description}) async {
    await _client.from('case_activity_log').insert({
      'incident_id': incidentId,
      'action': action,
      'description': description,
      'actor_id': _userId,
    });
  }
}
