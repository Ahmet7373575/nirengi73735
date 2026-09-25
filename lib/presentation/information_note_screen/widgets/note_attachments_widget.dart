import 'dart:ui';

import '../../../core/app_export.dart';

/// Attachments group — photo and file attachment actions with preview slots.
class NoteAttachmentsWidget extends StatefulWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onFileTap;

  const NoteAttachmentsWidget({
    super.key,
    required this.onCameraTap,
    required this.onFileTap,
  });

  @override
  State<NoteAttachmentsWidget> createState() => _NoteAttachmentsWidgetState();
}

class _NoteAttachmentsWidgetState extends State<NoteAttachmentsWidget> {
  // TODO: Replace with [Riverpod/Bloc] for production
  // Mock attached photos — in production these come from camera/picker
  final List<Map<String, dynamic>> _attachments = [
    {
      'type': 'photo',
      'label': 'Olay yeri fotoğrafı 1',
      'time': '13:38',
      'hasGps': true,
    },
    {
      'type': 'photo',
      'label': 'Araç plaka fotoğrafı',
      'time': '13:40',
      'hasGps': true,
    },
  ];

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
                    iconName: 'attach_file',
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ekler',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_attachments.length} ek',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Action buttons row ────────────────────────────────
              Row(
                children: [
                  _AttachButton(
                    icon: 'camera_alt',
                    label: 'Fotoğraf Çek',
                    color: AppTheme.primary,
                    onTap: widget.onCameraTap,
                  ),
                  const SizedBox(width: 12),
                  _AttachButton(
                    icon: 'attach_file',
                    label: 'Dosya Ekle',
                    color: AppTheme.secondary,
                    onTap: widget.onFileTap,
                  ),
                ],
              ),

              // ── Attachment previews ───────────────────────────────
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...List.generate(_attachments.length, (i) {
                  final att = _attachments[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withAlpha(26),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(38),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'camera_alt',
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                att['label'] as String,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    att['time'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                  if (att['hasGps'] == true) ...[
                                    const SizedBox(width: 6),
                                    CustomIconWidget(
                                      iconName: 'location_on',
                                      color: AppTheme.success,
                                      size: 10,
                                    ),
                                    Text(
                                      ' GPS',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.success,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => _attachments.removeAt(i));
                          },
                          child: CustomIconWidget(
                            iconName: 'delete_outline',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(31),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(77), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(iconName: icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
