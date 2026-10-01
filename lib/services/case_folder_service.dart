import 'package:supabase_flutter/supabase_flutter.dart';
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
}
