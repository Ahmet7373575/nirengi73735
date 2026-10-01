import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Compact template selector. The full list is opened only when requested,
/// keeping the field screen usable with one hand.
class NoteTemplateSelectorWidget extends StatelessWidget {
  final List<String> templates;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const NoteTemplateSelectorWidget({
    super.key,
    required this.templates,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeIndex = selectedIndex.clamp(0, templates.length - 1).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: DropdownButtonFormField<int>(
        value: safeIndex,
        isExpanded: true,
        dropdownColor: AppTheme.surfaceDark,
        icon: const Icon(Icons.expand_more, color: Colors.white70),
        decoration: InputDecoration(
          labelText: 'Belge türü',
          prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primary),
          filled: true,
          fillColor: AppTheme.glassSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.glassBorder),
          ),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        items: [
          for (var i = 0; i < templates.length; i++)
            DropdownMenuItem<int>(value: i, child: Text(templates[i])),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}
