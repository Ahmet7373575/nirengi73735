import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import './activity_feed_service.dart';
import '../presentation/notification_preferences_screen/notification_preferences_screen.dart';

/// Maps [ActivityEventType] to a notification priority/importance level.
/// Only critical and high-importance events trigger a heads-up notification.
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<ActivityEvent>? _feedSubscription;
  bool _initialized = false;

  // ── Channel IDs ────────────────────────────────────────────────────────
  static const String _criticalChannelId = 'critical_incidents';
  static const String _criticalChannelName = 'Kritik Olaylar';
  static const String _criticalChannelDesc =
      'Kritik olay ve acil durum bildirimleri';

  static const String _teamChannelId = 'team_updates';
  static const String _teamChannelName = 'Ekip Güncellemeleri';
  static const String _teamChannelDesc =
      'Not gönderme, taslak ve PDF bildirimleri';

  // ── Notification ID counter ────────────────────────────────────────────
  int _notifId = 0;
  int get _nextId => _notifId++;

  /// Initialize the plugin and request permissions.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Request Android 13+ notification permission
    if (!kIsWeb) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  /// Start listening to [ActivityFeedService] and forward events as
  /// native notifications.
  void startListening() {
    _feedSubscription?.cancel();
    _feedSubscription = ActivityFeedService.instance.events.listen(
      _onActivityEvent,
      onError: (e) => debugPrint('[NotificationService] Stream error: $e'),
    );
    debugPrint('[NotificationService] Listening to ActivityFeedService');
  }

  void _onActivityEvent(ActivityEvent event) {
    // ── Quiet hours gate ────────────────────────────────────────────────────
    // Critical incidents bypass quiet hours — all others are suppressed.
    final isCritical =
        event.type == ActivityEventType.noteSubmitted &&
        event.title.toLowerCase().contains('kritik');

    if (NotifPrefs.isQuietNow && !isCritical) return;

    switch (event.type) {
      case ActivityEventType.noteSubmitted:
        // Respect critical incidents toggle
        if (!NotifPrefs.isCriticalEnabled) return;
        // Priority threshold: noteSubmitted treated as "high"
        if (NotifPrefs.threshold > 2) return;
        _showNotification(
          id: _nextId,
          channelId: _teamChannelId,
          channelName: _teamChannelName,
          channelDesc: _teamChannelDesc,
          title: '📋 Not Gönderildi',
          body: _buildBody(event),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        break;

      case ActivityEventType.draftSaved:
        if (!NotifPrefs.isTeamUpdatesEnabled) return;
        if (NotifPrefs.threshold > 0) return; // low priority
        _showNotification(
          id: _nextId,
          channelId: _teamChannelId,
          channelName: _teamChannelName,
          channelDesc: _teamChannelDesc,
          title: '💾 Taslak Kaydedildi',
          body: _buildBody(event),
          importance: Importance.low,
          priority: Priority.low,
        );
        break;

      case ActivityEventType.draftUpdated:
        if (!NotifPrefs.isTeamUpdatesEnabled) return;
        if (NotifPrefs.threshold > 0) return;
        _showNotification(
          id: _nextId,
          channelId: _teamChannelId,
          channelName: _teamChannelName,
          channelDesc: _teamChannelDesc,
          title: '✏️ Taslak Güncellendi',
          body: _buildBody(event),
          importance: Importance.low,
          priority: Priority.low,
        );
        break;

      case ActivityEventType.pdfGenerated:
        if (!NotifPrefs.isTeamUpdatesEnabled) return;
        if (NotifPrefs.threshold > 1) return; // medium priority
        _showNotification(
          id: _nextId,
          channelId: _teamChannelId,
          channelName: _teamChannelName,
          channelDesc: _teamChannelDesc,
          title: '📄 PDF Oluşturuldu',
          body: event.subtitle,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        break;

      case ActivityEventType.profileUpdated:
        if (!NotifPrefs.isTeamUpdatesEnabled) return;
        if (NotifPrefs.threshold > 0) return;
        _showNotification(
          id: _nextId,
          channelId: _teamChannelId,
          channelName: _teamChannelName,
          channelDesc: _teamChannelDesc,
          title: '👤 Profil Güncellendi',
          body: event.subtitle,
          importance: Importance.low,
          priority: Priority.low,
        );
        break;

      case ActivityEventType.syncCompleted:
        if (!NotifPrefs.isTeamUpdatesEnabled) return;
        if (NotifPrefs.threshold > 0) return;
        _showNotification(
          id: _nextId,
          channelId: _teamChannelId,
          channelName: _teamChannelName,
          channelDesc: _teamChannelDesc,
          title: '🔄 Senkronizasyon Tamamlandı',
          body: event.subtitle,
          importance: Importance.min,
          priority: Priority.min,
        );
        break;
    }
  }

  String _buildBody(ActivityEvent event) {
    final parts = <String>[];
    if (event.officerName != null && event.officerName!.isNotEmpty) {
      parts.add(event.officerName!);
    }
    if (event.badgeNumber != null && event.badgeNumber!.isNotEmpty) {
      parts.add('(${event.badgeNumber})');
    }
    if (event.subtitle.isNotEmpty) {
      parts.add('— ${event.subtitle}');
    }
    return parts.isNotEmpty ? parts.join(' ') : event.title;
  }

  Future<void> _showNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
    required Importance importance,
    required Priority priority,
  }) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: importance.value >= Importance.defaultImportance.value,
      playSound: importance.value >= Importance.defaultImportance.value,
      styleInformation: BigTextStyleInformation(body),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to show notification: $e');
    }
  }

  /// Show a manual critical incident alert (e.g. from RapidIncidentScreen).
  Future<void> showCriticalIncidentAlert({
    required String incidentTitle,
    required String description,
    String? assignedTeam,
  }) async {
    if (!_initialized) return;
    // Critical incidents always fire — they bypass quiet hours and threshold
    // unless the officer has explicitly disabled critical incident alerts.
    if (!NotifPrefs.isCriticalEnabled) return;

    final body = assignedTeam != null
        ? '$description\nEkip: $assignedTeam'
        : description;

    final androidDetails = AndroidNotificationDetails(
      _criticalChannelId,
      _criticalChannelName,
      channelDescription: _criticalChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      color: const Color(0xFFEF4444),
      styleInformation: BigTextStyleInformation(body),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _plugin.show(
        id: _nextId,
        title: '🚨 KRİTİK OLAY: $incidentTitle',
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to show critical alert: $e');
    }
  }

  /// Stop listening and clean up.
  void dispose() {
    _feedSubscription?.cancel();
    _feedSubscription = null;
    _instance = null;
  }
}
