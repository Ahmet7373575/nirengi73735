import 'dart:ui';

import '../core/app_export.dart';

/// Internal tab specification — branchIndex null = stub tab (no navigation).
class _TabSpec {
  final String label;
  final String activeIcon;
  final String inactiveIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.branchIndex,
  });
}

/// V3 Liquid Glass BottomNav — BackdropFilter blur + frosted surface +
/// animated active pill. LOCKED — do not remove BackdropFilter.
class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedVisualIndex = 0;

  late AnimationController _pillController;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Ana Sayfa',
      activeIcon: 'home',
      inactiveIcon: 'home_outlined',
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Bilgi Notu',
      activeIcon: 'description',
      inactiveIcon: 'description_outlined',
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Tutanak',
      activeIcon: 'article',
      inactiveIcon: 'article_outlined',
      branchIndex: null, // stub — opens rapid incident
    ),
    _TabSpec(
      label: 'Yapay Zeka',
      activeIcon: 'smart_toy',
      inactiveIcon: 'smart_toy_outlined',
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Profil',
      activeIcon: 'person',
      inactiveIcon: 'person_outline',
      branchIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Sync visual index with shell on first build
    _syncVisualIndex();
  }

  @override
  void didUpdateWidget(AppNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncVisualIndex();
  }

  void _syncVisualIndex() {
    final currentBranch = widget.navigationShell.currentIndex;
    final matchingTab = _tabs.indexWhere((t) => t.branchIndex == currentBranch);
    if (matchingTab >= 0 && matchingTab != _selectedVisualIndex) {
      if (mounted) setState(() => _selectedVisualIndex = matchingTab);
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _onTabTap(int visualIndex) {
    if (!mounted) return;
    final tab = _tabs[visualIndex];

    // Tutanak tab — navigate to rapid incident screen
    if (tab.branchIndex == null && tab.label == 'Tutanak') {
      try {
        context.push('/rapid-incident-screen');
      } catch (e) {
        debugPrint('Navigation error: $e');
      }
      return;
    }

    // Other stub tabs — silently ignore
    if (tab.branchIndex == null) return;

    setState(() => _selectedVisualIndex = visualIndex);
    try {
      widget.navigationShell.goBranch(
        tab.branchIndex!,
        initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
      );
    } catch (e) {
      debugPrint('Branch navigation error: $e');
    }
    _pillController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + 12, left: 16, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          // LOCKED — Liquid Glass core technique
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(140),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withAlpha(38), width: 1),
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == _selectedVisualIndex;
                final isStub = tab.branchIndex == null;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Opacity(
                      opacity: isStub ? 0.6 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.all(6),
                        decoration: isActive
                            ? BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(64),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(
                                    102,
                                  ),
                                  width: 1,
                                ),
                              )
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: isActive
                                  ? tab.activeIcon
                                  : tab.inactiveIcon,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: isActive
                                  ? Text(
                                      tab.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
