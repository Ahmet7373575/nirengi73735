import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get _officerName {
    try {
      final user = AuthService.instance.currentUser;
      final meta = user?.userMetadata ?? {};
      final fullName = (meta['full_name'] as String?)?.trim() ?? '';
      if (fullName.isNotEmpty) return fullName.split(' ').first;
      final email = user?.email ?? '';
      return email.isNotEmpty ? email.split('@').first : 'Memur';
    } catch (_) {
      return 'Memur';
    }
  }

  void _open(String id) {
    switch (id) {
      case 'cases':
        context.push(AppRoutes.caseFolderScreen);
        break;
      case 'note':
        context.go(AppRoutes.informationNoteScreen);
        break;
      case 'tutanak':
        context.push(AppRoutes.rapidIncidentScreen);
        break;
      case 'assistant':
        context.go(AppRoutes.aiAssistantScreen);
        break;
      case 'profile':
        context.go(AppRoutes.profileScreen);
        break;
      case 'tools':
        context.push(AppRoutes.fieldToolsScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _WelcomeHeader(name: _officerName, height: size.height * .39)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -34),
                  child: _FeaturePanel(onOpen: _open),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24 + bottom + 76)),
            ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String name;
  final double height;
  const _WelcomeHeader({required this.name, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height.clamp(310.0, 405.0).toDouble(),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 18, left: 24, right: 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B86C9), Color(0xFF4F9AD0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 27)),
                IconButton(onPressed: () => context.go(AppRoutes.profileScreen), icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 27)),
              ],
            ),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🛡️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 8),
              Text('bekçi', style: TextStyle(color: Colors.white, fontSize: 54, height: .9, fontWeight: FontWeight.w800, letterSpacing: -2, shadows: const [Shadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))])),
            ]),
            const SizedBox(height: 22),
            Text('Hoş Geldin, ${name.toLowerCase()}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('İstediğin işlemi seç, saha görevini\ndaha hızlı ve düzenli tamamla!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, height: 1.35, fontWeight: FontWeight.w500)),
            const SizedBox(height: 42),
          ],
        ),
      );
}

class _FeaturePanel extends StatelessWidget {
  final ValueChanged<String> onOpen;
  const _FeaturePanel({required this.onOpen});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, -5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(left: 5, bottom: 14), child: Text('Hızlı erişim', style: TextStyle(color: Color(0xFF2C245F), fontSize: 18, fontWeight: FontWeight.w800))),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.08,
            children: [
              _FeatureCard(title: 'Olay Dosyaları', subtitle: 'Dosya oluştur, şahıs ve araçları takip et', icon: Icons.folder_special_outlined, color: const Color(0xFFF0ECF9), accent: const Color(0xFF57338D), onTap: () => onOpen('cases')),
              _FeatureCard(title: 'Bilgi Notu', subtitle: 'Resmi bilgi notunu hızlıca hazırla', icon: Icons.description_outlined, color: const Color(0xFFFFF0E6), accent: const Color(0xFFE98A2A), onTap: () => onOpen('note')),
              _FeatureCard(title: 'Tutanak Hazırla', subtitle: 'Olayı kaydet ve tutanağa dönüştür', icon: Icons.edit_document, color: const Color(0xFFEEF5D8), accent: const Color(0xFF6BA847), onTap: () => onOpen('tutanak')),
              _FeatureCard(title: 'Bekçi’ye Sor', subtitle: 'Mevzuat ve dosya yardımcın hazır', icon: Icons.shield_outlined, color: const Color(0xFFF0ECF9), accent: const Color(0xFF57338D), onTap: () => onOpen('assistant')),
              _FeatureCard(title: 'Saha Araçları', subtitle: 'Ceza, nöbet, not, kamera ve QR', icon: Icons.widgets_outlined, color: const Color(0xFFEAF4FC), accent: const Color(0xFF276A9A), onTap: () => onOpen('tools')),
            ],
          ),
          const SizedBox(height: 16),
          _PromoCard(onTap: () => onOpen('profile')),
        ]),
      );
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accent;
  final VoidCallback onTap;
  const _FeatureCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 17, 13, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: accent, size: 30),
              const Spacer(),
              Text(title, style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: accent.withAlpha(210), fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _PromoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PromoCard({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF63379B),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 112,
            child: Stack(children: [
              Positioned(right: -20, top: -28, child: Icon(Icons.shield_rounded, size: 180, color: Colors.white.withAlpha(20))),
              Padding(padding: const EdgeInsets.fromLTRB(18, 18, 130, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Saha görevinin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('güvenli yardımcısı', style: TextStyle(color: Color(0xFFFFB52A), fontSize: 19, fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFA918), borderRadius: BorderRadius.circular(18)), child: const Text('Profilini düzenle', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
              ])),
            ]),
          ),
        ),
      );
}
