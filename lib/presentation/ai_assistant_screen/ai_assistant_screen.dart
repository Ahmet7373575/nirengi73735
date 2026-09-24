import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/chat_notifier.dart';
import '../../widgets/custom_icon_widget.dart';

// ─── Draft output types ────────────────────────────────────────────────────
enum DraftType { bilgiNotu, tutanak, dilekce, rapor, none }

extension DraftTypeLabel on DraftType {
  String get label {
    switch (this) {
      case DraftType.bilgiNotu:
        return 'Bilgi Notu';
      case DraftType.tutanak:
        return 'Tutanak';
      case DraftType.dilekce:
        return 'Dilekçe';
      case DraftType.rapor:
        return 'Rapor';
      case DraftType.none:
        return 'Serbest';
    }
  }

  String get icon {
    switch (this) {
      case DraftType.bilgiNotu:
        return 'description';
      case DraftType.tutanak:
        return 'article';
      case DraftType.dilekce:
        return 'edit_document';
      case DraftType.rapor:
        return 'summarize';
      case DraftType.none:
        return 'chat';
    }
  }
}

// ─── Chat message model ────────────────────────────────────────────────────
class _ChatMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;

  const _ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

// ─── System prompt builder ─────────────────────────────────────────────────
String _buildSystemPrompt(DraftType draftType) {
  const base =
      '''Sen Nirengi uygulamasının yapay zeka asistanısın. Türk emniyet personeline yardım ediyorsun.
Görevin üç ana alanda destek sağlamak:

1. NOT YAZIMI (Note Composition): Kullanıcının anlattığı olayı dinle, eksik bilgileri sormak için takip soruları sor, ardından resmi formatta belge taslağı oluştur.
2. OLAY ŞABLONLARI (Incident Templates): Hızlı olay raporları, tutanaklar ve bilgi notları için hazır şablonlar sun. Kullanıcının olay türüne göre en uygun şablonu öner ve doldur.
3. EKİP SORULARI (Team Questions): Ekip koordinasyonu, görev ataması, vardiya planlaması ve personel yönetimi konularında rehberlik et.

Kurallar:
- Türkçe konuş, resmi ama anlaşılır bir dil kullan.
- Kullanıcı adına resmi karar verme; yalnızca kullanıcının verdiği bilgilerden düzenlenebilir taslak oluştur.
- Eksik kritik bilgiler varsa (yer, saat, şüpheli tanımı vb.) sormadan taslak oluşturma.
- Her soru kısa ve net olsun; aynı anda en fazla 3 soru sor.
- Taslak oluştururken başlık, tarih/saat alanı, içerik ve imza bölümü içeren resmi format kullan.
- Olay şablonu istendiğinde önce olay türünü sor, ardından uygun şablonu sun.
- Ekip soruları için pratik, uygulanabilir öneriler ver.''';

  switch (draftType) {
    case DraftType.bilgiNotu:
      return '$base\n\nŞu an BİLGİ NOTU taslağı oluşturuyorsun. Format: T.C. başlığı, birim adı, tarih/saat, konu, açıklama paragrafları, hazırlayan personel bilgisi.';
    case DraftType.tutanak:
      return '$base\n\nŞu an TUTANAK taslağı oluşturuyorsun. Format: Tutanak başlığı, tarih/yer/saat, hazır bulunanlar, olay tespiti, imza alanları.';
    case DraftType.dilekce:
      return '$base\n\nŞu an DİLEKÇE taslağı oluşturuyorsun. Format: Makam adresi, konu satırı, saygı ifadesi, talep paragrafı, tarih ve imza.';
    case DraftType.rapor:
      return '$base\n\nŞu an RAPOR taslağı oluşturuyorsun. Format: Rapor başlığı, dönem, özet, detaylar, sonuç ve öneriler, hazırlayan.';
    case DraftType.none:
      return '$base\n\nSerbest konuşma modundasın. Kullanıcının not yazımı, olay şablonları veya ekip soruları konularındaki taleplerini karşıla. Gerektiğinde belge taslağı oluşturmayı teklif et.';
  }
}

