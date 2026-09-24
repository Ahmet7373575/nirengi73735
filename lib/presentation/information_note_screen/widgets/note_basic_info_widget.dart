import 'dart:ui';

import '../../../core/app_export.dart';

/// Basic Info group card — Tarih, Saat, Personel, Sicil, Ekip.
/// Glassmorphism card with grouped fields. Tablet: 2-column layout.
class NoteBasicInfoWidget extends StatelessWidget {
  final bool isTablet;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController personnelController;
  final TextEditingController badgeController;
  final TextEditingController teamController;

  const NoteBasicInfoWidget({
    super.key,
    required this.isTablet,
    required this.dateController,
    required this.timeController,
    required this.personnelController,
    required this.badgeController,
    required this.teamController,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassFormCard(
      sectionIcon: 'assignment',
      sectionTitle: 'Temel Bilgiler',
      child: Column(
        children: [
          // ── Date + Time row ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _GlassFormField(
                  controller: dateController,
                  label: 'Tarih',
                  iconName: 'calendar_today',
                  keyboardType: TextInputType.datetime,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Tarih gerekli' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassFormField(
                  controller: timeController,
                  label: 'Saat',
                  iconName: 'access_time',
                  keyboardType: TextInputType.datetime,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Saat gerekli' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Personnel full width ────────────────────────────────────
          _GlassFormField(
            controller: personnelController,
            label: 'Personel Adı Soyadı',
            iconName: 'person_outline',
            validator: (v) =>
                v == null || v.isEmpty ? 'Personel adı gerekli' : null,
          ),
          const SizedBox(height: 12),

          // ── Badge + Team row ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _GlassFormField(
                  controller: badgeController,
                  label: 'Sicil No',
                  iconName: 'badge',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Sicil gerekli' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassFormField(
                  controller: teamController,
                  label: 'Ekip',
                  iconName: 'group',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Duty Info group card — Görev Yeri, GPS.
class NoteDutyInfoWidget extends StatelessWidget {
  final bool isTablet;
  final TextEditingController dutyLocationController;
  final TextEditingController gpsController;
  final VoidCallback onGpsTap;

  const NoteDutyInfoWidget({
    super.key,
    required this.isTablet,
    required this.dutyLocationController,
    required this.gpsController,
    required this.onGpsTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassFormCard(
      sectionIcon: 'place',
      sectionTitle: 'Görev Bilgileri',
      child: Column(
        children: [
          _GlassFormField(
            controller: dutyLocationController,
            label: 'Görev Yeri / Adres',
            iconName: 'place',
            validator: (v) =>
                v == null || v.isEmpty ? 'Görev yeri gerekli' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlassFormField(
                  controller: gpsController,
                  label: 'GPS Koordinatları',
                  iconName: 'location_on',
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onGpsTap,
                child: Container(
                  width: 52,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'my_location',
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared internal components — GlassFormCard + GlassFormField
// ══════════════════════════════════════════════════════════════════════════════

/// Glassmorphism card wrapper for form sections.
class _GlassFormCard extends StatelessWidget {
  final String sectionIcon;
  final String sectionTitle;
  final Widget child;

  const _GlassFormCard({
    required this.sectionIcon,
    required this.sectionTitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: sectionIcon,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism form field (V5) — animated focus border.
class _GlassFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String iconName;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final int maxLines;

  const _GlassFormField({
    required this.controller,
    required this.label,
    required this.iconName,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  State<_GlassFormField> createState() => _GlassFormFieldState();
}

class _GlassFormFieldState extends State<_GlassFormField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _borderAnim;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderAnim = Tween<double>(
      begin: 0.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = _focusNode.hasFocus;

    return AnimatedBuilder(
      animation: _borderAnim,
      builder: (context, _) {
        return TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontFeatures: widget.keyboardType == TextInputType.number
                ? const [FontFeature.tabularFigures()]
                : null,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: isFocused
                  ? AppTheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: CustomIconWidget(
                iconName: widget.iconName,
                color: isFocused
                    ? AppTheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            filled: true,
            fillColor: Colors.white.withAlpha(13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(38),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(38),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppTheme.primary.withOpacity(_borderAnim.value),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            errorStyle: const TextStyle(color: AppTheme.error, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        );
      },
    );
  }
}