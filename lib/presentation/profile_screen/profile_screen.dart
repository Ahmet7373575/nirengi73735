import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

/// Profile Screen — shows authenticated officer details and app settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Settings state ────────────────────────────────────────────────────────
  bool _notifIncidentAlerts = true;
  bool _notifDraftReminders = true;
  bool _notifSyncStatus = false;
  int _syncFrequencyMinutes = 5; // 1, 5, 15, 30, 60

  bool _loading = true;

  // ── Officer profile fields (from Supabase user metadata) ─────────────────
  String _fullName = '';
  String _email = '';
  String _badgeNumber = '';
  String _rank = '';
  String _team = '';
  String _shiftSchedule = '';

  static const _prefKeyNotifIncident = 'pref_notif_incident';
  static const _prefKeyNotifDraft = 'pref_notif_draft';
  static const _prefKeyNotifSync = 'pref_notif_sync';
  static const _prefKeySyncFreq = 'pref_sync_freq';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUserProfile(), _loadPreferences()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadUserProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? {};
    _fullName = (meta['full_name'] as String?)?.trim() ?? '';
    _email = user.email ?? '';
    _badgeNumber = (meta['badge_number'] as String?) ?? '';
    _rank = (meta['rank'] as String?) ?? '';
    _team = (meta['team'] as String?) ?? '';
    _shiftSchedule = (meta['shift_schedule'] as String?) ?? '';

    try {
      final member = await AuthService.instance.fetchCurrentTeamMember();
      if (member != null) {
        _fullName = (member['name'] as String?)?.trim() ?? _fullName;
        _badgeNumber =
            (member['badge_number'] as String?)?.trim() ?? _badgeNumber;
        _rank = (member['rank'] as String?)?.trim() ?? _rank;
        _team = (member['team_name'] as String?)?.trim() ?? _team;
        _shiftSchedule =
            (member['shift_status'] as String?)?.trim() ?? _shiftSchedule;
        _email = (member['email'] as String?)?.trim() ?? _email;
      }
    } catch (error) {
      debugPrint('Profile team member load error: $error');
    }

    // Fallback: derive display name from email if no full_name
    if (_fullName.isEmpty && _email.isNotEmpty) {
      _fullName = _email.split('@').first.replaceAll('.', ' ');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notifIncidentAlerts = prefs.getBool(_prefKeyNotifIncident) ?? true;
    _notifDraftReminders = prefs.getBool(_prefKeyNotifDraft) ?? true;
    _notifSyncStatus = prefs.getBool(_prefKeyNotifSync) ?? false;
    _syncFrequencyMinutes = prefs.getInt(_prefKeySyncFreq) ?? 5;
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  String _initials() {
    final parts = _fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  String _syncLabel(int minutes) {
    if (minutes == 1) return '1 dakika';
    if (minutes == 60) return '1 saat';
    return '$minutes dakika';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      // resizeToAvoidBottomInset prevents keyboard from covering content
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader(theme)),

                  // ── Officer Details Card ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildOfficerDetailsCard(theme),
                    ),
                  ),

                  // ── Notification Settings ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildNotificationCard(theme),
                    ),
                  ),

                  // ── Sync Settings ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildSyncCard(theme),
                    ),
                  ),

                  // ── Sign Out ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: _buildSignOutButton(theme),
                    ),
                  ),

                  // ── Bottom padding for nav bar ───────────────────────────
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withAlpha(38), width: 2),
            ),
            child: Center(
              child: Text(
                _initials(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName.isNotEmpty ? _fullName : 'Memur',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _rank.isNotEmpty ? _rank : _email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_rank.isNotEmpty && _email.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    _email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Officer Details Card ────────────────────────────────────────────────────
  Widget _buildOfficerDetailsCard(ThemeData theme) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Memur Bilgileri', icon: 'badge'),
          const SizedBox(height: 12),
          _DetailRow(
            icon: 'tag',
            label: 'Sicil Numarası',
            value: _badgeNumber.isNotEmpty ? _badgeNumber : '—',
          ),
          _DetailRow(
            icon: 'military_tech',
            label: 'Rütbe',
            value: _rank.isNotEmpty ? _rank : '—',
          ),
          _DetailRow(
            icon: 'groups',
            label: 'Ekip',
            value: _team.isNotEmpty ? _team : '—',
          ),
          _DetailRow(
            icon: 'schedule',
            label: 'Vardiya',
            value: _shiftSchedule.isNotEmpty ? _shiftSchedule : '—',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Notification Settings Card ──────────────────────────────────────────────
  Widget _buildNotificationCard(ThemeData theme) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Bildirim Tercihleri', icon: 'notifications'),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: 'warning_amber',
            label: 'Olay Uyarıları',
            subtitle: 'Yeni olay bildirimleri',
            value: _notifIncidentAlerts,
            onChanged: (v) {
              setState(() => _notifIncidentAlerts = v);
              _savePreference(_prefKeyNotifIncident, v);
            },
          ),
          _ToggleRow(
            icon: 'edit_note',
            label: 'Taslak Hatırlatıcıları',
            subtitle: 'Kaydedilmemiş taslak uyarıları',
            value: _notifDraftReminders,
            onChanged: (v) {
              setState(() => _notifDraftReminders = v);
              _savePreference(_prefKeyNotifDraft, v);
            },
          ),
          _ToggleRow(
            icon: 'sync',
            label: 'Senkronizasyon Durumu',
            subtitle: 'Senkronizasyon tamamlandı bildirimleri',
            value: _notifSyncStatus,
            onChanged: (v) {
              setState(() => _notifSyncStatus = v);
              _savePreference(_prefKeyNotifSync, v);
            },
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          // ── Advanced notification preferences link ──────────────────────
          GestureDetector(
            onTap: () => context.push(AppRoutes.notificationPreferencesScreen),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gelişmiş Bildirim Ayarları',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Uyarı türleri, sessiz saatler, öncelik eşiği',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sync Settings Card ──────────────────────────────────────────────────────
  Widget _buildSyncCard(ThemeData theme) {
    final options = [1, 5, 15, 30, 60];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Senkronizasyon', icon: 'cloud_sync'),
          const SizedBox(height: 12),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'timer',
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Senkronizasyon Sıklığı',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((min) {
              final isSelected = min == _syncFrequencyMinutes;
              return GestureDetector(
                onTap: () {
                  setState(() => _syncFrequencyMinutes = min);
                  _savePreference(_prefKeySyncFreq, min);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withAlpha(51)
                        : Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary.withAlpha(153)
                          : Colors.white.withAlpha(26),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _syncLabel(min),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info_outline',
                color: theme.colorScheme.onSurfaceVariant,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Çevrimdışıyken değişiklikler yerel olarak saklanır ve bağlantı kurulduğunda otomatik senkronize edilir.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sign Out Button ─────────────────────────────────────────────────────────
  Widget _buildSignOutButton(ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Hesabınızdan çıkmak istediğinizden emin misiniz?',
              style: TextStyle(color: Color(0xFFB0B0C8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'İptal',
                  style: TextStyle(color: Color(0xFFB0B0C8)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          try {
            await AuthService.instance.signOut();
            if (mounted) {
              context.go(AppRoutes.authScreen);
            }
          } catch (e) {
            debugPrint('Sign out error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Çıkış yapılırken bir sorun oluştu. Lütfen tekrar deneyin.',
                  ),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.error.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.error.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: AppTheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Çıkış Yap',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(33), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: icon,
            color: AppTheme.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.white.withAlpha(18)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: value
                    ? AppTheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.primary,
                activeTrackColor: AppTheme.primary.withAlpha(77),
                inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
                inactiveTrackColor: Colors.white.withAlpha(26),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.white.withAlpha(18)),
      ],
    );
  }
}
