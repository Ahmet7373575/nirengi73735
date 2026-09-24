import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import '../../providers/chat_notifier.dart';
import '../../services/incident_service.dart';
import '../../services/notification_service.dart';

/// Priority level enum for incidents.
enum IncidentPriority { low, medium, high, critical }

/// Incident status for real-time tracking.
enum IncidentStatus { open, inProgress, resolved, closed }

/// Team model.
class IncidentTeam {
  final String id;
  final String name;
  final String icon;
  final Color color;

  const IncidentTeam({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Rapid Incident Creation Screen — fast incident logging with team assignment,
/// priority level, and real-time status tracking. Integrates with PDF export.
class RapidIncidentScreen extends ConsumerStatefulWidget {
  const RapidIncidentScreen({super.key});

  @override
  ConsumerState<RapidIncidentScreen> createState() =>
      _RapidIncidentScreenState();
}

class _RapidIncidentScreenState extends ConsumerState<RapidIncidentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reporterController = TextEditingController();

  IncidentPriority _priority = IncidentPriority.medium;
  IncidentStatus _status = IncidentStatus.open;
  IncidentTeam? _selectedTeam;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _incidentId;
  DateTime? _submittedAt;

  // AI suggestion state
  IncidentPriority? _aiSuggestedPriority;
  String? _aiSuggestedCategory;
  String? _aiReasoning;
  bool _aiSuggestionApplied = false;
  Timer? _aiDebounceTimer;

  // Real-time tracking simulation
  Timer? _trackingTimer;
  int _trackingStep = 0;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _successScale;

  static const _aiConfig = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-3.7-flash',
    streaming: false,
  );

  static const List<IncidentTeam> _teams = [
    IncidentTeam(
      id: 't1',
      name: 'Asayiş Timi',
      icon: 'local_police',
      color: Color(0xFF3B82F6),
    ),
    IncidentTeam(
      id: 't2',
      name: 'Trafik Timi',
      icon: 'traffic',
      color: Color(0xFF10B981),
    ),
    IncidentTeam(
      id: 't3',
      name: 'Narkotik Timi',
      icon: 'medication',
      color: Color(0xFF8B5CF6),
    ),
    IncidentTeam(
      id: 't4',
      name: 'Çevik Kuvvet',
      icon: 'shield',
      color: Color(0xFFEF4444),
    ),
    IncidentTeam(
      id: 't5',
      name: 'Kriminal Timi',
      icon: 'fingerprint',
      color: Color(0xFFF59E0B),
    ),
    IncidentTeam(
      id: 't6',
      name: 'Siber Suç Timi',
      icon: 'computer',
      color: Color(0xFF06B6D4),
    ),
  ];

  static const List<String> _trackingMessages = [
    'Olay kaydedildi',
    'Ekip bildirildi',
    'Saha koordinasyonu başlatıldı',
    'Olay aktif takipte',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _reporterController.dispose();
    _trackingTimer?.cancel();
    _aiDebounceTimer?.cancel();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    final text = _descriptionController.text.trim();
    if (text.length < 20) {
      if (_aiSuggestedPriority != null || _aiSuggestedCategory != null) {
        setState(() {
          _aiSuggestedPriority = null;
          _aiSuggestedCategory = null;
          _aiReasoning = null;
          _aiSuggestionApplied = false;
        });
      }
      return;
    }

    _aiDebounceTimer?.cancel();
    _aiDebounceTimer = Timer(const Duration(milliseconds: 1200), () {
      _requestAiSuggestion(text);
    });
  }

  void _requestAiSuggestion(String description) {
    final title = _titleController.text.trim();
    final prompt =
        '''
Sen bir polis olay analiz asistanısın. Aşağıdaki olay açıklamasını analiz et ve JSON formatında yanıt ver.

Olay Başlığı: ${title.isNotEmpty ? title : '(belirtilmedi)'}
Olay Açıklaması: $description

Şu bilgileri JSON olarak döndür:
{
  "priority": "low" | "medium" | "high" | "critical",
  "category": "<kısa kategori adı, örn: Trafik Kazası, Hırsızlık, Uyuşturucu, Kavga, Siber Suç, Kamu Düzeni, Diğer>",
  "reasoning": "<öncelik ve kategori seçiminin kısa Türkçe gerekçesi, max 2 cümle>"
}

Öncelik kriterleri:
- critical: Can kaybı riski, silah, toplu olay, terör
- high: Yaralanma, aktif suç, acil müdahale gerekli
- medium: Aktif olmayan suç, mülk hasarı, orta risk
- low: Bilgi amaçlı, düşük risk, geçmiş olay

Sadece JSON döndür, başka açıklama ekleme.
''';

    ref
        .read(chatNotifierProvider(_aiConfig).notifier)
        .sendMessage(
          [
            {
              'role': 'system',
              'content':
                  'Sen bir polis olay analiz asistanısın. Sadece geçerli JSON döndür.',
            },
            {'role': 'user', 'content': prompt},
          ],
          parameters: {'temperature': 0.2, 'max_tokens': 300},
        );
  }

  void _applyAiSuggestion() {
    if (_aiSuggestedPriority != null) {
      setState(() {
        _priority = _aiSuggestedPriority!;
        _aiSuggestionApplied = true;
      });
    }
  }

  void _dismissAiSuggestion() {
    setState(() {
      _aiSuggestedPriority = null;
      _aiSuggestedCategory = null;
      _aiReasoning = null;
      _aiSuggestionApplied = false;
    });
  }

  IncidentPriority? _parsePriority(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'low':
        return IncidentPriority.low;
      case 'medium':
        return IncidentPriority.medium;
      case 'high':
        return IncidentPriority.high;
      case 'critical':
        return IncidentPriority.critical;
      default:
        return null;
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeam == null) {
      _showSnack('Lütfen bir ekip seçin', isError: true);
      return;
    }

    // Guard against double-tap / duplicate submission
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Build the local incident ID
      final localId =
          'OLY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Sync to Supabase backend
      final incident = IncidentModel(
        localId: localId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        reporterName: _reporterController.text.trim().isEmpty
            ? null
            : _reporterController.text.trim(),
        priority: _priority.name,
        incidentStatus: _status.name == 'inProgress'
            ? 'in_progress'
            : _status.name,
        assignedTeamId: _selectedTeam?.id,
        assignedTeamName: _selectedTeam?.name,
        aiSuggestedPriority: _aiSuggestedPriority?.name,
        aiSuggestedCategory: _aiSuggestedCategory,
      );

      final supabaseId = await IncidentService.instance.submitIncident(
        incident,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
        _incidentId = supabaseId ?? localId;
        _submittedAt = DateTime.now();
        _trackingStep = 0;
      });

