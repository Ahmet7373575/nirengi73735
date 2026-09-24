import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

/// Notification preference keys — shared with NotificationService.
class NotifPrefs {
  NotifPrefs._();

  static const String criticalIncidents = 'notif_pref_critical_incidents';
  static const String teamUpdates = 'notif_pref_team_updates';
  static const String assignments = 'notif_pref_assignments';
  static const String quietHoursEnabled = 'notif_pref_quiet_hours_enabled';
  static const String quietHoursStart =
      'notif_pref_quiet_hours_start'; // int: hour 0-23
  static const String quietHoursEnd =
      'notif_pref_quiet_hours_end'; // int: hour 0-23
  static const String priorityThreshold =
      'notif_pref_priority_threshold'; // int: 0=all,1=medium+,2=high+,3=critical only

  // ── Static accessors (sync after load) ──────────────────────────────────
  static bool _criticalIncidents = true;
  static bool _teamUpdates = true;
  static bool _assignments = true;
  static bool _quietHoursEnabled = false;
  static int _quietHoursStart = 22;
  static int _quietHoursEnd = 7;
  static int _priorityThreshold = 0;

  static bool get isCriticalEnabled => _criticalIncidents;
  static bool get isTeamUpdatesEnabled => _teamUpdates;
  static bool get isAssignmentsEnabled => _assignments;
  static bool get isQuietHoursEnabled => _quietHoursEnabled;
  static int get quietStart => _quietHoursStart;
  static int get quietEnd => _quietHoursEnd;
  static int get threshold => _priorityThreshold;

  /// Returns true if current time is within quiet hours.
  static bool get isQuietNow {
    if (!_quietHoursEnabled) return false;
    final now = DateTime.now().hour;
    if (_quietHoursStart <= _quietHoursEnd) {
      return now >= _quietHoursStart && now < _quietHoursEnd;
    } else {
      // Wraps midnight e.g. 22:00 → 07:00
      return now >= _quietHoursStart || now < _quietHoursEnd;
    }
  }

  /// Load all prefs into static cache — call once at app start.
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _criticalIncidents = p.getBool(criticalIncidents) ?? true;
    _teamUpdates = p.getBool(teamUpdates) ?? true;
    _assignments = p.getBool(assignments) ?? true;
    _quietHoursEnabled = p.getBool(quietHoursEnabled) ?? false;
    _quietHoursStart = p.getInt(quietHoursStart) ?? 22;
    _quietHoursEnd = p.getInt(quietHoursEnd) ?? 7;
    _priorityThreshold = p.getInt(priorityThreshold) ?? 0;
  }

  static Future<void> _set(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is bool) await p.setBool(key, value);
    if (value is int) await p.setInt(key, value);
    // Refresh cache
    await load();
  }
}

