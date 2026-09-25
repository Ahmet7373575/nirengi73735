import './note_storage_service.dart';

/// Represents a detected conflict between a local draft and its cloud version.
class DraftConflict {
  final Map<String, dynamic> localDraft;
  final Map<String, dynamic> cloudDraft;

  /// Field-level diff: key → {local: value, cloud: value}
  final Map<String, Map<String, dynamic>> diffFields;

  const DraftConflict({
    required this.localDraft,
    required this.cloudDraft,
    required this.diffFields,
  });

  bool get hasConflict => diffFields.isNotEmpty;
}

/// Detects conflicts between a locally-edited draft and the Supabase version.
class NoteMergeService {
  static NoteMergeService? _instance;
  static NoteMergeService get instance => _instance ??= NoteMergeService._();
  NoteMergeService._();

  /// Fields that are compared for conflict detection (user-editable content).
  static const List<String> _comparableFields = [
    'template_index',
    'template_name',
    'date_text',
    'time_text',
    'personnel_name',
    'badge_number',
    'team_name',
    'duty_location',
    'gps_coordinates',
    'subject',
    'description',
  ];

  /// Human-readable Turkish labels for each field.
  static const Map<String, String> fieldLabels = {
    'template_index': 'Şablon',
    'template_name': 'Şablon Adı',
    'date_text': 'Tarih',
    'time_text': 'Saat',
    'personnel_name': 'Personel',
    'badge_number': 'Sicil No',
    'team_name': 'Ekip',
    'duty_location': 'Görev Yeri',
    'gps_coordinates': 'GPS',
    'subject': 'Konu',
    'description': 'Açıklama',
  };

  /// Fetches the cloud version of a draft and compares it with [localDraft].
  /// Returns a [DraftConflict] — check [DraftConflict.hasConflict] to decide
  /// whether to show the merge dialog.
  Future<DraftConflict?> detectConflict(Map<String, dynamic> localDraft) async {
    final localId = localDraft['local_id'] as String?;
    if (localId == null) return null;

    try {
      final cloudDrafts = await NoteStorageService.instance.fetchDraftByLocalId(
        localId,
      );
      if (cloudDrafts == null) {
        return null; // No cloud version yet — no conflict
      }

      final diff = <String, Map<String, dynamic>>{};
      for (final field in _comparableFields) {
        final localVal = localDraft[field]?.toString() ?? '';
        final cloudVal = cloudDrafts[field]?.toString() ?? '';
        if (localVal != cloudVal) {
          diff[field] = {'local': localVal, 'cloud': cloudVal};
        }
      }

      return DraftConflict(
        localDraft: localDraft,
        cloudDraft: cloudDrafts,
        diffFields: diff,
      );
    } catch (_) {
      return null; // Network error — skip conflict check
    }
  }

  /// Builds a manually-merged draft by applying [mergedValues] on top of [base].
  Map<String, dynamic> buildMergedDraft(
    Map<String, dynamic> base,
    Map<String, String> mergedValues,
  ) {
    final result = Map<String, dynamic>.from(base);
    mergedValues.forEach((key, value) {
      result[key] = value;
    });
    result['is_synced'] = false;
    result['updated_at'] = DateTime.now().toIso8601String();
    return result;
  }
}
