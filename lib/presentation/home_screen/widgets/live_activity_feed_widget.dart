import 'dart:async';
import 'dart:ui';

import '../../../core/app_export.dart';
import '../../../services/activity_feed_service.dart';

/// Live activity feed widget — shows real-time peer events on the home screen.
/// Subscribes to [ActivityFeedService] and prepends new events without
/// requiring a manual refresh.
class LiveActivityFeedWidget extends StatefulWidget {
  const LiveActivityFeedWidget({super.key});

  @override
  State<LiveActivityFeedWidget> createState() => _LiveActivityFeedWidgetState();
}

class _LiveActivityFeedWidgetState extends State<LiveActivityFeedWidget>
    with SingleTickerProviderStateMixin {
  final List<ActivityEvent> _events = [];
  StreamSubscription<ActivityEvent>? _sub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final bool _isLive = true;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    ActivityFeedService.instance.subscribe();
    _sub = ActivityFeedService.instance.events.listen(_onEvent);
  }

  void _onEvent(ActivityEvent event) {
    if (!mounted) return;
    setState(() {
      _events.insert(0, event);
      // Keep max 20 events in memory
      if (_events.length > 20) _events.removeLast();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success.withOpacity(_pulseAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withOpacity(
                        _pulseAnimation.value * 0.6,
                      ),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Canlı Aktivite',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(40),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.success.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Text(
                'CANLI',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Spacer(),
            if (_events.isNotEmpty)
              Text(
                '${_events.length} olay',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Feed body ───────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.glassBorder, width: 1),
              ),
              child: _events.isEmpty
                  ? _EmptyFeedPlaceholder()
                  : Column(
                      children: List.generate(
                        _events.length > 5 ? 5 : _events.length,
                        (i) => _ActivityRow(
                          event: _events[i],
                          isNew: i == 0,
                          showDivider:
                              i <
                              ((_events.length > 5 ? 5 : _events.length) - 1),
                          timeLabel: _formatTime(_events[i].timestamp),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyFeedPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'wifi_tethering',
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'Ekip aktivitesi bekleniyor…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single activity row ──────────────────────────────────────────────────────

class _ActivityRow extends StatefulWidget {
  final ActivityEvent event;
  final bool isNew;
  final bool showDivider;
  final String timeLabel;

  const _ActivityRow({
    required this.event,
    required this.isNew,
    required this.showDivider,
    required this.timeLabel,
  });

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    if (widget.isNew) {
      _entryController.forward();
    } else {
      _entryController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = Color(widget.event.iconColorHex);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          children: [
            Container(
              color: widget.isNew
                  ? AppTheme.primary.withAlpha(18)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(36),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iconColor.withAlpha(70),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: widget.event.iconName,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.event.title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isNew)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(50),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'YENİ',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.event.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.event.officerName != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'person',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 11,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.event.officerName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.event.badgeNumber?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '· ${widget.event.badgeNumber}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withAlpha(150),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Timestamp
                  const SizedBox(width: 8),
                  Text(
                    widget.timeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showDivider)
              Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.glassBorder,
                indent: 14,
                endIndent: 14,
              ),
          ],
        ),
      ),
    );
  }
}