      _successController.forward();
      _startTracking();

      // Fire a critical-priority native notification when the incident is critical
      if (_priority == IncidentPriority.critical) {
        NotificationService.instance.showCriticalIncidentAlert(
          incidentTitle: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedTeam: _selectedTeam?.name,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack('Olay kaydedilemedi. Lütfen tekrar deneyin.', isError: true);
      debugPrint('Submit incident error: $e');
    }
  }

  void _startTracking() {
    _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_trackingStep < _trackingMessages.length - 1) {
        setState(() => _trackingStep++);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('NİRENGİ - HIZLI OLAY RAPORU',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 14),
              pw.Text('Olay ID: ${_incidentId ?? '-'}'),
              pw.Text('Başlık: ${_titleController.text}'),
              pw.Text('Yer: ${_locationController.text}'),
              pw.Text('Öncelik: ${_priority.name}'),
              pw.Text('Ekip: ${_selectedTeam?.name ?? '-'}'),
              pw.Text('Durum: ${_status.name}'),
              pw.SizedBox(height: 12),
              pw.Text(_descriptionController.text),
            ],
          ),
        ),
      ),
    );
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'olay_${_incidentId ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    await File('${directory.path}/$fileName').writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    await Printing.sharePdf(bytes: bytes, filename: fileName);
    _showSnack('PDF hazırlandı — Paylaş veya Yazdır');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _isSubmitted = false;
      _incidentId = null;
      _submittedAt = null;
      _trackingStep = 0;
      _priority = IncidentPriority.medium;
      _status = IncidentStatus.open;
      _selectedTeam = null;
      _aiSuggestedPriority = null;
      _aiSuggestedCategory = null;
      _aiReasoning = null;
      _aiSuggestionApplied = false;
      _titleController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _reporterController.clear();
    });
    _successController.reset();
    _trackingTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen for AI response
    ref.listen<ChatState>(chatNotifierProvider(_aiConfig), (previous, next) {
      if (!mounted) return;
      if (next.error != null && previous?.error != next.error) {
        // Show user-friendly Turkish message instead of raw error
        Fluttertoast.showToast(
          msg: 'AI analiz tamamlanamadı. Lütfen tekrar deneyin.',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_SHORT,
        );
        return;
      }
      if (!next.isLoading && next.response.isNotEmpty && next.error == null) {
        _parseAiResponse(next.response);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      // Keyboard resize for form fields
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ─────────────────────────────────────────────────
              _buildAppBar(theme),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: _isSubmitted
                    ? _buildTrackingView(theme)
                    : _buildFormView(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _parseAiResponse(String response) {
    try {
      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = response.trim();
      if (jsonStr.contains('```')) {
        final start = jsonStr.indexOf('{');
        final end = jsonStr.lastIndexOf('}');
        if (start != -1 && end != -1) {
          jsonStr = jsonStr.substring(start, end + 1);
        }
      }

      // Simple manual JSON parsing to avoid dart:convert dependency issues
      final priorityMatch = RegExp(
        r'"priority"\s*:\s*"(\w+)"',
      ).firstMatch(jsonStr);
      final categoryMatch = RegExp(
        r'"category"\s*:\s*"([^"]+)"',
      ).firstMatch(jsonStr);
      final reasoningMatch = RegExp(
        r'"reasoning"\s*:\s*"([^"]+)"',
      ).firstMatch(jsonStr);

      final priority = _parsePriority(priorityMatch?.group(1));
      final category = categoryMatch?.group(1);
      final reasoning = reasoningMatch?.group(1);

      if (priority != null && category != null) {
        setState(() {
          _aiSuggestedPriority = priority;
          _aiSuggestedCategory = category;
          _aiReasoning = reasoning;
          _aiSuggestionApplied = false;
        });
      }
    } catch (_) {
      // Silently ignore parse errors
    }
  }

  Widget _buildAppBar(ThemeData theme) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            border: Border(
              bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.glassBorder, width: 1),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı Olay Kaydı',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Anlık olay oluştur ve ekip ata',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Priority indicator
              _PriorityBadge(priority: _priority),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeData theme) {
    final aiState = ref.watch(chatNotifierProvider(_aiConfig));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Priority selector ──────────────────────────────────────
            _SectionLabel(label: 'Öncelik Seviyesi', icon: 'priority_high'),
            const SizedBox(height: 10),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),

            const SizedBox(height: 20),

            // ── Incident title ─────────────────────────────────────────
            _SectionLabel(label: 'Olay Başlığı', icon: 'title'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Olayı kısaca tanımlayın...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Başlık zorunludur' : null,
              maxLines: 1,
            ),

            const SizedBox(height: 16),

            // ── Location ───────────────────────────────────────────────
            _SectionLabel(label: 'Konum', icon: 'location_on'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _locationController,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Adres veya koordinat girin...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Konum zorunludur' : null,
            ),

            const SizedBox(height: 16),

            // ── Reporter ───────────────────────────────────────────────
            _SectionLabel(label: 'Bildiren Memur', icon: 'badge'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _reporterController,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Memur adı ve sicil numarası...',
              ),
            ),

            const SizedBox(height: 16),

            // ── Description ────────────────────────────────────────────
            _SectionLabel(label: 'Olay Açıklaması', icon: 'description'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Detaylı olay açıklaması...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Açıklama zorunludur'
                  : null,
            ),

            const SizedBox(height: 12),

            // ── AI Suggestion Panel ────────────────────────────────────
            _AiSuggestionPanel(
              isLoading: aiState.isLoading,
              suggestedPriority: _aiSuggestedPriority,
              suggestedCategory: _aiSuggestedCategory,
              reasoning: _aiReasoning,
              applied: _aiSuggestionApplied,
              onApply: _applyAiSuggestion,
              onDismiss: _dismissAiSuggestion,
            ),

            const SizedBox(height: 20),

            // ── Team assignment ────────────────────────────────────────
            _SectionLabel(label: 'Ekip Ataması', icon: 'groups'),
            const SizedBox(height: 10),
            _TeamGrid(
              teams: _teams,
              selected: _selectedTeam,
              onSelected: (t) => setState(() => _selectedTeam = t),
            ),

            const SizedBox(height: 20),

            // ── Status ─────────────────────────────────────────────────
            _SectionLabel(label: 'Başlangıç Durumu', icon: 'flag'),
            const SizedBox(height: 10),
            _StatusSelector(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
            ),

            const SizedBox(height: 28),

            // ── Submit button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _priorityColor(_priority),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'send',
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Olayı Kaydet ve Ekibi Bildir',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // ── Success animation ──────────────────────────────────────
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(38),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.success.withAlpha(102),
                  width: 2,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.success,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Olay Kaydedildi',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _incidentId ?? '',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 24),

          // ── Incident summary card ──────────────────────────────────
          _IncidentSummaryCard(
            title: _titleController.text,
            location: _locationController.text,
            priority: _priority,
            team: _selectedTeam,
            status: _status,
            submittedAt: _submittedAt,
            aiCategory: _aiSuggestedCategory,
          ),

          const SizedBox(height: 20),

          // ── Real-time tracking steps ───────────────────────────────
          _SectionLabel(label: 'Gerçek Zamanlı Takip', icon: 'radar'),
          const SizedBox(height: 12),
          _TrackingTimeline(
            messages: _trackingMessages,
            currentStep: _trackingStep,
            pulseController: _pulseController,
          ),

          const SizedBox(height: 24),

          // ── Action buttons ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportPdf,
                  icon: CustomIconWidget(
                    iconName: 'picture_as_pdf',
                    color: AppTheme.error,
                    size: 18,
                  ),
                  label: Text(
                    'PDF Dışa Aktar',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.error.withAlpha(128),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetForm,
                  icon: CustomIconWidget(
                    iconName: 'add_circle_outline',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Yeni Olay',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── AI Suggestion Panel ───────────────────────────────────────────────────────

class _AiSuggestionPanel extends StatelessWidget {
  final bool isLoading;
  final IncidentPriority? suggestedPriority;
  final String? suggestedCategory;
  final String? reasoning;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _AiSuggestionPanel({
    required this.isLoading,
    required this.suggestedPriority,
    required this.suggestedCategory,
    required this.reasoning,
    required this.applied,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading state
    if (isLoading) {
      return _buildContainer(
        theme,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Gemini olay analiz ediyor...',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFB0B0C8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Show suggestion
    if (suggestedPriority != null && suggestedCategory != null && !applied) {
      final pColor = _priorityColor(suggestedPriority!);
      return _buildContainer(
        theme,
        borderColor: const Color(0xFF8B5CF6).withAlpha(102),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF8B5CF6),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gemini AI Önerisi',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Suggestions row
            Row(
              children: [
                // Priority chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Öncelik',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: pColor.withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: pColor.withAlpha(102),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: pColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _priorityLabel(suggestedPriority!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: pColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Category chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          suggestedCategory!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB794F4),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Reasoning
            if (reasoning != null && reasoning!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                reasoning!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text(
                  'Önceliği Uygula',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show applied state
    if (applied && suggestedCategory != null) {
      return _buildContainer(
        theme,
        borderColor: AppTheme.success.withAlpha(76),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI önerisi uygulandı — Kategori: $suggestedCategory',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildContainer(
    ThemeData theme, {
    required Widget child,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withAlpha(204),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor ?? AppTheme.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Priority helpers ──────────────────────────────────────────────────────────

Color _priorityColor(IncidentPriority p) {
  switch (p) {
    case IncidentPriority.low:
      return AppTheme.success;
    case IncidentPriority.medium:
      return AppTheme.warning;
    case IncidentPriority.high:
      return const Color(0xFFFF6B35);
    case IncidentPriority.critical:
      return AppTheme.error;
  }
}

String _priorityLabel(IncidentPriority p) {
  switch (p) {
    case IncidentPriority.low:
      return 'Düşük';
    case IncidentPriority.medium:
      return 'Orta';
    case IncidentPriority.high:
      return 'Yüksek';
    case IncidentPriority.critical:
      return 'KRİTİK';
  }
}

String _statusLabel(IncidentStatus s) {
  switch (s) {
    case IncidentStatus.open:
      return 'Açık';
    case IncidentStatus.inProgress:
      return 'Devam Ediyor';
    case IncidentStatus.resolved:
      return 'Çözüldü';
    case IncidentStatus.closed:
      return 'Kapatıldı';
  }
}

Color _statusColor(IncidentStatus s) {
  switch (s) {
    case IncidentStatus.open:
      return AppTheme.info;
    case IncidentStatus.inProgress:
      return AppTheme.warning;
    case IncidentStatus.resolved:
      return AppTheme.success;
    case IncidentStatus.closed:
      return const Color(0xFF6B7280);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CustomIconWidget(iconName: icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final IncidentPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(102), width: 1),
      ),
      child: Text(
        _priorityLabel(priority),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final IncidentPriority selected;
  final ValueChanged<IncidentPriority> onChanged;

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: IncidentPriority.values.map((p) {
        final isSelected = p == selected;
        final color = _priorityColor(p);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(51) : AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color.withAlpha(153)
                      : AppTheme.glassBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _priorityLabel(p),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? color : const Color(0xFFB0B0C8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TeamGrid extends StatelessWidget {
  final List<IncidentTeam> teams;
  final IncidentTeam? selected;
  final ValueChanged<IncidentTeam> onSelected;

  const _TeamGrid({
    required this.teams,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: teams.length,
      itemBuilder: (context, i) {
        final team = teams[i];
        final isSelected = selected?.id == team.id;
        return GestureDetector(
          onTap: () => onSelected(team),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? team.color.withAlpha(51)
                  : AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? team.color.withAlpha(153)
                    : AppTheme.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: team.icon,
                  color: isSelected ? team.color : const Color(0xFFB0B0C8),
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  team.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? team.color : const Color(0xFFB0B0C8),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final IncidentStatus selected;
  final ValueChanged<IncidentStatus> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IncidentStatus.values.map((s) {
        final isSelected = s == selected;
        final color = _statusColor(s);
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(51) : AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? color.withAlpha(153) : AppTheme.glassBorder,
                width: 1,
              ),
            ),
            child: Text(
              _statusLabel(s),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFFB0B0C8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _IncidentSummaryCard extends StatelessWidget {
  final String title;
  final String location;
  final IncidentPriority priority;
  final IncidentTeam? team;
  final IncidentStatus status;
  final DateTime? submittedAt;
  final String? aiCategory;

  const _IncidentSummaryCard({
    required this.title,
    required this.location,
    required this.priority,
    required this.team,
    required this.status,
    required this.submittedAt,
    this.aiCategory,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pColor = _priorityColor(priority);
    final sColor = _statusColor(status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pColor.withAlpha(76), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PriorityBadge(priority: priority),
                ],
              ),
              if (aiCategory != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF8B5CF6),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kategori: $aiCategory',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFB794F4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              _SummaryRow(icon: 'location_on', text: location),
              if (team != null) ...[
                const SizedBox(height: 6),
                _SummaryRow(icon: team!.icon, text: team!.name),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: sColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sColor.withAlpha(76), width: 1),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 10,
                        color: sColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(submittedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String icon;
  final String text;
  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Tracking timeline ─────────────────────────────────────────────────────────

class _TrackingTimeline extends StatelessWidget {
  final List<String> messages;
  final int currentStep;
  final AnimationController pulseController;

  const _TrackingTimeline({
    required this.messages,
    required this.currentStep,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
          ),
          child: Column(
            children: List.generate(messages.length, (i) {
              final isDone = i <= currentStep;
              final isActive = i == currentStep;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Step indicator
                    AnimatedBuilder(
                      animation: pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppTheme.success.withAlpha(51)
                                : AppTheme.glassSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.success.withAlpha(
                                      (153 * pulseController.value).toInt(),
                                    )
                                  : isDone
                                  ? AppTheme.success.withAlpha(153)
                                  : AppTheme.glassBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isDone
                                ? CustomIconWidget(
                                    iconName: 'check',
                                    color: AppTheme.success,
                                    size: 14,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        messages[i],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDone
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          fontWeight: isDone
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isActive)
                      AnimatedBuilder(
                        animation: pulseController,
                        builder: (context, child) => Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(
                              (255 * pulseController.value).toInt(),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
