import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/case_folder_service.dart';
import '../../services/incident_service.dart';
import '../../services/note_cache_service.dart';
import '../../services/note_merge_service.dart';
import '../../services/note_storage_service.dart';
import './widgets/note_action_bar_widget.dart';
import './widgets/note_attachments_widget.dart';
import './widgets/note_basic_info_widget.dart';
import './widgets/note_incident_detail_widget.dart';
import './widgets/note_merge_dialog_widget.dart';
import './widgets/note_template_selector_widget.dart';

/// Information Note Screen — Full form for creating official field notes.
/// Grouped glassmorphism form cards with animated floating labels.
class InformationNoteScreen extends StatefulWidget {
  final IncidentModel? incident;

  const InformationNoteScreen({super.key, this.incident});

  @override
  State<InformationNoteScreen> createState() => _InformationNoteScreenState();
}

class _InformationNoteScreenState extends State<InformationNoteScreen> {
  // TODO: Replace with [Riverpod/Bloc] for production
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _selectedTemplateIndex = 0;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  String? _currentLocalId;

  // Form controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _personnelController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _teamController = TextEditingController();
  final TextEditingController _dutyLocationController = TextEditingController();
  final TextEditingController _gpsController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Map<String, TextEditingController> _templateControllers = {};
  String _legalDisposition = 'İfade Sonrası Serbest';
  String _medicalStatus = 'BTM ile Giderilir';

  final List<String> _templates = [
    'Tutanak',
    'Bilgi Notu',
    'Kasten Yaralama Olayı',
    'Uyuşturucu Madde Ele Geçirme',
    'Aranan Şahıs Tespit Tutanağı',
    'Şüpheli Şahıs Kontrolü',
    'Şüpheli Araç Kontrolü',
    'Kimlik Tespit Tutanağı',
    'Üst Arama Tutanağı',
    'İşyeri Denetim Tutanağı',
    'Kayıp Şahıs Müracaatı',
    'Kayıp Eşya Tespit Tutanağı',
    'Buluntu Eşya Teslim Tutanağı',
    'Gürültü İhbarı Tutanağı',
    'Kabahat Tespit Tutanağı',
    'Dilencilik Tespit Tutanağı',
    'Sarhoşluk Tespit Tutanağı',
    'Mala Zarar Verme Olayı',
    'Hırsızlık Olayı',
    'Tehdit Olayı',
    'Hakaret Olayı',
    'Trafik Kazası Tespit Tutanağı',
    'Trafik İdari Yaptırım Tutanağı',
    'Yol Kontrol Uygulaması',
    'Önleyici Kolluk Devriyesi',
    'Şok Uygulaması',
    'Yol Emniyet ve Kontrol Faaliyeti',
    'TEM Faaliyeti',
    'YKN Kontrolü',
    'Görev Teslim Tutanağı',
    'Nöbet Devir Teslimi',
    'İfade Alma Tutanağı',
    'Yakalama Tutanağı',
    'Gözaltı Tutanağı',
    'Adli Arama Tutanağı',
    'Emanet Eşya Teslimi',
    'Fotoğraf Tespit Tutanağı',
    'Kamera Kayıt İnceleme',
    'Olay Yeri Tespit',
    'Hayati Tehlike Tespiti',
    'Ailesine Teslim Tutanağı',
    'Çocuk Yuvasına Teslim',
    'Adliyeye Sevk Tutanağı',
    'Serbest Bırakma Tutanağı',
    'Görev Raporu',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with current date/time and officer info
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    _timeController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _loadOfficerDefaults();
    _prefillFromIncident();
    _loadCaseEntities();
    // Generate a stable local ID for this note session
    _currentLocalId = 'draft_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _prefillFromIncident() {
    final incident = widget.incident;
    if (incident == null) return;
    _subjectController.text = incident.title;
    _descriptionController.text = incident.description;
    _dutyLocationController.text = incident.location ?? '';
    if (incident.gpsLatitude != null && incident.gpsLongitude != null) {
      _gpsController.text =
          '${incident.gpsLatitude!.toStringAsFixed(5)}, ${incident.gpsLongitude!.toStringAsFixed(5)}';
    }
  }

