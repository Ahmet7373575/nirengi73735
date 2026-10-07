import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  String _text(dynamic value) => value?.toString().trim().isNotEmpty == true ? value.toString() : 'Belirtilmedi';

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
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        _message('Dosya ilişkileri yüklenemedi: $error');
      }
    }
  }

  Future<void> _addPerson() async {
    final data = await _personDialog();
    if (data == null) return;
    final incidentId = incident.id ?? incident.localId;
    try {
      await _service.addPerson(incidentId: incidentId, role: data['role']!, fullName: data['full_name']!, nationalId: data['national_id'], phone: data['phone'], address: data['address'], notes: data['notes']);
      await _service.addActivity(incidentId: incidentId, action: 'Şahıs Eklendi', description: data['full_name']!);
      await _loadRelated();
    } catch (error) {
      _message('Şahıs kaydedilemedi: $error');
    }
  }

  Future<void> _addVehicle() async {
    final data = await _vehicleDialog();
    if (data == null) return;
    final incidentId = incident.id ?? incident.localId;
    try {
      await _service.addVehicle(incidentId: incidentId, plate: data['plate'], makeModel: data['make_model'], color: data['color'], ownerName: data['owner_name'], notes: data['notes']);
      await _service.addActivity(incidentId: incidentId, action: 'Araç Eklendi', description: data['plate'] ?? 'Araç');
      await _loadRelated();
    } catch (error) {
      _message('Araç kaydedilemedi: $error');
    }
  }

  Future<void> _addMedia() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(child: Wrap(children: [
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Kamera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeriden seç'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
      ])),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, imageQuality: 82, maxWidth: 2200);
    if (file == null) return;
    final incidentId = incident.id ?? incident.localId;
    try {
      Position? position;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition();
      }
      await _service.addMedia(incidentId: incidentId, fileName: file.name, bytes: await file.readAsBytes(), sourcePath: file.path, latitude: position?.latitude, longitude: position?.longitude);
      await _service.addActivity(incidentId: incidentId, action: 'Medya Eklendi', description: file.name);
      await _loadRelated();
      _message('Fotoğraf dosyaya eklendi.');
    } catch (error) {
      _message('Fotoğraf eklenemedi. Storage bucket veya izinleri kontrol edin: $error');
    }
  }

  Future<void> _exportZip() async {
    final archive = Archive();
    void addText(String name, String value) {
      final bytes = utf8.encode(value);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    addText('00_Paket_Bilgisi.txt', 'BEKÇİ BİLGİ NOTU\nOlay Dosyası: ${incident.title}\nOluşturma: ${DateTime.now().toIso8601String()}');
    addText('01_Olay_Bilgileri.txt', 'Başlık: ${incident.title}\nDurum: ${incident.incidentStatus}\nÖncelik: ${incident.priority}\nKonum: ${_text(incident.location)}\n\n${incident.description}');
    addText('02_Sahislar.txt', _persons.asMap().entries.map((e) => '${e.key + 1}. ${_text(e.value['full_name'])} • ${_text(e.value['role'])}\nT.C.: ${_text(e.value['national_id'])}\nTelefon: ${_text(e.value['phone'])}\nAdres: ${_text(e.value['address'])}').join('\n\n'));
    addText('03_Araclar.txt', _vehicles.asMap().entries.map((e) => '${e.key + 1}. ${_text(e.value['plate'])} • ${_text(e.value['make_model'])} • ${_text(e.value['color'])}').join('\n'));
    addText('04_Evraklar.txt', _documents.asMap().entries.map((e) => '${e.key + 1}. ${_text(e.value['title'])} • ${_text(e.value['document_type'])}').join('\n'));
    addText('05_Zaman_Cizelgesi.txt', _history.map((e) => '${_text(e['created_at'])} • ${_text(e['action'])}: ${_text(e['description'])}').join('\n'));
    addText('06_Medya.txt', _media.map((e) => '${_text(e['file_name'])}: ${_text(e['file_path'])}').join('\n'));
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) return _message('ZIP oluşturulamadı.');
    final dir = await getTemporaryDirectory();
    final safeTitle = incident.title.isEmpty ? 'olay-dosyasi' : incident.title.replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ -]'), '_');
    final file = File('${dir.path}/$safeTitle.zip');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'Bekçi Bilgi Notu olay dosyası');
  }

  Future<Map<String, String>?> _personDialog() async {
    final role = TextEditingController(text: 'bilgi_sahibi');
    final name = TextEditingController();
    final id = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<Map<String, String>>(context: context, builder: (context) => AlertDialog(
      title: const Text('Şahıs ekle'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: role, decoration: const InputDecoration(labelText: 'Sıfat (müşteki/şüpheli/bilgi sahibi)')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad')),
        TextField(controller: id, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'T.C. kimlik no')),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')),
        TextField(controller: address, decoration: const InputDecoration(labelText: 'İkamet adresi')),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Not')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: () { if (name.text.trim().isNotEmpty) Navigator.pop(context, {'role': role.text.trim(), 'full_name': name.text.trim(), 'national_id': id.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(), 'notes': notes.text.trim()}); }, child: const Text('Kaydet')),
      ],
    ));
    for (final controller in [role, name, id, phone, address, notes]) { controller.dispose(); }
    return result;
  }

  Future<Map<String, String>?> _vehicleDialog() async {
    final plate = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();
    final owner = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<Map<String, String>>(context: context, builder: (context) => AlertDialog(
      title: const Text('Araç ekle'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: plate, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Plaka')),
        TextField(controller: model, decoration: const InputDecoration(labelText: 'Marka / model')),
        TextField(controller: color, decoration: const InputDecoration(labelText: 'Renk')),
        TextField(controller: owner, decoration: const InputDecoration(labelText: 'Sahibi')),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Not')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: () { if (plate.text.trim().isNotEmpty) Navigator.pop(context, {'plate': plate.text.trim().toUpperCase(), 'make_model': model.text.trim(), 'color': color.text.trim(), 'owner_name': owner.text.trim(), 'notes': notes.text.trim()}); }, child: const Text('Kaydet')),
      ],
    ));
    for (final controller in [plate, model, color, owner, notes]) { controller.dispose(); }
    return result;
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(title: Text(incident.title.isEmpty ? 'Olay Dosyası' : incident.title), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Genel'), Tab(text: 'Şahıslar'), Tab(text: 'Araçlar'), Tab(text: 'Evraklar'), Tab(text: 'Medya'), Tab(text: 'Geçmiş')])),
        body: _loading ? const Center(child: CircularProgressIndicator()) : TabBarView(children: [
          _Overview(incident: incident, onExport: _exportZip),
          _EntityList(items: _persons, empty: 'Şahıs eklenmedi', action: 'Şahıs ekle', onAdd: _addPerson, titleKey: 'full_name', subtitleKey: 'role'),
          _EntityList(items: _vehicles, empty: 'Araç eklenmedi', action: 'Araç ekle', onAdd: _addVehicle, titleKey: 'plate', subtitleKey: 'make_model'),
          _Documents(incident: incident, documents: _documents),
          _MediaList(items: _media, onAdd: _addMedia),
          _HistoryTab(items: _history),
        ]),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onExport;
  const _Overview({required this.incident, required this.onExport});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    _InfoTile(label: 'Olay başlığı', value: incident.title),
    _InfoTile(label: 'Olay türü', value: incident.incidentType ?? 'Belirtilmedi'),
    _InfoTile(label: 'Suç adı', value: incident.crimeName ?? 'Belirtilmedi'),
    _InfoTile(label: 'Soruşturma no', value: incident.investigationNumber ?? 'Belirtilmedi'),
    _InfoTile(label: 'Mahalle', value: incident.neighborhood ?? 'Belirtilmedi'),
    _InfoTile(label: 'Konum', value: incident.location ?? 'Belirtilmedi'),
    _InfoTile(label: 'Durum', value: incident.incidentStatus.replaceAll('_', ' ')),
    _InfoTile(label: 'Öncelik', value: incident.priority),
    _InfoTile(label: 'Açıklama', value: incident.description),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: () => context.push(AppRoutes.informationNoteScreen, extra: incident), icon: const Icon(Icons.description_outlined), label: const Text('Bu dosyaya evrak hazırla')),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: onExport, icon: const Icon(Icons.folder_zip_outlined), label: const Text('Dosyayı ZIP olarak paylaş')),
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
  final List<Map<String, dynamic>> documents;
  const _Documents({required this.incident, required this.documents});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text('${documents.length} belge', style: const TextStyle(color: Colors.white70)),
    const SizedBox(height: 12),
    Card(child: ListTile(leading: const Icon(Icons.note_alt_outlined, color: AppTheme.primary), title: const Text('Yeni tutanak veya bilgi notu'), subtitle: const Text('Olay bilgileri forma aktarılır'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(AppRoutes.informationNoteScreen, extra: incident))),
    ...documents.map((document) => Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(document['title']?.toString() ?? 'Evrak'),
            subtitle: Text('${document['document_type'] ?? 'Belge'} • ${document['created_at'] ?? ''}'),
          ),
        )),
  ]);
}

class _MediaList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onAdd;
  const _MediaList({required this.items, required this.onAdd});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Fotoğraf ekle'))),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Medya eklenmedi')))
          else
            ...items.map((item) => Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ((item['file_path']?.toString() ?? '').startsWith('http'))
                      Image.network(item['file_path'].toString(), height: 190, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 80, child: Center(child: Icon(Icons.broken_image_outlined))))
                    else
                      const SizedBox(height: 80, child: Center(child: Icon(Icons.image_outlined))),
                    ListTile(title: Text(item['file_name']?.toString() ?? 'Fotoğraf'), subtitle: Text('GPS: ${item['latitude'] ?? '—'}, ${item['longitude'] ?? '—'}')),
                  ]),
                )),
        ],
      );
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
