import 'dart:ui';

import '../../../core/app_export.dart';

/// Bottom action bar — Save Draft + Generate PDF buttons.
/// Shows loading states with locked button width.
class NoteActionBarWidget extends StatelessWidget {
  final bool isSaving;
  final bool isGeneratingPdf;
  final VoidCallback onSaveDraft;
  final VoidCallback onGeneratePdf;

  const NoteActionBarWidget({
    super.key,
    required this.isSaving,
    required this.isGeneratingPdf,
    required this.onSaveDraft,
    required this.onGeneratePdf,
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
              // ── Section label ─────────────────────────────────────
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'picture_as_pdf',
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Belge İşlemleri',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── PDF info row ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A4 formatında, QR doğrulama ve imza alanıyla PDF oluşturulacak.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(179),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Action buttons ────────────────────────────────────
              Row(
                children: [
                  // Save Draft
                  Expanded(
                    child: _ActionButton(
                      label: 'Taslak Kaydet',
                      iconName: 'save_outlined',
                      isLoading: isSaving,
                      isPrimary: false,
                      onTap: onSaveDraft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Generate PDF
                  Expanded(
                    flex: 2,
                    child: _ActionButton(
                      label: 'PDF Oluştur',
                      iconName: 'picture_as_pdf',
                      isLoading: isGeneratingPdf,
                      isPrimary: true,
                      onTap: onGeneratePdf,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Share row ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'share',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'PDF oluşturulduktan sonra paylaş, yazdır veya AirDrop',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final String iconName;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.iconName,
    required this.isLoading,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(
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
    final color = widget.isPrimary ? AppTheme.primary : AppTheme.glassSurface;
    final borderColor = widget.isPrimary
        ? AppTheme.primary
        : AppTheme.glassBorder;
    final textColor = widget.isPrimary
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppTheme.primary : AppTheme.glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: widget.iconName,
                        color: textColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
