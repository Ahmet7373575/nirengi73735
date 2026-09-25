import 'dart:ui';


import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';

/// Glassmorphism home AppBar — avatar left + greeting center + actions right.
/// Anatomy locked from reference image extraction.
class HomeAppBarWidget extends StatelessWidget {
  final String officerName;
  final String rank;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const HomeAppBarWidget({
    super.key,
    required this.officerName,
    required this.rank,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withAlpha(128),
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(20), width: 1),
            ),
          ),
          child: Row(
            children: [
              // ── Avatar circle ─────────────────────────────────────────
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      officerName.isNotEmpty
                          ? officerName[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Greeting + name ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      officerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Date badge ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.glassBorder, width: 1),
                ),
                child: Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Notification button ───────────────────────────────────
              GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.glassBorder, width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'notifications_outlined',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Sign-out button ───────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.authScreen);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.glassBorder, width: 1),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'logout',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
