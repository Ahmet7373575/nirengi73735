import 'dart:ui';

import '../../../core/app_export.dart';
import '../../../services/note_storage_service.dart';

/// Recent note data model.
class RecentNoteModel {
  final String id;
  final String title;
  final String category;
  final String time;
  final String status;
  final Color statusColor;
  final String iconName;
  final Color iconColor;
  final String officerName;
  final DateTime date;

  const RecentNoteModel({
    required this.id,
    required this.title,
    required this.category,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.iconName,
    required this.iconColor,
    required this.officerName,
    required this.date,
  });

  factory RecentNoteModel.fromMap(Map<String, dynamic> map) {
    return RecentNoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      time: map['time'] as String,
      status: map['status'] as String,
      statusColor: Color(map['statusColorHex'] as int),
      iconName: map['iconName'] as String,
      iconColor: Color(map['iconColorHex'] as int),
      officerName: map['officerName'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
    );
  }
}

/// Recent notes section — section header + rich data rows + filters.
class RecentNotesSectionWidget extends StatefulWidget {
  const RecentNotesSectionWidget({super.key});

  @override
  State<RecentNotesSectionWidget> createState() =>
      _RecentNotesSectionWidgetState();
}

class _RecentNotesSectionWidgetState extends State<RecentNotesSectionWidget> {
  late List<RecentNoteModel> _notes;
  late List<RecentNoteModel> _pdfRecords;
  int _activeTab = 0; // 0=Son Notlar, 1=PDF, 2=Favoriler

  // Filter state
  bool _showFilters = false;
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _officerController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _keyword = '';
  String _officerFilter = '';

  static final List<Map<String, dynamic>> _noteMaps = [
    {
      'id': 'n001',
      'title': 'Şüpheli araç takip olayı — E-5 üzeri',
      'category': 'Kaçan Araç',
      'time': '13:42',
      'status': 'PDF Hazır',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'directions_car',
      'iconColorHex': 0xFFEF4444,
      'officerName': 'Mehmet Yılmaz',
      'date': '2024-01-15',
    },
    {
      'id': 'n002',
      'title': 'Komşu şikayeti üzerine gürültü tespiti',
      'category': 'Asayiş',
      'time': '12:15',
      'status': 'Taslak',
      'statusColorHex': 0xFFF59E0B,
      'iconName': 'local_police',
      'iconColorHex': 0xFF3B82F6,
      'officerName': 'Ahmet Kaya',
      'date': '2024-01-15',
    },
    {
      'id': 'n003',
      'title': 'Kayıp çocuk başvurusu — 8 yaş, erkek',
      'category': 'Kayıp Şahıs',
      'time': '11:07',
      'status': 'Tamamlandı',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'child_care',
      'iconColorHex': 0xFF10B981,
      'officerName': 'Fatma Demir',
      'date': '2024-01-14',
    },
    {
      'id': 'n004',
      'title': 'Trafik kazası — hafif yaralanma, 2 araç',
      'category': 'Trafik Kazası',
      'time': '09:33',
      'status': 'PDF Hazır',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'car_crash',
      'iconColorHex': 0xFFF59E0B,
      'officerName': 'Mehmet Yılmaz',
      'date': '2024-01-14',
    },
    {
      'id': 'n005',
      'title': 'Aile içi anlaşmazlık — tanıklı ifade',
      'category': 'Aile İçi',
      'time': '08:50',
      'status': 'Tamamlandı',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'family_restroom',
      'iconColorHex': 0xFFEC4899,
      'officerName': 'Ali Çelik',
      'date': '2024-01-13',
    },
  ];

