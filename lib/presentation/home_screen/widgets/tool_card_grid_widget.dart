import 'dart:ui';

import '../../../core/app_export.dart';

/// Tool data model — Map-first pattern.
class ToolModel {
  final String id;
  final String title;
  final String iconName;
  final Color color;
  final String category;
  final int noteCount;

  const ToolModel({
    required this.id,
    required this.title,
    required this.iconName,
    required this.color,
    required this.category,
    required this.noteCount,
  });

  factory ToolModel.fromMap(Map<String, dynamic> map) {
    return ToolModel(
      id: map['id'] as String,
      title: map['title'] as String,
      iconName: map['iconName'] as String,
      color: Color(map['colorHex'] as int),
      category: map['category'] as String,
      noteCount: map['noteCount'] as int,
    );
  }
}

/// 2-column (tablet: 3-column) grid of tool cards.
/// Each card: half-width glassmorphism, icon top-left + arrow top-right + label bottom.
class ToolCardGridWidget extends StatefulWidget {
  final bool isTablet;
  final ValueChanged<String> onToolTap;

  const ToolCardGridWidget({
    super.key,
    required this.isTablet,
    required this.onToolTap,
  });

  @override
  State<ToolCardGridWidget> createState() => _ToolCardGridWidgetState();
}

class _ToolCardGridWidgetState extends State<ToolCardGridWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  late List<ToolModel> _tools;

  static final List<Map<String, dynamic>> _toolMaps = [
    {
      'id': 'aranan_sahis',
      'title': 'Aranan Şahıs',
      'iconName': 'person_search',
      'colorHex': 0xFF3B82F6,
      'category': 'Asayiş',
      'noteCount': 12,
    },
    {
      'id': 'kacan_arac',
      'title': 'Kaçan Araç',
      'iconName': 'directions_car',
      'colorHex': 0xFFEF4444,
      'category': 'Trafik',
      'noteCount': 5,
    },
    {
      'id': 'trafik_kazasi',
      'title': 'Trafik Kazası',
      'iconName': 'car_crash',
      'colorHex': 0xFFF59E0B,
      'category': 'Trafik',
      'noteCount': 8,
    },
    {
      'id': 'yoklama_kacagi',
      'title': 'Yoklama Kaçağı',
      'iconName': 'badge',
      'colorHex': 0xFF8B5CF6,
      'category': 'Asayiş',
      'noteCount': 3,
    },
    {
      'id': 'genel_bilgi',
      'title': 'Genel Bilgi Notu',
      'iconName': 'notes',
      'colorHex': 0xFF06B6D4,
      'category': 'Genel',
      'noteCount': 24,
    },
    {
      'id': 'asayis',
      'title': 'Asayiş',
      'iconName': 'local_police',
      'colorHex': 0xFF3B82F6,
      'category': 'Asayiş',
      'noteCount': 17,
    },
    {
      'id': 'narkotik',
      'title': 'Narkotik',
      'iconName': 'medical_services',
      'colorHex': 0xFF8B5CF6,
      'category': 'Narkotik',
      'noteCount': 6,
    },
    {
      'id': 'kayip_sahis',
      'title': 'Kayıp Şahıs',
      'iconName': 'person_outline',
      'colorHex': 0xFFF59E0B,
      'category': 'Kayıp',
      'noteCount': 4,
    },
    {
      'id': 'aile_ici',
      'title': 'Aile İçi',
      'iconName': 'family_restroom',
      'colorHex': 0xFFEC4899,
      'category': 'Aile İçi',
      'noteCount': 9,
    },
    {
      'id': 'yangin',
      'title': 'Yangın',
      'iconName': 'local_fire_department',
      'colorHex': 0xFFEF4444,
      'category': 'Yangın',
      'noteCount': 2,
    },
    {
      'id': 'cocuk',
      'title': 'Çocuk',
      'iconName': 'child_care',
      'colorHex': 0xFF10B981,
      'category': 'Çocuk',
      'noteCount': 7,
    },
    {
      'id': 'trafik',
      'title': 'Trafik',
      'iconName': 'directions_car',
      'colorHex': 0xFF10B981,
      'category': 'Trafik',
      'noteCount': 11,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tools = _toolMaps.map(ToolModel.fromMap).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cols = widget.isTablet ? 3 : 2;
    final rows = (_tools.length / cols).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Modüller',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_tools.length} modül',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid
        for (int r = 0; r < rows; r++) ...[
          Row(
            children: [
              for (int c = 0; c < cols; c++) ...[
                if (r * cols + c < _tools.length)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: c < cols - 1 ? 8 : 0,
                        bottom: 8,
                      ),
                      child: _ToolCard(
                        tool: _tools[r * cols + c],
                        onTap: () => widget.onToolTap(_tools[r * cols + c].id),
                      ),
                    ),
                  )
                else
                  Expanded(child: const SizedBox()),
                if (c < cols - 1) const SizedBox(width: 0),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Individual tool card — glassmorphism, icon top-left + arrow top-right +
/// label bottom-left. Anatomy locked.
class _ToolCard extends StatefulWidget {
  final ToolModel tool;
  final VoidCallback onTap;

  const _ToolCard({required this.tool, required this.onTap});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 110,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.tool.color.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.tool.color.withAlpha(64),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: icon + arrow ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.tool.color.withAlpha(51),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: widget.tool.iconName,
                            color: widget.tool.color,
                            size: 20,
                          ),
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'north_east',
                        color: Colors.white.withAlpha(102),
                        size: 14,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // ── Label ─────────────────────────────────────────
                  Text(
                    widget.tool.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.tool.noteCount} not',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
