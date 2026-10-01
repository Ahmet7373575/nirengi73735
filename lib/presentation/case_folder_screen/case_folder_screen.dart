import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../services/incident_service.dart';
import '../../theme/app_theme.dart';

class CaseFolderScreen extends StatefulWidget {
  const CaseFolderScreen({super.key});

  @override
  State<CaseFolderScreen> createState() => _CaseFolderScreenState();
}

class _CaseFolderScreenState extends State<CaseFolderScreen> {
  final _searchController = TextEditingController();
  List<IncidentModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await IncidentService.instance.fetchMyIncidents(limit: 100);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<IncidentModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          (item.location ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Olay Dosyaları'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.rapidIncidentScreen),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Yeni dosya'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Dosya, olay veya konum ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              _EmptyCases(onCreate: () => context.push(AppRoutes.rapidIncidentScreen))
            else
              ...items.map((item) => _CaseCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final IncidentModel item;
  const _CaseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.incidentStatus.replaceAll('_', ' ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.caseDetailScreen, extra: item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title.isEmpty ? 'Başlıksız olay' : item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(item.location ?? 'Konum belirtilmedi',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(status, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCases extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCases({required this.onCreate});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(Icons.folder_open, size: 52, color: Colors.white54),
            const SizedBox(height: 12),
            const Text('Henüz olay dosyası yok'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('İlk dosyayı oluştur'),
            ),
          ],
        ),
      );
}