  Future<void> _loadCaseEntities() async {
    final incident = widget.incident;
    if (incident == null) return;
    try {
      final incidentId = incident.id ?? incident.localId;
      final values = await Future.wait([
        CaseFolderService.instance.persons(incidentId),
        CaseFolderService.instance.vehicles(incidentId),
      ]);
      if (!mounted) return;
      final persons = values[0]
          .map((item) => item['full_name']?.toString())
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .join(', ');
      final vehicles = values[1]
          .map((item) => item['plate']?.toString())
          .whereType<String>()
          .where((plate) => plate.trim().isNotEmpty)
          .join(', ');
      final contextLines = <String>[
        if (persons.isNotEmpty) 'Şahıslar: $persons',
        if (vehicles.isNotEmpty) 'Araçlar: $vehicles',
      ];
      if (contextLines.isEmpty) return;
      final field = _controllerForTemplateField(_activeTemplateFields.first);
      if (field.text.trim().isEmpty) field.text = contextLines.join('\n');
    } catch (error) {
      debugPrint('Case entity prefill error: $error');
    }
  }

  Future<void> _loadOfficerDefaults() async {
    try {
      final member = await AuthService.instance.fetchCurrentTeamMember();
      if (!mounted || member == null) return;
      setState(() {
        _personnelController.text = member['name']?.toString() ?? '';
        _badgeController.text = member['badge_number']?.toString() ?? '';
        _teamController.text = member['team_name']?.toString() ?? '';
      });
    } catch (error) {
      debugPrint('Information note profile load error: $error');
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _personnelController.dispose();
    _badgeController.dispose();
    _teamController.dispose();
    _dutyLocationController.dispose();
    _gpsController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    for (final controller in _templateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  static const Map<String, List<String>> _templateFields = {
    'Tutanak': ['Hazır bulunanlar', 'Tespit edilen hususlar'],
    'Bilgi Notu': ['Bilginin kaynağı', 'Değerlendirme'],
    'Mevzuat / Değerlendirme': ['Olayın hukuki niteliği', 'Dayanak / değerlendirme'],
  };

  List<String> get _activeTemplateFields =>
      _templateFields[_templates[_selectedTemplateIndex]] ??
      const ['Hazır bulunanlar', 'Tespit edilen hususlar'];

  TextEditingController _controllerForTemplateField(String field) {
    return _templateControllers.putIfAbsent(
      '${_selectedTemplateIndex}_$field',
      TextEditingController.new,
    );
  }

  Map<String, dynamic> _templateValues() => {
    for (final field in _activeTemplateFields)
      field: _controllerForTemplateField(field).text.trim(),
  };

  Map<String, dynamic> _buildDraftPayload() {
    return {
      'local_id': _currentLocalId,
      'template_index': _selectedTemplateIndex,
      'template_name': _templates[_selectedTemplateIndex],
      'date_text': _dateController.text,
      'time_text': _timeController.text,
      'personnel_name': _personnelController.text,
      'badge_number': _badgeController.text,
      'team_name': _teamController.text,
      'duty_location': _dutyLocationController.text,
      'gps_coordinates': _gpsController.text,
      'subject': _subjectController.text,
      'description': _descriptionController.text,
      'legal_disposition': _legalDisposition,
      'medical_status': _medicalStatus,
      'template_data': _templateValues(),
      'status': 'draft',
      'is_synced': false,
      if (AuthService.instance.currentUserId != null)
        'user_id': AuthService.instance.currentUserId,
    };
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    try {
      final draft = _buildDraftPayload();

      // 1. Save locally first (always succeeds)
      await NoteCacheService.instance.saveDraftLocally(draft);

      // 2. Try to sync to Supabase immediately if online
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.any((r) => r != ConnectivityResult.none);
      String message = 'Taslak kaydedildi';

      if (isOnline) {
        try {
          // ── Conflict detection ──────────────────────────────────────
          final conflict = await NoteMergeService.instance.detectConflict(
            draft,
          );

          if (conflict != null && conflict.hasConflict && mounted) {
            // Pause sync — show merge dialog
            final result = await NoteMergeDialog.show(context, conflict);

            if (result == null) {
              message = 'Taslak kaydedildi (senkronizasyon iptal edildi)';
            } else if (result.choice == MergeChoice.keepLocal) {
              await NoteStorageService.instance.upsertDraft(draft);
              message = 'Yerel sürüm buluta kaydedildi';
            } else if (result.choice == MergeChoice.useCloud) {
              final cloudDraft = conflict.cloudDraft;
              await NoteCacheService.instance.saveDraftLocally(cloudDraft);
              _applyDraftToForm(cloudDraft);
              message = 'Bulut sürümü uygulandı';
            } else if (result.choice == MergeChoice.manualMerge &&
                result.mergedValues != null) {
              final merged = NoteMergeService.instance.buildMergedDraft(
                draft,
                result.mergedValues!,
              );
              await NoteCacheService.instance.saveDraftLocally(merged);
              await NoteStorageService.instance.upsertDraft(merged);
              _applyDraftToForm(merged);
              message = 'Birleştirilmiş sürüm kaydedildi';
            }
          } else {
            await NoteStorageService.instance.upsertDraft(draft);
            message = 'Taslak kaydedildi ve senkronize edildi';
          }
        } catch (_) {
          message = 'Taslak kaydedildi (çevrimdışı — sync bekliyor)';
        }
      } else {
        message = 'Taslak kaydedildi (çevrimdışı — sync bekliyor)';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save draft error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Taslak kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Applies a draft map back to the form controllers (used after cloud/merge resolution).
  void _applyDraftToForm(Map<String, dynamic> draft) {
    setState(() {
      _selectedTemplateIndex =
          (draft['template_index'] as int?) ?? _selectedTemplateIndex;
      _dateController.text = draft['date_text']?.toString() ?? '';
      _timeController.text = draft['time_text']?.toString() ?? '';
      _personnelController.text = draft['personnel_name']?.toString() ?? '';
      _badgeController.text = draft['badge_number']?.toString() ?? '';
      _teamController.text = draft['team_name']?.toString() ?? '';
      _dutyLocationController.text = draft['duty_location']?.toString() ?? '';
      _gpsController.text = draft['gps_coordinates']?.toString() ?? '';
      _subjectController.text = draft['subject']?.toString() ?? '';
      _descriptionController.text = draft['description']?.toString() ?? '';
      _legalDisposition = draft['legal_disposition']?.toString() ?? _legalDisposition;
      _medicalStatus = draft['medical_status']?.toString() ?? _medicalStatus;
      final templateData = draft['template_data'];
      if (templateData is Map) {
        for (final entry in templateData.entries) {
          _controllerForTemplateField(entry.key.toString()).text =
              entry.value?.toString() ?? '';
        }
      }
    });
  }

  Future<void> _generatePdf() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Guard against double-tap
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final localId = _currentLocalId!;
      final now = DateTime.now();

      // 1. Save as submitted note locally
      final submittedNote = {
        'local_id': 'submitted_$localId',
        'template_index': _selectedTemplateIndex,
        'template_name': _templates[_selectedTemplateIndex],
        'date_text': _dateController.text,
        'time_text': _timeController.text,
        'personnel_name': _personnelController.text,
        'badge_number': _badgeController.text,
        'team_name': _teamController.text,
        'duty_location': _dutyLocationController.text,
        'gps_coordinates': _gpsController.text,
        'subject': _subjectController.text,
        'description': _descriptionController.text,
        'legal_disposition': _legalDisposition,
        'medical_status': _medicalStatus,
        'template_data': _templateValues(),
        'submitted_at': now.toIso8601String(),
        if (AuthService.instance.currentUserId != null)
          'user_id': AuthService.instance.currentUserId,
      };
      await NoteCacheService.instance.saveSubmittedNoteLocally(submittedNote);

      // 2. Generate a Turkish-character-safe, official-looking document.
      final safeFileName = _subjectController.text
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final regular = pw.Font.ttf(
        (await rootBundle.load('assets/fonts/NotoSans-Regular.ttf')),
      );
      final bold = pw.Font.ttf(
        (await rootBundle.load('assets/fonts/NotoSans-Bold.ttf')),
      );
      final documentType = _templates[_selectedTemplateIndex];
      final isTutanak = documentType == 'Tutanak';
      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
      final templateValues = _templateValues();
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.fromLTRB(54, 46, 54, 48),
          header: (context) => pw.Column(children: [
            pw.Text('T.C.', style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.Text('İÇİŞLERİ BAKANLIĞI', style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.Text('EMNİYET GENEL MÜDÜRLÜĞÜ', style: pw.TextStyle(font: bold, fontSize: 10)),
            pw.SizedBox(height: 18),
            pw.Center(child: pw.Text(isTutanak ? 'TUTANAK' : documentType.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 16))),
            pw.SizedBox(height: 14),
          ]),
          footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Sayfa ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(font: regular, fontSize: 8))),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(width: .5),
              columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(3)},
              children: [
                _pdfRow('Tarih / Saat', '${_dateController.text} - ${_timeController.text}', regular, bold),
                _pdfRow('Yer / Görev', _dutyLocationController.text, regular, bold),
                _pdfRow('Konu', _subjectController.text, regular, bold),
                _pdfRow('Hazırlayan', '${_personnelController.text} - Sicil: ${_badgeController.text}', regular, bold),
                _pdfRow('Birim / Ekip', _teamController.text, regular, bold),
                _pdfRow('Adli durum', _legalDisposition, regular, bold),
                _pdfRow('Adli muayene / rapor', _medicalStatus, regular, bold),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Text(isTutanak ? 'OLAYIN TESPİTİ VE AÇIKLAMASI' : 'BİLGİ NOTU', style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.SizedBox(height: 8),
            pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(width: .5)), child: pw.Text(_descriptionController.text.trim(), style: pw.TextStyle(font: regular, fontSize: 10, lineSpacing: 4))),
            if (templateValues.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text('EK BİLGİLER', style: pw.TextStyle(font: bold, fontSize: 11)),
              pw.SizedBox(height: 6),
              pw.Table(border: pw.TableBorder.all(width: .5), children: templateValues.entries.map((entry) => _pdfRow(entry.key, entry.value.toString(), regular, bold)).toList()),
            ],
            pw.SizedBox(height: 26),
            pw.Text(isTutanak ? 'İşbu tutanak tarafımızca birlikte tanzim edilerek imza altına alınmıştır.' : 'Arz ederim.', style: pw.TextStyle(font: regular, fontSize: 10)),
            pw.SizedBox(height: 42),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(children: [pw.Text(_personnelController.text, style: pw.TextStyle(font: bold, fontSize: 10)), pw.Text(_teamController.text, style: pw.TextStyle(font: regular, fontSize: 10)), pw.SizedBox(height: 28), pw.Text('İMZA', style: pw.TextStyle(font: bold, fontSize: 9))])),
          ],
        ),
      );
      final Uint8List pdfBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${isTutanak ? 'tutanak' : 'bilgi_notu'}_${safeFileName.isEmpty ? 'kayit' : safeFileName}_${now.millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes, flush: true);