// ─── Quick action suggestions ──────────────────────────────────────────────
const List<Map<String, String>> _quickSuggestions = [
  {
    'icon': 'edit_note',
    'label': 'Not Yaz',
    'prompt': 'Bir bilgi notu yazmama yardım et. Olayı anlatacağım.',
  },
  {
    'icon': 'article',
    'label': 'Olay Şablonu',
    'prompt': 'Hızlı olay tutanağı için şablon oluştur.',
  },
  {
    'icon': 'groups',
    'label': 'Ekip Sorusu',
    'prompt': 'Ekip koordinasyonu ve görev ataması hakkında yardım istiyorum.',
  },
  {
    'icon': 'description',
    'label': 'Bilgi Notu',
    'prompt': 'Resmi bilgi notu taslağı oluşturmak istiyorum.',
  },
];

// ─── Main screen ──────────────────────────────────────────────────────────
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  DraftType _selectedDraftType = DraftType.none;
  final List<_ChatMessage> _messages = [];
  bool _showDraftTypeSelector = false;
  bool _hasDraft = false;
  String _currentDraft = '';

  // ── Provider selection — OpenAI is the primary provider ───────────────
  bool _useOpenAI = true;

  ChatConfig get _config => _useOpenAI
      ? const ChatConfig(
          provider: 'OPEN_AI',
          model: 'gpt-5.6-terra',
          streaming: true,
        )
      : const ChatConfig(
          provider: 'GEMINI',
          model: 'gemini/gemini-3.7-flash',
          streaming: true,
        );

  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _typingAnimation = CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    );

    // Welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            content:
                'Merhaba! Ben Nirengi Yapay Zeka Asistanı (OpenAI GPT ile güçlendirilmiştir).\n\n'
                'Size şu konularda yardımcı olabilirim:\n'
                '📝 **Not Yazımı** — Olayı anlatın, resmi belge taslağı oluşturayım\n'
                '📋 **Olay Şablonları** — Tutanak, bilgi notu ve rapor şablonları\n'
                '👥 **Ekip Soruları** — Görev ataması, koordinasyon ve vardiya planlaması\n\n'
                'Aşağıdaki hızlı seçeneklerden birini kullanabilir veya doğrudan yazmaya başlayabilirsiniz.',
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // ── Build message list for API ─────────────────────────────────────────
  List<Map<String, dynamic>> _buildApiMessages() {
    final List<Map<String, dynamic>> apiMessages = [
      {'role': 'system', 'content': _buildSystemPrompt(_selectedDraftType)},
    ];
    for (final msg in _messages) {
      if (msg.role == 'system') continue;
      apiMessages.add({'role': msg.role, 'content': msg.content});
    }
    return apiMessages;
  }

  // ── Send message ───────────────────────────────────────────────────────
  void _sendMessage({String? overrideText}) {
    final text = overrideText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    // Prevent sending while AI is loading
    final currentConfig = _config;
    final chatState = ref.read(chatNotifierProvider(currentConfig));
    if (chatState.isLoading) return;

    setState(() {
      _messages.add(
        _ChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
      );
    });
    if (overrideText == null) {
      _inputController.clear();
      _inputFocusNode.unfocus();
    }

    final apiMessages = _buildApiMessages();

    ref
        .read(chatNotifierProvider(currentConfig).notifier)
        .sendMessage(
          apiMessages,
          parameters: _useOpenAI
              ? {'max_completion_tokens': 2000}
              : {'temperature': 0.7, 'max_tokens': 2000},
        );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Copy draft to clipboard ────────────────────────────────────────────
  void _copyDraft() {
    Clipboard.setData(ClipboardData(text: _currentDraft));
    Fluttertoast.showToast(
      msg: 'Taslak panoya kopyalandı',
      backgroundColor: const Color(0xFF22C55E),
      textColor: Colors.white,
    );
  }

  // ── Clear conversation ─────────────────────────────────────────────────
  void _clearConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konuşmayı Temizle',
          style: GoogleFonts.ibmPlexSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tüm konuşma geçmişi silinecek. Devam etmek istiyor musunuz?',
          style: GoogleFonts.ibmPlexSans(color: const Color(0xFFB0B0C8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: GoogleFonts.ibmPlexSans(color: const Color(0xFFB0B0C8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _hasDraft = false;
                _currentDraft = '';
                _messages.add(
                  _ChatMessage(
                    role: 'assistant',
                    content:
                        'Konuşma temizlendi. Yeni bir olay anlatmaya başlayabilirsiniz.',
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            child: Text(
              'Temizle',
              style: GoogleFonts.ibmPlexSans(color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _config;
    final chatState = ref.watch(chatNotifierProvider(currentConfig));

    // Listen for AI responses
    ref.listen<ChatState>(chatNotifierProvider(currentConfig), (
      previous,
      next,
    ) {
      if (!mounted) return;

      if (next.error != null && previous?.error != next.error) {
        // Show user-friendly Turkish error message
        final errorMsg =
            next.error?.toString() ??
            'İşlem sırasında bir sorun oluştu. Lütfen tekrar deneyin.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // When streaming completes, add assistant message
      if (previous?.isLoading == true &&
          !next.isLoading &&
          next.response.isNotEmpty &&
          next.error == null) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: 'assistant',
              content: next.response,
              timestamp: DateTime.now(),
            ),
          );

          // Detect if response contains a draft
          final lower = next.response.toLowerCase();
          if (lower.contains('t.c.') ||
              lower.contains('tutanak') ||
              lower.contains('dilekçe') ||
              lower.contains('tarih:') ||
              lower.contains('konu:')) {
            _hasDraft = true;
            _currentDraft = next.response;
          }
        });
        _scrollToBottom();
      }

      // Scroll during streaming
      if (next.isLoading && next.response.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _buildHeader(chatState),
              _buildDraftTypeSelector(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildMessageList(chatState)),
                    if (!chatState.isLoading && _messages.length <= 1)
                      _buildQuickSuggestions(),
                  ],
                ),
              ),
              if (_hasDraft) _buildDraftActions(),
              _buildInputBar(chatState),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(20), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yapay Zeka Asistanı',
                  style: GoogleFonts.ibmPlexSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: chatState.isLoading
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatState.isLoading ? 'Yanıt yazıyor...' : 'Çevrimiçi',
                      style: GoogleFonts.ibmPlexSans(
                        color: const Color(0xFFB0B0C8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Provider toggle ──────────────────────────────────────────
          GestureDetector(
            onTap: chatState.isLoading
                ? null
                : () {
                    setState(() {
                      _useOpenAI = !_useOpenAI;
                    });
                    Fluttertoast.showToast(
                      msg: _useOpenAI ? 'OpenAI (GPT) aktif' : 'Gemini aktif',
                      backgroundColor: const Color(0xFF3B82F6),
                      textColor: Colors.white,
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _useOpenAI
                    ? const Color(0xFF10A37F).withAlpha(30)
                    : const Color(0xFF4285F4).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _useOpenAI
                      ? const Color(0xFF10A37F).withAlpha(100)
                      : const Color(0xFF4285F4).withAlpha(100),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _useOpenAI ? Icons.auto_awesome : Icons.hub_rounded,
                    color: _useOpenAI
                        ? const Color(0xFF10A37F)
                        : const Color(0xFF4285F4),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _useOpenAI ? 'GPT' : 'Gemini',
                    style: GoogleFonts.ibmPlexSans(
                      color: _useOpenAI
                          ? const Color(0xFF10A37F)
                          : const Color(0xFF4285F4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Draft type toggle
          GestureDetector(
            onTap: () => setState(
              () => _showDraftTypeSelector = !_showDraftTypeSelector,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withAlpha(80),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: _selectedDraftType.icon,
                    color: const Color(0xFF3B82F6),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedDraftType.label,
                    style: GoogleFonts.ibmPlexSans(
                      color: const Color(0xFF3B82F6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _showDraftTypeSelector
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF3B82F6),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear button
          GestureDetector(
            onTap: _clearConversation,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(20), width: 1),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFFB0B0C8),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Draft type selector ────────────────────────────────────────────────
  Widget _buildDraftTypeSelector() {
    if (!_showDraftTypeSelector) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF16213E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belge Türü Seçin',
            style: GoogleFonts.ibmPlexSans(
              color: const Color(0xFFB0B0C8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DraftType.values.map((type) {
              final isSelected = _selectedDraftType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDraftType = type;
                    _showDraftTypeSelector = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6).withAlpha(40)
                        : Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withAlpha(20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: type.icon,
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFB0B0C8),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        type.label,
                        style: GoogleFonts.ibmPlexSans(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFB0B0C8),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────
  Widget _buildMessageList(ChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Streaming bubble
        if (index == _messages.length && chatState.isLoading) {
          return _buildStreamingBubble(chatState.response);
        }
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    final isDraft =
        msg.role == 'assistant' &&
        (msg.content.toLowerCase().contains('t.c.') ||
            msg.content.toLowerCase().contains('tarih:') ||
            msg.content.toLowerCase().contains('konu:'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                Fluttertoast.showToast(
                  msg: 'Kopyalandı',
                  backgroundColor: const Color(0xFF22C55E),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF3B82F6).withAlpha(200)
                      : isDraft
                      ? const Color(0xFF16213E)
                      : const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isDraft
                      ? Border.all(
                          color: const Color(0xFF3B82F6).withAlpha(80),
                          width: 1,
                        )
                      : Border.all(
                          color: Colors.white.withAlpha(isUser ? 0 : 15),
                          width: 1,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDraft) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF3B82F6),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'TASLAK BELGE',
                            style: GoogleFonts.ibmPlexSans(
                              color: const Color(0xFF3B82F6),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Divider(
                        color: const Color(0xFF3B82F6).withAlpha(50),
                        height: 1,
                      ),
                      const SizedBox(height: 6),
                    ],
                    SelectableText(
                      msg.content,
                      style: GoogleFonts.ibmPlexSans(
                        color: isUser ? Colors.white : const Color(0xFFE8E8F0),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(msg.timestamp),
                      style: GoogleFonts.ibmPlexSans(
                        color: isUser
                            ? Colors.white.withAlpha(120)
                            : const Color(0xFF5A5A7A),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildStreamingBubble(String partialResponse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white.withAlpha(15), width: 1),
              ),
              child: partialResponse.isEmpty
                  ? _buildTypingIndicator()
                  : Text(
                      partialResponse,
                      style: GoogleFonts.ibmPlexSans(
                        color: const Color(0xFFE8E8F0),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final value =
                (((_typingAnimation.value - delay) % 1.0 + 1.0) % 1.0);
            final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(
              0.3,
              1.0,
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  // ── Draft action bar ───────────────────────────────────────────────────
  Widget _buildDraftActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF3B82F6).withAlpha(60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: Color(0xFF3B82F6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Taslak belge oluşturuldu',
              style: GoogleFonts.ibmPlexSans(
                color: const Color(0xFF3B82F6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _actionChip(
            icon: Icons.copy_rounded,
            label: 'Kopyala',
            onTap: _copyDraft,
          ),
          const SizedBox(width: 8),
          _actionChip(
            icon: Icons.edit_rounded,
            label: 'Düzenle',
            onTap: () => _showDraftEditor(),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3B82F6).withAlpha(80),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF3B82F6), size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                color: const Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDraftEditor() {
    final editController = TextEditingController(text: _currentDraft);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Taslağı Düzenle',
                      style: GoogleFonts.ibmPlexSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _currentDraft = editController.text);
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(
                          msg: 'Taslak güncellendi',
                          backgroundColor: const Color(0xFF22C55E),
                        );
                      },
                      child: Text(
                        'Kaydet',
                        style: GoogleFonts.ibmPlexSans(
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: editController,
                    maxLines: null,
                    expands: true,
                    style: GoogleFonts.ibmPlexMono(
                      color: const Color(0xFFE8E8F0),
                      fontSize: 13,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(20),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withAlpha(20),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B82F6),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick suggestion chips ─────────────────────────────────────────────
  Widget _buildQuickSuggestions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Hızlı Başlangıç',
              style: GoogleFonts.ibmPlexSans(
                color: const Color(0xFF5A5A7A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _sendMessage(overrideText: suggestion['prompt']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10A37F).withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: suggestion['icon']!,
                        color: const Color(0xFF10A37F),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        suggestion['label']!,
                        style: GoogleFonts.ibmPlexSans(
                          color: const Color(0xFF10A37F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────
  Widget _buildInputBar(ChatState chatState) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withAlpha(220),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(15), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    maxLines: null,
                    enabled: !chatState.isLoading,
                    textInputAction: TextInputAction.newline,
                    style: GoogleFonts.ibmPlexSans(
                      color: const Color(0xFFE8E8F0),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: chatState.isLoading
                          ? 'Yanıt bekleniyor...'
                          : 'Olayı anlatın veya soru sorun...',
                      hintStyle: GoogleFonts.ibmPlexSans(
                        color: const Color(0xFF5A5A7A),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!chatState.isLoading) _sendMessage();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: chatState.isLoading ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: chatState.isLoading
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: chatState.isLoading
                        ? Colors.white.withAlpha(20)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: chatState.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}