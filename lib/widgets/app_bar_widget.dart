import 'dart:ui';

import '../core/app_export.dart';

/// Glassmorphism AppBar (V3) — BackdropFilter blur, transparent, content
/// shows through. LOCKED — do not remove BackdropFilter.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final bool transparent;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.transparent = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withAlpha(153),
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(26), width: 1),
            ),
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'arrow_back_ios_new',
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else if (leading != null)
                leading!
              else
                const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
