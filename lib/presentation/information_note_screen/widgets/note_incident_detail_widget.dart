import 'dart:ui';

import '../../../core/app_export.dart';

/// Incident Detail group — Konu + Açıklama with mic dictation button.
class NoteIncidentDetailWidget extends StatefulWidget {
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final VoidCallback onMicTap;

  const NoteIncidentDetailWidget({
    super.key,
    required this.subjectController,
    required this.descriptionController,
    required this.onMicTap,
  });

  @override
  State<NoteIncidentDetailWidget> createState() =>
      _NoteIncidentDetailWidgetState();
}

class _NoteIncidentDetailWidgetState extends State<NoteIncidentDetailWidget>
    with SingleTickerProviderStateMixin {
  late FocusNode _subjectFocus;
  late FocusNode _descFocus;
  late AnimationController _focusController;
  late Animation<double> _subjectBorder;
  late Animation<double> _descBorder;

  @override
  void initState() {
    super.initState();
    _subjectFocus = FocusNode();
    _descFocus = FocusNode();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _subjectBorder = Tween<double>(
      begin: 0.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _focusController, curve: Curves.easeOut));
    _descBorder = Tween<double>(
      begin: 0.15,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _focusController, curve: Curves.easeOut));
    _subjectFocus.addListener(() => setState(() {}));
    _descFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _subjectFocus.dispose();
    _descFocus.dispose();
    _focusController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(bool focused) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: focused ? AppTheme.primary : Colors.white.withAlpha(38),
      width: focused ? 1.5 : 1,
    ),
  );

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
              // ── Section header ────────────────────────────────────
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'subject',
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Olay Detayları',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // ── Mic button ──────────────────────────────────
                  GestureDetector(
                    onTap: widget.onMicTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(38),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.secondary.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'mic',
                            color: AppTheme.secondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sesli Dikta',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Subject field ─────────────────────────────────────
              TextFormField(
                controller: widget.subjectController,
                focusNode: _subjectFocus,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Konu gerekli' : null,
                decoration: InputDecoration(
                  labelText: 'Konu',
                  labelStyle: TextStyle(
                    color: _subjectFocus.hasFocus
                        ? AppTheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: CustomIconWidget(
                      iconName: 'notes',
                      color: _subjectFocus.hasFocus
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 44),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                  border: _border(false),
                  enabledBorder: _border(false),
                  focusedBorder: _border(true),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.error,
                      width: 1,
                    ),
                  ),
                  errorStyle: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 11,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Description multiline ─────────────────────────────
              TextFormField(
                controller: widget.descriptionController,
                focusNode: _descFocus,
                maxLines: 5,
                minLines: 4,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Açıklama gerekli' : null,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  alignLabelWithHint: true,
                  labelStyle: TextStyle(
                    color: _descFocus.hasFocus
                        ? AppTheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                  border: _border(false),
                  enabledBorder: _border(false),
                  focusedBorder: _border(true),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.error,
                      width: 1,
                    ),
                  ),
                  errorStyle: const TextStyle(
                    color: AppTheme.error,
                    fontSize: 11,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintText:
                      'Olay detaylarını buraya girin veya sesli dikta kullanın...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(153),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
