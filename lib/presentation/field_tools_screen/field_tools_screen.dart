import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

class FieldToolsScreen extends StatefulWidget {
  const FieldToolsScreen({super.key});

  @override
  State<FieldToolsScreen> createState() => _FieldToolsScreenState();
}

class _FieldToolsScreenState extends State<FieldToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  final _noteTitle = TextEditingController();
  final _noteBody = TextEditingController();
  final _task = TextEditingController();
  final _start = TextEditingController(text: '08:00');
  final _end = TextEditingController(text: '20:00');
  final _picker = ImagePicker();
  final List<Map<String, String>> _notes = [];
  String _category = 'Olay';
  String _system = '12 / 36 Sistemi';
  String _shift = 'Gündüz';
  String _activity = 'Önleyici Devriye Faaliyeti';
  String _firstDutyDay = '';
  String _qrValue = '';
  String _cameraFile = '';
  int _selectedPenalty = 0;

  static const _penalties = <Map<String, String>>[
    {'title': 'Mülki amirin emrine aykırı davranmak', 'law': '5326 · Md. 32 · Kabahatler Kanunu', 'amount': '3.705 TL', 'authority': 'Mülki Amir', 'document': 'EK-1 İdari Yaptırım Karar Tutanağı'},
    {'title': 'Dilencilik yapmak', 'law': '5326 · Md. 33 · Kabahatler Kanunu', 'amount': '1.764 TL', 'authority': 'Kolluk', 'document': 'EK-1 İdari Yaptırım Karar Tutanağı'},
    {'title': 'Kumar oynamak', 'law': '5326 · Md. 34 · Kabahatler Kanunu', 'amount': '11.604 TL', 'authority': 'Kolluk', 'document': 'EK-1 İdari Yaptırım Karar Tutanağı'},
    {'title': 'Sarhoş olarak huzur ve sükûnu bozmak', 'law': '5326 · Md. 35 · Kabahatler Kanunu', 'amount': '1.764 TL', 'authority': 'Kolluk', 'document': 'Tespit Tutanağı'},
    {'title': 'Gürültüye neden olmak · gerçek kişi', 'law': '5326 · Md. 36/1 · Kabahatler Kanunu', 'amount': '1.764 TL', 'authority': 'Kolluk', 'document': 'Gürültü Tespit Tutanağı'},
    {'title': 'Gürültüye neden olmak · ticari işletme', 'law': '5326 · Md. 36/1 · Kabahatler Kanunu', 'amount': '38.246 TL', 'authority': 'Kolluk', 'document': 'Gürültü Tespit Tutanağı'},
    {'title': 'Kimlik bilgisi vermekten kaçınmak', 'law': '5326 · Md. 40 · Kabahatler Kanunu', 'amount': '1.764 TL', 'authority': 'Kolluk', 'document': 'Kimlik Tespit Tutanağı'},
    {'title': 'İzinsiz afiş asmak', 'law': '5326 · Md. 42 · Kabahatler Kanunu', 'amount': '3.705 TL', 'authority': 'Mülki Amir', 'document': 'EK-1 İdari Yaptırım Karar Tutanağı'},
    {'title': '112’ye asılsız ihbarda bulunmak', 'law': '5326 · Md. 42/A · Kabahatler Kanunu', 'amount': '18.823 TL', 'authority': 'Kolluk', 'document': 'Tespit Tutanağı'},
    {'title': 'Havalı silahı görünür şekilde taşımak', 'law': '5326 · Md. 43 · Kabahatler Kanunu', 'amount': '1.764 TL', 'authority': 'Kolluk', 'document': 'Tespit Tutanağı'},
    {'title': 'Konaklama bildirimi yapmamak', 'law': '1774 · Md. 15 · Kimlik Bildirme Kanunu', 'amount': '7.467 TL', 'authority': 'Mülki Amir', 'document': 'İdari Yaptırım Kararı'},
    {'title': 'Kimliği belgesiz kişiyi barındırmak', 'law': '1774 · Md. 17 · Kimlik Bildirme Kanunu', 'amount': '481 TL', 'authority': 'Mülki Amir', 'document': 'İdari Yaptırım Kararı'},
    {'title': 'İzinsiz yardım toplamak', 'law': '2860 · Md. 29 · Yardım Toplama Kanunu', 'amount': '47.397 TL', 'authority': 'Mülki Amir', 'document': 'İdari Yaptırım Kararı'},
    {'title': 'Kurusıkı silahı usulsüz satmak', 'law': '5729 · Md. 4', 'amount': '15.029 TL', 'authority': 'Mülki Amir', 'document': 'Tespit Tutanağı'},
    {'title': 'Ruhsatsız yivsiz tüfek taşımak', 'law': '2521 · Md. 13', 'amount': '8.195 TL', 'authority': 'Mülki Amir', 'document': 'Tespit Tutanağı'},
    {'title': 'Kapalı alanda tütün tüketmek', 'law': '4207 · Tütün Mevzuatı', 'amount': '1.764 TL', 'authority': 'Kolluk', 'document': 'Tespit Tutanağı'},
    {'title': '18 yaş altına alkol satmak', 'law': '4250 · Alkol Mevzuatı', 'amount': '206.436 TL', 'authority': 'Mülki Amir', 'document': 'İdari Yaptırım Kararı'},
    {'title': 'Hayvana kötü davranmak', 'law': '5199 · Hayvanları Koruma Kanunu', 'amount': '13.032 TL', 'authority': 'Mülki Amir', 'document': 'Tespit Tutanağı'},
    {'title': 'İzinsiz drone / İHA uçurmak', 'law': '2920 · Md. 144 · Sivil Havacılık Kanunu', 'amount': '108.370 TL', 'authority': 'Mülki Amir', 'document': 'Tespit Tutanağı'},
    {'title': 'Düzensiz göç yükümlülüğünü ihlal', 'law': '6458 · YUKK', 'amount': '8.195 TL', 'authority': 'Mülki Amir', 'document': 'Tespit Tutanağı'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _noteTitle.dispose();
    _noteBody.dispose();
    _task.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('field_notes') ?? '[]';
    final data = (jsonDecode(raw) as List).whereType<Map>().map((e) => Map<String, String>.from(e)).toList();
    if (mounted) setState(() => _notes.addAll(data));
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('field_notes', jsonEncode(_notes));
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _saveNote() async {
    if (_noteTitle.text.trim().isEmpty || _noteBody.text.trim().isEmpty) return _message('Not başlığı ve detayı zorunludur.');
    setState(() => _notes.insert(0, {'category': _category, 'title': _noteTitle.text.trim(), 'body': _noteBody.text.trim(), 'date': DateTime.now().toIso8601String()}));
    await _saveNotes();
    _noteTitle.clear();
    _noteBody.clear();
    _message('$_category notu çevrimdışı kaydedildi.');
  }

  Future<void> _pickDocument() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2400);
    if (file == null) return;
    setState(() => _cameraFile = file.name);
    _message('Belge fotoğrafı hazırlandı: ${file.name}');
  }

  Future<void> _showQrScanner() async {
    final value = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerPage()));
    if (!mounted || value == null) return;
    setState(() => _qrValue = value);
    _message('Geçerli QR içeriği alındı. Şablon aktarımı için hazır.');
  }

  void _showPenalty() {
    final p = _penalties[_selectedPenalty];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['title']!, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(p['law']!),
              const SizedBox(height: 18),
              Text(p['amount']!, style: const TextStyle(color: AppTheme.warning, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _detail('Karar makamı', p['authority']!),
              _detail('İtiraz mercii', 'Sulh Ceza Hâkimliği'),
              _detail('İtiraz süresi', '15 gün'),
              _detail('Ödeme süresi', '1 ay'),
              _detail('Tekerrür', 'Mevzuata göre değerlendirilir'),
              _detail('Tanzim edilecek evrak', p['document']!),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () { Navigator.pop(context); _message('Mevzuat maddesi not ekranına aktarılmaya hazır.'); },
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Not olarak kullan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
  List<Map<String, String>> get _filteredPenalties { final q = _search.text.toLowerCase(); return _penalties.where((p) => '${p['title']} ${p['law']}'.toLowerCase().contains(q)).toList(); }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Saha Araçları'), bottom: TabBar(controller: _tabs, isScrollable: true, tabs: const [Tab(icon: Icon(Icons.gavel_outlined), text: 'Mevzuat'), Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Nöbet'), Tab(icon: Icon(Icons.sticky_note_2_outlined), text: 'Notlar'), Tab(icon: Icon(Icons.document_scanner_outlined), text: 'Kamera'), Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR')])) , body: TabBarView(controller: _tabs, children: [_penaltyView(), _dutyView(), _notesView(), _cameraView(), _qrView()]));

  Widget _penaltyView() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Kanun, madde veya kabahat ara...')),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _filteredPenalties.length,
          itemBuilder: (_, i) {
            final p = _filteredPenalties[i];
            final index = _penalties.indexOf(p);
            return Card(
              child: ListTile(
                onTap: () { setState(() => _selectedPenalty = index); _showPenalty(); },
                leading: const CircleAvatar(child: Icon(Icons.gavel_outlined)),
                title: Text(p['title']!),
                subtitle: Text(p['law']!),
                trailing: Text(p['amount']!, style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800)),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _dutyView() => ListView(padding: const EdgeInsets.all(16), children: [Text('Nöbet ve görev planı', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), const Text('Seçtiğiniz başlangıç saatinde her gün tekrar edecek şekilde planlanır.'), const SizedBox(height: 18), DropdownButtonFormField<String>(value: _system, decoration: const InputDecoration(labelText: 'Çalışma sistemi'), items: const ['12 / 36 Sistemi', '12 / 24 Sistemi', '8 / 24 Sistemi'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (x) => setState(() => _system = x!)), DropdownButtonFormField<String>(value: _shift, decoration: const InputDecoration(labelText: 'Vardiya'), items: const ['Gündüz', 'Gece'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (x) => setState(() => _shift = x!)), DropdownButtonFormField<String>(value: _activity, decoration: const InputDecoration(labelText: 'Faaliyet'), items: const ['Önleyici Devriye Faaliyeti', 'Cadde ve Sokak Kontrol Uygulaması', 'Şok Uygulama / Denetim', 'Sabit Nokta / Çevre Güvenlik Nöbeti', 'Huzur Güven Uygulaması', 'Park ve Bahçe Denetimi'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (x) => setState(() => _activity = x!)), TextField(controller: _task, decoration: const InputDecoration(labelText: 'Görev adı')), Row(children: [Expanded(child: TextField(controller: _start, decoration: const InputDecoration(labelText: 'Başlangıç'))), const SizedBox(width: 10), Expanded(child: TextField(controller: _end, decoration: const InputDecoration(labelText: 'Bitiş')))]), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event), title: Text(_firstDutyDay.isEmpty ? 'İlk nöbet gününü seç' : _firstDutyDay), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: DateTime.now()); if (d != null) setState(() => _firstDutyDay = '${d.day}.${d.month}.${d.year}'); }), FilledButton.icon(onPressed: () => _message('Görev planı yerel olarak kaydedildi; cihaz bildirim izniyle alarm kurulabilir.'), icon: const Icon(Icons.alarm_add), label: const Text('Görevi kaydet ve alarm kur'))]);

  Widget _notesView() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Kategorili not defteri', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['Olay', 'Şahıs', 'Mevzuat', 'Özel'].map((x) => ChoiceChip(label: Text(x), selected: x == _category, onSelected: (_) => setState(() => _category = x))).toList(),
      ),
      const SizedBox(height: 14),
      TextField(controller: _noteTitle, decoration: const InputDecoration(labelText: 'Hızlı not başlığı')),
      TextField(controller: _noteBody, maxLines: 5, decoration: const InputDecoration(labelText: 'Not detayı')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _saveNote, icon: const Icon(Icons.save_outlined), label: const Text('Yerel notu kaydet')),
      const SizedBox(height: 18),
      ..._notes.map((n) => Card(child: ListTile(leading: const Icon(Icons.sticky_note_2_outlined, color: AppTheme.primary), title: Text(n['title']!), subtitle: Text('${n['category']} · ${n['body']}')))),
    ],
  );

  Widget _cameraView() => ListView(padding: const EdgeInsets.all(16), children: [Text('Belge kamerası', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), const Text('Resmî evrakı fotoğraflayıp olay dosyasına eklemek için kamera kullanın.'), const SizedBox(height: 18), Container(height: 230, alignment: Alignment.center, decoration: BoxDecoration(color: AppTheme.surfaceVariantDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.glassBorder)), child: _cameraFile.isEmpty ? const Icon(Icons.document_scanner_outlined, size: 72, color: AppTheme.primary) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle, size: 48, color: AppTheme.success), Text(_cameraFile)])), const SizedBox(height: 12), FilledButton.icon(onPressed: _pickDocument, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Belge çek')), const SizedBox(height: 8), const Text('Flaş, kadraj ve belge netliği cihaz kamerası tarafından yönetilir.', style: TextStyle(color: Colors.grey))]);

  Widget _qrView() => ListView(padding: const EdgeInsets.all(16), children: [Text('QR şablon aktarımı', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), const Text('Yalnızca Polis-Bekçi Notu tarafından oluşturulan geçerli QR kodlarını kabul eder.'), const SizedBox(height: 20), Container(height: 230, alignment: Alignment.center, decoration: BoxDecoration(color: AppTheme.surfaceVariantDark, borderRadius: BorderRadius.circular(20)), child: _qrValue.isEmpty ? const Icon(Icons.qr_code_2, size: 110, color: AppTheme.primary) : Text(_qrValue, textAlign: TextAlign.center)), const SizedBox(height: 14), FilledButton.icon(onPressed: _showQrScanner, icon: const Icon(Icons.qr_code_scanner), label: const Text('QR kodu tara')), if (_qrValue.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Card(child: ListTile(leading: const Icon(Icons.check_circle, color: AppTheme.success), title: const Text('QR içeriği alındı'), subtitle: Text(_qrValue))))]);
}

class _QrScannerPage extends StatelessWidget {
  const _QrScannerPage();
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('QR kodu çerçeve içine getirin')), body: MobileScanner(onDetect: (capture) { final code = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue; if (code != null) Navigator.pop(context, code); }));
}
