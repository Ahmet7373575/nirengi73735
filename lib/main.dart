import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './presentation/notification_preferences_screen/notification_preferences_screen.dart';
import './services/activity_feed_service.dart';
import './services/incident_service.dart';
import './services/note_cache_service.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';
import 'routes/app_routes.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global Flutter error handler — set BEFORE runApp
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };

      // Catch async errors from platform
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
        return true;
      };

      bool hasShownError = false;

      // 🚨 CRITICAL: Custom error widget — DO NOT REMOVE
      ErrorWidget.builder = (FlutterErrorDetails details) {
        if (!hasShownError) {
          hasShownError = true;
          Future.delayed(const Duration(seconds: 5), () {
            hasShownError = false;
          });
          return CustomErrorWidget(errorDetails: details);
        }
        return const SizedBox.shrink();
      };

      // Initialize Supabase
      try {
        await SupabaseService.initialize();
        NoteCacheService.instance.startConnectivityListener();
        IncidentService.instance.startConnectivityListener();
        await IncidentService.instance.syncPendingIncidents();
      } catch (e) {
        debugPrint('Failed to initialize Supabase: $e');
      }

      // Load notification preferences into static cache
      try {
        await NotifPrefs.load();
      } catch (e) {
        debugPrint('Failed to load notification preferences: $e');
      }

      // Initialize push notifications
      try {
        await NotificationService.instance.initialize();
        ActivityFeedService.instance.subscribe();
        NotificationService.instance.startListening();
      } catch (e) {
        debugPrint('Failed to initialize NotificationService: $e');
      }

      // 🚨 CRITICAL: Device orientation lock — DO NOT REMOVE
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      GoRouter.optionURLReflectsImperativeAPIs = true;
      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      debugPrint('Unhandled zone error: $error\n$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'Nirengi',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        );
      },
    );
  }
}
