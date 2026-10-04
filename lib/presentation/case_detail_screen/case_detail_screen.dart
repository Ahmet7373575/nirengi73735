import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../services/case_folder_service.dart';
import '../../services/incident_service.dart';
import '../../theme/app_theme.dart';

class CaseDetailScreen extends StatefulWidget {
  final IncidentModel incident;
  const CaseDetailScreen({super.key, required this.incident});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final _service = CaseFolderService.instance;
  List<Map<String, dynamic>> _persons = [];
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _media = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  IncidentModel get incident => widget.incident;

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    try {
      final values = await Future.wait([
        _service.persons(incident.id ?? incident.localId),
        _service.vehicles(incident.id ?? incident.localId),
        _service.documents(incident.id ?? incident.localId),
        _service.media(incident.id ?? incident.localId),
        _service.history(incident.id ?? incident.localId),
      ]);
      if (!mounted) return;
      setState(() {
        _persons = values[0];
        _vehicles = values[1];
        _documents = values[2];
        _media = values[3];
        _history = values[4];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPerson() async {
    final data = await _personDialog();
    if (data == null) return;
    try {
      await _service.addPerson(incidentId: incident.id!, role: data['role']!, fullName: data['full_name']!, nationalId: data['national_id'], phone: data['phone']);
      await _loadRelated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Şahıs kaydedilemedi: $e')));
    }
  }

  Future<void> _addVehicle() async {
    final data = await _vehicleDialog();
    if (data == null) return;
    try {
      await _service.addVehicle(incidentId: incident.id!, plate: data['plate'], makeModel: data['make_model'], color: data['color']);
      await _loadRelated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Araç kaydedilemedi: $e')));
    }
  }

  Future<Map<String, String>?> _personDialog() async {
    final name = TextEditingController();
    final role = TextEditingController(text: 'bilgi_sahibi');
    final id = TextEditingController();
    final phone = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şahıs ekle'),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: role, decoration: const InputDecoration(labelText: 'Sıfat (müşteki/şüpheli/bilgi sahibi)')),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad')),
          TextField(controller: id, decoration: const InputDecoration(labelText: 'T.C. kimlik no')),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefon')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () { if (name.text.trim().isNotEmpty) Navigator.pop(context, {'role': role.text.trim(), 'full_name': name.text.trim(), 'national_id': id.text.trim(), 'phone': phone.text.trim()}); }, child: const Text('Kaydet')),
        ],
      ),
    );
    name.dispose(); role.dispose(); id.dispose(); phone.dispose();
    return result;
  }

  Future<Map<String, String>?> _vehicleDialog() async {
    final plate = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Araç ekle'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: plate, decoration: const InputDecoration(labelText: 'Plaka')),
          TextField(controller: model, decoration: const InputDecoration(labelText: 'Marka / model')),
          TextField(controller: color, decoration: const InputDecoration(labelText: 'Renk')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, {'plate': plate.text.trim(), 'make_model': model.text.trim(), 'color': color.text.trim()}), child: const Text('Kaydet')),
        ],
      ),
    );
    plate.dispose(); model.dispose(); color.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(incident.title.isEmpty ? 'Olay Dosyası' : incident.title),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Genel'), Tab(text: 'Şahıslar'), Tab(text: 'Araçlar'),
            Tab(text: 'Evraklar'), Tab(text: 'Medya'), Tab(text: 'Geçmiş'),
          ]),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                _Overview(incident: incident),
                _EntityList(items: _persons, empty: 'Şahıs eklenmedi', action: 'Şahıs ekle', onAdd: _addPerson, titleKey: 'full_name', subtitleKey: 'role'),
                _EntityList(items: _vehicles, empty: 'Araç eklenmedi', action: 'Araç ekle', onAdd: _addVehicle, titleKey: 'plate', subtitleKey: 'make_model'),
                _Documents(incident: incident, count: _documents.length),
                _EntityList(items: _media, empty: 'Medya eklenmedi', action: 'Fotoğraf ekle', onAdd: () => _message('Fotoğraf ekleme için kamera/storage bağlantısı eklenecek.'), titleKey: 'file_name', subtitleKey: 'media_type'),
                _HistoryTab(items: _history),
              ]),
      ),
    );
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _Overview extends StatelessWidget {
  final IncidentModel incident;
  const _Overview({required this.incident});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    _InfoTile(label: 'Olay başlığı', value: incident.title),
    _InfoTile(label: 'Konum', value: incident.location ?? 'Belirtilmedi'),
    _InfoTile(label: 'Durum', value: incident.incidentStatus.replaceAll('_', ' ')),
    _InfoTile(label: 'Öncelik', value: incident.priority),
    _InfoTile(label: 'Açıklama', value: incident.description),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: () => context.push(AppRoutes.informationNoteScreen, extra: incident), icon: const Icon(Icons.description_outlined), label: const Text('Bu dosyaya evrak hazırla')),
  ]);
}

class _EntityList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String empty;
  final String action;
  final VoidCallback onAdd;
  final String titleKey;
  final String subtitleKey;
  const _EntityList({required this.items, required this.empty, required this.action, required this.onAdd, required this.titleKey, required this.subtitleKey});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(action))),
    const SizedBox(height: 8),
    if (items.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(empty)))
    else ...items.map((item) => Card(child: ListTile(leading: const Icon(Icons.badge_outlined, color: AppTheme.primary), title: Text(item[titleKey]?.toString().isNotEmpty == true ? item[titleKey].toString() : 'Belirtilmedi'), subtitle: Text(item[subtitleKey]?.toString() ?? '')))),
  ]);
}

class _Documents extends StatelessWidget {
  final IncidentModel incident;
  final int count;
  const _Documents({required this.incident, required this.count});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text('$count belge', style: const TextStyle(color: Colors.white70)),
    const SizedBox(height: 12),
    Card(child: ListTile(leading: const Icon(Icons.note_alt_outlined, color: AppTheme.primary), title: const Text('Yeni tutanak veya bilgi notu'), subtitle: const Text('Olay bilgileri forma aktarılır'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(AppRoutes.informationNoteScreen))),
  ]);
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)), const SizedBox(height: 5), Text(value.isEmpty ? 'Belirtilmedi' : value)])));
}

class _HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _HistoryTab({required this.items});
  @override
  Widget build(BuildContext context) => items.isEmpty ? const Center(child: Text('Dosya geçmişi henüz boş.')) : ListView(padding: const EdgeInsets.all(16), children: items.map((item) => ListTile(leading: const Icon(Icons.history), title: Text(item['action']?.toString() ?? 'İşlem'), subtitle: Text(item['description']?.toString() ?? ''))).toList());
}
