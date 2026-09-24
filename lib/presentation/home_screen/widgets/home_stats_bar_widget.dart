import '../../../core/app_export.dart';

/// Horizontal stats bar — today's operational metrics for the officer.
class HomeStatsBarWidget extends StatelessWidget {
  const HomeStatsBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stats = [
      _StatItem(
        label: 'Bugünkü Not',
        value: '7',
        icon: 'description',
        color: AppTheme.primary,
      ),
      _StatItem(
        label: 'PDF Oluştu',
        value: '4',
        icon: 'picture_as_pdf',
        color: AppTheme.success,
      ),
      _StatItem(
        label: 'Bekleyen',
        value: '3',
        icon: 'assignment',
        color: AppTheme.warning,
      ),
      _StatItem(
        label: 'Nöbet',
        value: '06:42',
        icon: 'access_time',
        color: AppTheme.info,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: stats
            .map((s) => Expanded(child: _StatCard(item: s)))
            .toList(),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withAlpha(64), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: item.icon, color: item.color, size: 16),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
