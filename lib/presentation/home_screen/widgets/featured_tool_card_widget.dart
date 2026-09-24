import 'dart:ui';

import '../../../core/app_export.dart';

/// Featured full-width glassmorphism card — title left + icon right +
/// description below + arrow top-right. Anatomy locked.
class FeaturedToolCardWidget extends StatelessWidget {
  const FeaturedToolCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(64),
                  AppTheme.secondary.withAlpha(38),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withAlpha(89),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: title + icon + arrow ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(51),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'YAPAY ZEKA ASİSTANI',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.primary,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bilgi Notu Oluştur',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Icon container ───────────────────────────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(51),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'smart_toy',
                          color: AppTheme.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // ── Arrow top-right ──────────────────────────────
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'north_east',
                          color: Colors.white.withAlpha(179),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Description ────────────────────────────────────────
                Text(
                  'Konuşarak resmi bilgi notu oluşturun. Yapay zeka eksik bilgileri sorar, tutanakları otomatik düzenler.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(179),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // ── Action row ─────────────────────────────────────────
                Row(
                  children: [
                    _ActionChip(
                      icon: 'mic',
                      label: 'Sesli Dikta',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      icon: 'edit',
                      label: 'Manuel Giriş',
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