      final pdfRecord = {
        'local_id': 'pdf_$localId',
        'file_name': fileName,
        'file_path': file.path,
        'file_size_bytes': pdfBytes.length,
        'pdf_status': 'generated',
        'generated_at': now.toIso8601String(),
        if (AuthService.instance.currentUserId != null)
          'user_id': AuthService.instance.currentUserId,
      };
      await NoteCacheService.instance.savePdfRecordLocally(pdfRecord);

      if (widget.incident != null) {
        try {
          await CaseFolderService.instance.addDocument(
            incidentId: widget.incident!.id ?? widget.incident!.localId,
            documentType: documentType,
            title: _subjectController.text.trim().isEmpty
                ? documentType
                : _subjectController.text.trim(),
            fileName: fileName,
            filePath: file.path,
          );
          await CaseFolderService.instance.addActivity(
            incidentId: widget.incident!.id ?? widget.incident!.localId,
            action: 'Evrak Eklendi',
            description: fileName,
          );
        } catch (error) {
          debugPrint('Case document link error: $error');
        }
      }

      // 3. Try to sync both to Supabase if online
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        try {
          final savedNote = await NoteStorageService.instance
              .upsertSubmittedNote(submittedNote);
          final pdfPayload = Map<String, dynamic>.from(pdfRecord);
          if (savedNote != null && savedNote['id'] != null) {
            pdfPayload['submitted_note_id'] = savedNote['id'];
          }
          await NoteStorageService.instance.upsertPdfRecord(pdfPayload);
          await NoteStorageService.instance.markDraftSubmitted(localId);
        } catch (_) {
          // Will sync on next connectivity event
        }
      }

      // 4. Mark draft as submitted locally
      final drafts = await NoteCacheService.instance.getLocalDrafts();
      final draftIdx = drafts.indexWhere((d) => d['local_id'] == localId);
      if (draftIdx >= 0) {
        drafts[draftIdx]['status'] = 'submitted';
        await NoteCacheService.instance.saveDraftLocally(drafts[draftIdx]);
      }

      if (mounted) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF oluşturuldu — Paylaş veya Yazdır'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Generate PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF oluşturulamadı. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.TableRow _pdfRow(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 9)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Text(value.trim().isEmpty ? 'Belirtilmedi' : value, style: pw.TextStyle(font: regular, fontSize: 9)),
      ),
    ]);
  }

  Widget _buildTemplateFieldsSection(ThemeData theme) {
    final fields = _activeTemplateFields;
    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'dynamic_form',
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_templates[_selectedTemplateIndex]} Bilgileri',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _controllerForTemplateField(field),
                style: const TextStyle(color: Colors.white),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '$field gerekli'
                    : null,
                decoration: InputDecoration(
                  labelText: field,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                ),
              ),
            ),
          ),
          const Divider(height: 24),
          Text(
            'Dinamik değişken ekle',
            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _variableChip('+ Metin', '[Metin]', theme),
              _variableChip('+ Tarih', '[Tarih]', theme),
              _variableChip('+ Saat', '[Saat]', theme),
              _variableChip('+ Seçenek', '[Seçenek]', theme),
              _variableChip('+ Yaş/Cins.', '[Yaş/Cins]', theme),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _legalDisposition,
            decoration: const InputDecoration(labelText: 'Şahıs adli durumu'),
            items: const [
              'İfade Sonrası Serbest',
              'Ailesine Teslim (18 Yaş Altı)',
              'Çocuk Yuvasına Teslim (18 Yaş Altı)',
              'Adliyeye Sevk / Gözaltı',
              'Diğer / Manuel Olarak Yazacağım',
            ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => setState(() => _legalDisposition = value ?? _legalDisposition),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _medicalStatus,
            decoration: const InputDecoration(labelText: 'Adli muayene / rapor durumu'),
            items: const [
              'BTM ile Giderilir',
              'BTM ile Giderilemez',
              'Hayati Tehlike VAR',
            ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => setState(() => _medicalStatus = value ?? _medicalStatus),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Nasıl Kullanılır?'),
                  content: const Text('Şablonu seçin, değişken butonlarıyla metin alanına işaretler ekleyin. Tarih, saat, seçenek ve yaş/cinsiyet bilgilerini belgeyi hazırlarken doldurun. Tüm şablonlar ücretsiz ve sınırsız yerel olarak kullanılabilir.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anladım'))],
                ),
              ),
              icon: const Icon(Icons.help_outline, size: 17),
              label: const Text('Nasıl Kullanılır?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variableChip(String label, String token, ThemeData theme) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final current = _descriptionController.text;
        final separator = current.isEmpty || current.endsWith(' ') ? '' : ' ';
        _descriptionController.text = '$current$separator$token ';
        _descriptionController.selection = TextSelection.collapsed(
          offset: _descriptionController.text.length,
        );
      },
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      // resizeToAvoidBottomInset ensures keyboard doesn't cover form fields
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // ── Template selector ────────────────────────────────────
                SliverToBoxAdapter(
                  child: NoteTemplateSelectorWidget(
                    templates: _templates,
                    selectedIndex: _selectedTemplateIndex,
                    onSelected: (i) {
                      if (mounted) setState(() => _selectedTemplateIndex = i);
                    },
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: _buildTemplateFieldsSection(theme),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Basic info group ──────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: NoteBasicInfoWidget(
                      isTablet: isTablet,
                      dateController: _dateController,
                      timeController: _timeController,
                      personnelController: _personnelController,
                      badgeController: _badgeController,
                      teamController: _teamController,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Duty info group ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: NoteDutyInfoWidget(
                      isTablet: isTablet,
                      dutyLocationController: _dutyLocationController,
                      gpsController: _gpsController,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Incident detail group ─────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: NoteIncidentDetailWidget(
                      subjectController: _subjectController,
                      descriptionController: _descriptionController,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Attachments group ─────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: NoteAttachmentsWidget(
                      onCameraTap: () {},
                      onFileTap: () {},
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Action bar ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: NoteActionBarWidget(
                      isSaving: _isSaving,
                      isGeneratingPdf: _isGeneratingPdf,
                      onSaveDraft: _saveDraft,
                      onGeneratePdf: _generatePdf,
                    ),
                  ),
                ),

                // ── Bottom padding (accounts for keyboard + nav bar) ──────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 120,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: AppTheme.surfaceDark.withAlpha(204),
      elevation: 0,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: 'arrow_back_ios_new',
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          FocusScope.of(context).unfocus();
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.homeScreen);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bilgi Notu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            _templates[_selectedTemplateIndex],
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'smart_toy',
            color: AppTheme.secondary,
            size: 22,
          ),
          onPressed: () {},
          tooltip: 'Yapay Zeka Asistanı',
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: Colors.white,
            size: 22,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
