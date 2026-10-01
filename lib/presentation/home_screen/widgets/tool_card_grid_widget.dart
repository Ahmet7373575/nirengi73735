import 'dart:ui';

import '../../../core/app_export.dart';

class ToolModel {
  final String id;
  final String title;
  final String iconName;
  final Color color;
  final String category;
  final int noteCount;

  const ToolModel({
    required this.id,
    required this.title,
    required this.iconName,
    required this.color,
    required this.category,
    required this.noteCount,
  });
}

/// Core workflow only: the officer starts with a case, then prepares a
/// document or asks the assistant. Special incident types belong inside a case.
class ToolCardGridWidget extends StatelessWidget {
  final bool isTablet;
  final ValueChanged<String> onToolTap;

  const ToolCardGridWidget({
    super.key,
    required this.isTablet,
    required this.onToolTap,
  });

  static const _tools = [
    ToolModel(
      id: 'case_folders',
      title: 'Olay Dosyaları',
      iconName: 'folder_special',
      color: Color(0xFF3B82F6),
      category: 'Dosya',
      noteCount: 0,
    ),
    ToolModel(
      id: 'document',
      title: 'Tutanak / Bilgi Notu',
      iconName: 'description',
      color: Color(0xFF10B981),
      category: 'Belge',
      noteCount: 0,
    ),
    ToolModel(
      id: 'assistant',
      title: 'Çavuş’a Sor',
      iconName: 'smart_toy',
      color: Color(0xFF8B5CF6),
      category: 'Yardımcı',
      noteCount: 0,
    ),
    ToolModel(
      id: 'profile',
      title: 'Personel Profili',
      iconName: 'person_outline',
      color: Color(0xFFF59E0B),
      category: 'Hesap',
      noteCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final columns = isTablet ? 4 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ana işlemler', style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isTablet ? 1.35 : 1.45,
          ),
          itemBuilder: (context, index) => _ToolCard(
            tool: _tools[index],
            onTap: () => onToolTap(_tools[index].id),
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolModel tool;
  final VoidCallback onTap;
  const _ToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tool.color.withAlpha(26),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tool.color.withAlpha(64)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(tool.iconName), color: tool.color, size: 25),
                  const Spacer(),
                  Text(tool.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(tool.category, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );

  IconData _iconFor(String name) {
    switch (name) {
      case 'folder_special': return Icons.folder_special_outlined;
      case 'description': return Icons.description_outlined;
      case 'smart_toy': return Icons.smart_toy_outlined;
      default: return Icons.person_outline;
    }
  }
}
