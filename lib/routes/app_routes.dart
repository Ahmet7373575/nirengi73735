import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/information_note_screen/information_note_screen.dart';
import '../presentation/ai_assistant_screen/ai_assistant_screen.dart';
import '../presentation/auth_screen/auth_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/rapid_incident_screen/rapid_incident_screen.dart';
import '../presentation/notification_preferences_screen/notification_preferences_screen.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

/// Route path constants — one per screen, no aliasing.
class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String authScreen = '/auth';
  static const String homeScreen = '/home-screen';
  static const String informationNoteScreen = '/information-note-screen';
  static const String aiAssistantScreen = '/ai-assistant-screen';
  static const String profileScreen = '/profile-screen';
  static const String rapidIncidentScreen = '/rapid-incident-screen';
  static const String notificationPreferencesScreen =
      '/notification-preferences-screen';
}

/// Top-level GoRouter instance with auth redirect guard.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  // Error builder prevents blank/black screen on unknown routes
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF0F0F1A),
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Sayfa bulunamadı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.homeScreen),
              child: const Text(
                'Ana Sayfaya Dön',
                style: TextStyle(color: Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  redirect: (context, state) {
    try {
      final isAuthenticated = AuthService.instance.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.authScreen;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.authScreen;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.homeScreen;
      }
      // Redirect root to home when authenticated
      if (isAuthenticated && state.matchedLocation == AppRoutes.initial) {
        return AppRoutes.homeScreen;
      }
    } catch (e) {
      debugPrint('Router redirect error: $e');
      return AppRoutes.authScreen;
    }
    return null;
  },
  routes: [
    // ── Auth screen ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.authScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),

    // ── Root entry point ──────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),

    // ── Rapid Incident Screen ─────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.rapidIncidentScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RapidIncidentScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),

    // ── Notification Preferences Screen ──────────────────────────────────
    GoRoute(
      path: AppRoutes.notificationPreferencesScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationPreferencesScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),

    // ── StatefulShellRoute — persistent bottom nav tabs ──────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.informationNoteScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: InformationNoteScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.aiAssistantScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AiAssistantScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
