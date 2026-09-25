import 'dart:ui';
import '../../../core/app_export.dart';

/// Model for a team member entry shown in the panel.
class _TeamMember {
  final String name;
  final String badge;
  final String rank;
  final String team;
  final _ShiftStatus shiftStatus;
  final String lastGpsPing;
  final String location;
  final String avatarSeed;

  const _TeamMember({
    required this.name,
    required this.badge,
    required this.rank,
    required this.team,
    required this.shiftStatus,
    required this.lastGpsPing,
    required this.location,
    required this.avatarSeed,
  });
}

enum _ShiftStatus { onDuty, onBreak, offDuty, responding }

extension _ShiftStatusExt on _ShiftStatus {
  String get label {
    switch (this) {
      case _ShiftStatus.onDuty:
        return 'Görevde';
      case _ShiftStatus.onBreak:
        return 'Molada';
      case _ShiftStatus.offDuty:
        return 'İzinde';
      case _ShiftStatus.responding:
        return 'Müdahale';
    }
  }

  Color get color {
    switch (this) {
      case _ShiftStatus.onDuty:
        return const Color(0xFF22C55E);
      case _ShiftStatus.onBreak:
        return const Color(0xFFF59E0B);
      case _ShiftStatus.offDuty:
        return const Color(0xFF6B7280);
      case _ShiftStatus.responding:
        return const Color(0xFFEF4444);
    }
  }

  String get iconName {
    switch (this) {
      case _ShiftStatus.onDuty:
        return 'check_circle';
      case _ShiftStatus.onBreak:
        return 'coffee';
      case _ShiftStatus.offDuty:
        return 'do_not_disturb';
      case _ShiftStatus.responding:
        return 'directions_run';
    }
  }
}

class TeamMembersPanelWidget extends StatefulWidget {
  const TeamMembersPanelWidget({super.key});

  @override
  State<TeamMembersPanelWidget> createState() => _TeamMembersPanelWidgetState();
}

class _TeamMembersPanelWidgetState extends State<TeamMembersPanelWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  static const List<_TeamMember> _members = [
    _TeamMember(
      name: 'Ahmet Kaya',
      badge: 'P-1042',
      rank: 'Komiser',
      team: 'Alfa',
      shiftStatus: _ShiftStatus.onDuty,
      lastGpsPing: '2 dk önce',
      location: 'Kadıköy, İstanbul',
      avatarSeed: 'AK',
    ),
    _TeamMember(
      name: 'Fatma Demir',
      badge: 'P-2187',
      rank: 'Memur',
      team: 'Bravo',
      shiftStatus: _ShiftStatus.responding,
      lastGpsPing: '1 dk önce',
      location: 'Üsküdar, İstanbul',
      avatarSeed: 'FD',
    ),
    _TeamMember(
      name: 'Hasan Çelik',
      badge: 'P-0934',
      rank: 'Başkomiser',
      team: 'Alfa',
      shiftStatus: _ShiftStatus.onDuty,
      lastGpsPing: '5 dk önce',
      location: 'Beşiktaş, İstanbul',
      avatarSeed: 'HÇ',
    ),
    _TeamMember(
      name: 'Zeynep Arslan',
      badge: 'P-3301',
      rank: 'Memur',
      team: 'Charlie',
      shiftStatus: _ShiftStatus.onBreak,
      lastGpsPing: '12 dk önce',
      location: 'Şişli, İstanbul',
      avatarSeed: 'ZA',
    ),
    _TeamMember(
      name: 'Murat Yıldız',
      badge: 'P-1756',
      rank: 'Komiser Yrd.',
      team: 'Delta',
      shiftStatus: _ShiftStatus.offDuty,
      lastGpsPing: '3 sa önce',
      location: 'Son konum: Bakırköy',
      avatarSeed: 'MY',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  int get _onDutyCount => _members
      .where(
        (m) =>
            m.shiftStatus == _ShiftStatus.onDuty ||
            m.shiftStatus == _ShiftStatus.responding,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggleExpand,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              // Pulsing dot for active members
              _PulsingDot(color: const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Text(
                'Ekip Üyeleri',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(230),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(38),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$_onDutyCount aktif',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _isExpanded ? 0 : -0.5,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: Colors.white.withAlpha(120),
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Animated member list ─────────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: Column(
            children: List.generate(_members.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < _members.length - 1 ? 8 : 0,
                ),
                child: _MemberCard(member: _members[i]),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Pulsing dot indicator ────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withAlpha((128 + (127 * _anim.value)).round()),
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha((80 * _anim.value).round()),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual member card ───────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final _TeamMember member;
  const _MemberCard({required this.member});

  // Deterministic avatar color from badge string
  Color _avatarColor() {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];
    final idx = member.badge.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        member.shiftStatus == _ShiftStatus.onDuty ||
        member.shiftStatus == _ShiftStatus.responding;
    final avatarColor = _avatarColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withAlpha(14)
                : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: member.shiftStatus == _ShiftStatus.responding
                  ? const Color(0xFFEF4444).withAlpha(80)
                  : Colors.white.withAlpha(isActive ? 30 : 18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [avatarColor, avatarColor.withAlpha(160)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.avatarSeed,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Status dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: member.shiftStatus.color,
                        border: Border.all(
                          color: const Color(0xFF0F0F1A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(
                                isActive ? 230 : 160,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Shift status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: member.shiftStatus.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: member.shiftStatus.color.withAlpha(70),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName: member.shiftStatus.iconName,
                                color: member.shiftStatus.color,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                member.shiftStatus.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: member.shiftStatus.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${member.rank} · ${member.badge}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(100),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.team,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // GPS ping row
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: isActive
                              ? const Color(0xFF22C55E).withAlpha(200)
                              : Colors.white.withAlpha(60),
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            member.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(
                                isActive ? 140 : 80,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: Colors.white.withAlpha(60),
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          member.lastGpsPing,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withAlpha(80),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Contact actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ContactButton(
                    iconName: 'phone',
                    color: const Color(0xFF22C55E),
                    enabled: isActive,
                    onTap: isActive
                        ? () =>
                              _showContactSnackbar(context, member, 'Aranıyor')
                        : null,
                  ),
                  const SizedBox(height: 6),
                  _ContactButton(
                    iconName: 'assignment_ind',
                    color: const Color(0xFF3B82F6),
                    enabled: isActive,
                    onTap: isActive
                        ? () => _showContactSnackbar(
                            context,
                            member,
                            'Olay atandı',
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactSnackbar(
    BuildContext context,
    _TeamMember member,
    String action,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action: ${member.name} (${member.badge})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Small contact action button ──────────────────────────────────────────────
class _ContactButton extends StatelessWidget {
  final String iconName;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ContactButton({
    required this.iconName,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? color.withAlpha(30) : Colors.white.withAlpha(10),
          border: Border.all(
            color: enabled ? color.withAlpha(80) : Colors.white.withAlpha(20),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: CustomIconWidget(
          iconName: iconName,
          color: enabled ? color : Colors.white.withAlpha(50),
          size: 14,
        ),
      ),
    );
  }
}