/// Notification Preferences Screen — lets officers customize which alert
/// types trigger notifications, set quiet hours, and priority thresholds.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _criticalIncidents = true;
  bool _teamUpdates = true;
  bool _assignments = true;
  bool _quietHoursEnabled = false;
  int _quietStart = 22;
  int _quietEnd = 7;
  int _priorityThreshold = 0; // 0=Tümü, 1=Orta+, 2=Yüksek+, 3=Yalnızca Kritik

  bool _loading = true;
  bool _saving = false;

  static const List<String> _thresholdLabels = [
    'Tüm Bildirimler',
    'Orta ve Üzeri',
    'Yüksek ve Üzeri',
    'Yalnızca Kritik',
  ];

  static const List<String> _thresholdDescriptions = [
    'Düşük öncelikli bildirimler dahil tümü',
    'Düşük öncelikli bildirimler filtrelenir',
    'Yalnızca yüksek ve kritik olaylar',
    'Yalnızca acil kritik uyarılar',
  ];

  static const List<Color> _thresholdColors = [
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await NotifPrefs.load();
    if (!mounted) return;
    setState(() {
      _criticalIncidents = NotifPrefs.isCriticalEnabled;
      _teamUpdates = NotifPrefs.isTeamUpdatesEnabled;
      _assignments = NotifPrefs.isAssignmentsEnabled;
      _quietHoursEnabled = NotifPrefs.isQuietHoursEnabled;
      _quietStart = NotifPrefs.quietStart;
      _quietEnd = NotifPrefs.quietEnd;
      _priorityThreshold = NotifPrefs.threshold;
      _loading = false;
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final p = await SharedPreferences.getInstance();
    await p.setBool(NotifPrefs.criticalIncidents, _criticalIncidents);
    await p.setBool(NotifPrefs.teamUpdates, _teamUpdates);
    await p.setBool(NotifPrefs.assignments, _assignments);
    await p.setBool(NotifPrefs.quietHoursEnabled, _quietHoursEnabled);
    await p.setInt(NotifPrefs.quietHoursStart, _quietStart);
    await p.setInt(NotifPrefs.quietHoursEnd, _quietEnd);
    await p.setInt(NotifPrefs.priorityThreshold, _priorityThreshold);
    await NotifPrefs.load(); // Refresh static cache

    // Sync to Supabase backend (fire-and-forget, local prefs are source of truth)
    PreferencesService.instance.savePreferences(
      criticalIncidents: _criticalIncidents,
      teamUpdates: _teamUpdates,
      assignments: _assignments,
      quietHoursEnabled: _quietHoursEnabled,
      quietHoursStart: _quietStart,
      quietHoursEnd: _quietEnd,
      priorityThreshold: _priorityThreshold,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Bildirim tercihleri kaydedildi'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatHour(int hour) {
    final h = hour.toString().padLeft(2, '0');
    return '$h:00';
  }

  Future<void> _pickHour(bool isStart) async {
    final initial = TimeOfDay(
      hour: isStart ? _quietStart : _quietEnd,
      minute: 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Sessiz Saat Başlangıcı' : 'Sessiz Saat Bitişi',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppTheme.surfaceDark,
            hourMinuteColor: AppTheme.glassSurface,
            dialBackgroundColor: AppTheme.surfaceVariantDark,
            entryModeIconColor: AppTheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _quietStart = picked.hour;
      } else {
        _quietEnd = picked.hour;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: CustomScrollView(
                  slivers: [
                    // ── App Bar ────────────────────────────────────────────────
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppTheme.backgroundDark,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      title: Text(
                        'Bildirim Tercihleri',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : TextButton(
                                  onPressed: _saveAll,
                                  child: Text(
                                    'Kaydet',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── Alert Types Section ──────────────────────────────
                          _SectionHeader(
                            icon: 'notifications_active',
                            label: 'Uyarı Türleri',
                            subtitle:
                                'Hangi olayların bildirim göndereceğini seçin',
                          ),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: Column(
                              children: [
                                _AlertTypeRow(
                                  icon: 'warning_amber',
                                  iconColor: const Color(0xFFEF4444),
                                  title: 'Kritik Olaylar',
                                  subtitle: 'Acil müdahale gerektiren olaylar',
                                  value: _criticalIncidents,
                                  onChanged: (v) =>
                                      setState(() => _criticalIncidents = v),
                                ),
                                _Divider(),
                                _AlertTypeRow(
                                  icon: 'groups',
                                  iconColor: const Color(0xFF3B82F6),
                                  title: 'Ekip Güncellemeleri',
                                  subtitle:
                                      'Not gönderme, taslak ve senkronizasyon',
                                  value: _teamUpdates,
                                  onChanged: (v) =>
                                      setState(() => _teamUpdates = v),
                                ),
                                _Divider(),
                                _AlertTypeRow(
                                  icon: 'assignment_ind',
                                  iconColor: const Color(0xFF8B5CF6),
                                  title: 'Görev Atamaları',
                                  subtitle: 'Yeni görev ve olay atamaları',
                                  value: _assignments,
                                  onChanged: (v) =>
                                      setState(() => _assignments = v),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Priority Threshold Section ───────────────────────
                          _SectionHeader(
                            icon: 'tune',
                            label: 'Öncelik Eşiği',
                            subtitle: 'Minimum bildirim öncelik seviyesi',
                          ),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: Column(
                              children: List.generate(4, (i) {
                                final isSelected = _priorityThreshold == i;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _priorityThreshold = i),
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            color: _thresholdColors[i]
                                                .withAlpha(26),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _thresholdColors[i]
                                                  .withAlpha(77),
                                              width: 1,
                                            ),
                                          )
                                        : null,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? _thresholdColors[i]
                                                : AppTheme.glassBorder,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _thresholdLabels[i],
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? _thresholdColors[i]
                                                          : theme
                                                                .colorScheme
                                                                .onSurface,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _thresholdDescriptions[i],
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: _thresholdColors[i],
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Quiet Hours Section ──────────────────────────────
                          _SectionHeader(
                            icon: 'bedtime',
                            label: 'Sessiz Saatler',
                            subtitle:
                                'Bu saatler arasında bildirimler sessize alınır',
                          ),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: Column(
                              children: [
                                // Master toggle
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withAlpha(26),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.do_not_disturb_on_outlined,
                                          color: Color(0xFF8B5CF6),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sessiz Saatleri Etkinleştir',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              'Kritik olaylar sessiz saatlerde de bildirilir',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _quietHoursEnabled,
                                        onChanged: (v) => setState(
                                          () => _quietHoursEnabled = v,
                                        ),
                                        activeThumbColor: AppTheme.primary,
                                      ),
                                    ],
                                  ),
                                ),

                                // Time pickers — only visible when enabled
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 250),
                                  crossFadeState: _quietHoursEnabled
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: Column(
                                    children: [
                                      _Divider(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _TimePickerButton(
                                                label: 'Başlangıç',
                                                time: _formatHour(_quietStart),
                                                onTap: () => _pickHour(true),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: AppTheme.glassBorder,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _TimePickerButton(
                                                label: 'Bitiş',
                                                time: _formatHour(_quietEnd),
                                                onTap: () => _pickHour(false),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Summary chip
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          12,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF8B5CF6,
                                            ).withAlpha(20),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF8B5CF6,
                                              ).withAlpha(51),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.info_outline_rounded,
                                                color: Color(0xFF8B5CF6),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Sessiz: ${_formatHour(_quietStart)} – ${_formatHour(_quietEnd)}  •  Kritik olaylar her zaman bildirilir',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF8B5CF6,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  secondChild: const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Save Button ──────────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveAll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Tercihleri Kaydet',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CustomIconWidget(iconName: icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AlertTypeRow extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AlertTypeRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconData(icon), color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'warning_amber':
        return Icons.warning_amber_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'assignment_ind':
        return Icons.assignment_ind_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.glassBorder.withAlpha(77),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