  static final List<Map<String, dynamic>> _pdfMaps = [
    {
      'id': 'p001',
      'title': 'Olay Tutanağı — Araç Takip #2024-001',
      'category': 'Trafik',
      'time': '14:00',
      'status': 'PDF Hazır',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'picture_as_pdf',
      'iconColorHex': 0xFFEF4444,
      'officerName': 'Mehmet Yılmaz',
      'date': '2024-01-15',
    },
    {
      'id': 'p002',
      'title': 'Bilgi Notu — Kayıp Şahıs Raporu',
      'category': 'Kayıp',
      'time': '11:30',
      'status': 'PDF Hazır',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'picture_as_pdf',
      'iconColorHex': 0xFFEF4444,
      'officerName': 'Fatma Demir',
      'date': '2024-01-14',
    },
    {
      'id': 'p003',
      'title': 'Kaza Tespit Tutanağı — E-5 Km 42',
      'category': 'Trafik Kazası',
      'time': '10:15',
      'status': 'PDF Hazır',
      'statusColorHex': 0xFF22C55E,
      'iconName': 'picture_as_pdf',
      'iconColorHex': 0xFFEF4444,
      'officerName': 'Ahmet Kaya',
      'date': '2024-01-13',
    },
  ];

  @override
  void initState() {
    super.initState();
    _notes = [];
    _pdfRecords = [];
    _loadRemoteNotes();
  }

  Future<void> _loadRemoteNotes() async {
    try {
      final submitted = await NoteStorageService.instance.fetchSubmittedNotes();
      final pdfs = await NoteStorageService.instance.fetchPdfRecords();
      if (!mounted) return;
      setState(() {
        _notes = submitted.map(_submittedToModel).toList();
        _pdfRecords = pdfs.map(_pdfToModel).toList();
      });
    } catch (error) {
      debugPrint('Recent notes load error: $error');
    }
  }

  RecentNoteModel _submittedToModel(Map<String, dynamic> note) {
    final date = DateTime.tryParse(
          note['submitted_at']?.toString() ?? '',
        ) ??
        DateTime.now();
    return RecentNoteModel(
      id: note['id']?.toString() ?? note['local_id']?.toString() ?? '',
      title: note['subject']?.toString() ?? 'Bilgi Notu',
      category: note['template_name']?.toString() ?? 'Genel Bilgi Notu',
      time: '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      status: 'Tamamlandı',
      statusColor: AppTheme.success,
      iconName: 'description',
      iconColor: AppTheme.primary,
      officerName: note['personnel_name']?.toString() ?? '',
      date: date,
    );
  }

  RecentNoteModel _pdfToModel(Map<String, dynamic> pdf) {
    final date = DateTime.tryParse(
          pdf['generated_at']?.toString() ?? pdf['created_at']?.toString() ?? '',
        ) ??
        DateTime.now();
    return RecentNoteModel(
      id: pdf['id']?.toString() ?? pdf['local_id']?.toString() ?? '',
      title: pdf['file_name']?.toString() ?? 'PDF Belgesi',
      category: 'PDF',
      time: '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      status: pdf['pdf_status']?.toString() ?? 'generated',
      statusColor: AppTheme.success,
      iconName: 'picture_as_pdf',
      iconColor: AppTheme.error,
      officerName: '',
      date: date,
    );
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _officerController.dispose();
    super.dispose();
  }

