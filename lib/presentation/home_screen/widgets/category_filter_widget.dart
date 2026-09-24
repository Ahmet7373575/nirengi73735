import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Horizontal scroll pill filter chips — first active = filled, rest outlined.
/// Anatomy locked from reference image extraction.
class CategoryFilterWidget extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.glassSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
                  width: 1,
                ),
              ),
              child: Text(
                categories[i],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
