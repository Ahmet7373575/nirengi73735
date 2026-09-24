import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import './widgets/category_filter_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/home_stats_bar_widget.dart';
import './widgets/live_activity_feed_widget.dart';
import './widgets/recent_notes_section_widget.dart';
import './widgets/tool_card_grid_widget.dart';

/// Home Screen — Operational dashboard for field officers.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Tümü',
    'Asayiş',
    'Trafik',
    'Narkotik',
    'Yangın',
    'Kayıp',
    'Aile İçi',
    'Çocuk',
  ];

  String get _officerName {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return 'Memur';
      final meta = user.userMetadata ?? {};
      final fullName = (meta['full_name'] as String?)?.trim() ?? '';
      if (fullName.isNotEmpty) return fullName;
      final email = user.email ?? '';
      if (email.isNotEmpty) return email.split('@').first.replaceAll('.', ' ');
      return 'Memur';
    } catch (_) {
      return 'Memur';
    }
  }

  String get _officerRank {
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return '';
      final meta = user.userMetadata ?? {};
      return (meta['rank'] as String?)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Glassmorphism AppBar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: HomeAppBarWidget(
                officerName: _officerName,
                rank: _officerRank,
                onNotificationTap: () {},
                onProfileTap: () {
                  try {
                    context.go(AppRoutes.profileScreen);
                  } catch (e) {
                    debugPrint('Profile nav error: $e');
                  }
                },
              ),
            ),

            // ── Stats bar ────────────────────────────────────────────────
            const SliverToBoxAdapter(child: HomeStatsBarWidget()),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Category filter chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: CategoryFilterWidget(
                categories: _categories,
                selectedIndex: _selectedCategoryIndex,
                onSelected: (i) {
                  if (mounted) setState(() => _selectedCategoryIndex = i);
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Tool cards grid ───────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: ToolCardGridWidget(
                  isTablet: isTablet,
                  onToolTap: (toolId) {
                    try {
                      context.go(AppRoutes.informationNoteScreen);
                    } catch (e) {
                      debugPrint('Tool nav error: $e');
                    }
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Recent notes section ──────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: RecentNotesSectionWidget()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Live activity feed ────────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: LiveActivityFeedWidget()),
            ),

            // ── Bottom padding for nav bar ────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'rapid_incident_fab',
            onPressed: () {
              try {
                context.push(AppRoutes.rapidIncidentScreen);
              } catch (e) {
                debugPrint('FAB nav error: $e');
              }
            },
            backgroundColor: AppTheme.error,
            icon: const Icon(Icons.flash_on, color: Colors.white, size: 20),
            label: const Text(
              'Hızlı Olay',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            elevation: 8,
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'new_note_fab',
            onPressed: () {
              try {
                context.go(AppRoutes.informationNoteScreen);
              } catch (e) {
                debugPrint('FAB nav error: $e');
              }
            },
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