  List<RecentNoteModel> get _filteredList {
    final source = _activeTab == 1 ? _pdfRecords : _notes;
    return source.where((note) {
      // Keyword filter
      if (_keyword.isNotEmpty) {
        final kw = _keyword.toLowerCase();
        if (!note.title.toLowerCase().contains(kw) &&
            !note.category.toLowerCase().contains(kw)) {
          return false;
        }
      }
      // Officer filter
      if (_officerFilter.isNotEmpty) {
        if (!note.officerName.toLowerCase().contains(
          _officerFilter.toLowerCase(),
        )) {
          return false;
        }
      }
      // Date range filter
      if (_selectedDateRange != null) {
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end;
        if (note.date.isBefore(start) ||
            note.date.isAfter(end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _keyword.isNotEmpty ||
      _officerFilter.isNotEmpty ||
      _selectedDateRange != null;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.surfaceDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _keyword = '';
      _officerFilter = '';
      _selectedDateRange = null;
      _keywordController.clear();
      _officerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with tabs ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _SectionTab(
                    label: 'Son Notlar',
                    isActive: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                  const SizedBox(width: 8),
                  _SectionTab(
                    label: 'PDF\'ler',
                    isActive: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                  const SizedBox(width: 8),
                  _SectionTab(
                    label: 'Favoriler',
                    isActive: _activeTab == 2,
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                ],
              ),
            ),
            // Filter toggle button
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (_showFilters || _hasActiveFilters)
                      ? AppTheme.primary.withAlpha(51)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (_showFilters || _hasActiveFilters)
                        ? AppTheme.primary.withAlpha(102)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'tune',
                      color: (_showFilters || _hasActiveFilters)
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Tümünü Gör',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),

        // ── Filter panel ────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _showFilters
              ? _FilterPanel(
                  keywordController: _keywordController,
                  officerController: _officerController,
                  selectedDateRange: _selectedDateRange,
                  hasActiveFilters: _hasActiveFilters,
                  onKeywordChanged: (v) => setState(() => _keyword = v),
                  onOfficerChanged: (v) => setState(() => _officerFilter = v),
                  onDateRangeTap: _pickDateRange,
                  onClearFilters: _clearFilters,
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),

        // ── Note rows ───────────────────────────────────────────────────
        if (_activeTab == 2)
          _EmptyFavorites()
        else if (filtered.isEmpty)
          _EmptyFilterResult(onClear: _clearFilters)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: Column(
                  children: List.generate(filtered.length, (i) {
                    final note = filtered[i];
                    return _NoteRow(
                      note: note,
                      showDivider: i < filtered.length - 1,
                      onTap: () {},
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Filter Panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final TextEditingController keywordController;
  final TextEditingController officerController;
  final DateTimeRange? selectedDateRange;
  final bool hasActiveFilters;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<String> onOfficerChanged;
  final VoidCallback onDateRangeTap;
  final VoidCallback onClearFilters;

  const _FilterPanel({
    required this.keywordController,
    required this.officerController,
    required this.selectedDateRange,
    required this.hasActiveFilters,
    required this.onKeywordChanged,
    required this.onOfficerChanged,
    required this.onDateRangeTap,
    required this.onClearFilters,
  });

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keyword search
          TextField(
            controller: keywordController,
            onChanged: onKeywordChanged,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Anahtar kelime ara...',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Officer name search
          TextField(
            controller: officerController,
            onChanged: onOfficerChanged,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Memur adı ile filtrele...',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: CustomIconWidget(
                  iconName: 'badge',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Date range picker
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDateRangeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedDateRange != null
                            ? AppTheme.primary.withAlpha(128)
                            : AppTheme.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'date_range',
                          color: selectedDateRange != null
                              ? AppTheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedDateRange != null
                                ? '${_formatDate(selectedDateRange!.start)} – ${_formatDate(selectedDateRange!.end)}'
                                : 'Tarih aralığı seç',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: selectedDateRange != null
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasActiveFilters) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearFilters,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.error.withAlpha(64),
                        width: 1,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'filter_alt_off',
                      color: AppTheme.error,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'star_border',
            color: theme.colorScheme.onSurfaceVariant,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz favori eklenmedi',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterResult extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyFilterResult({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Filtreyle eşleşen kayıt bulunamadı',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Filtreleri Temizle',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Tab ───────────────────────────────────────────────────────────────

class _SectionTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SectionTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withAlpha(102)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? AppTheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Note Row ──────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  final RecentNoteModel note;
  final bool showDivider;
  final VoidCallback onTap;

  const _NoteRow({
    required this.note,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          splashColor: AppTheme.primary.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // ── Category icon ────────────────────────────────────
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: note.iconColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: note.iconColor.withAlpha(64),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: note.iconName,
                      color: note.iconColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Content ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusBadgeWidget(
                            label: note.status,
                            color: note.statusColor,
                            fontSize: 10,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            note.category,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          if (note.officerName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            CustomIconWidget(
                              iconName: 'person',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                note.officerName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Time + arrow ──────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      note.time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    CustomIconWidget(
                      iconName: 'chevron_right',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withAlpha(15),
            indent: 68,
          ),
      ],
    );
  }
}
