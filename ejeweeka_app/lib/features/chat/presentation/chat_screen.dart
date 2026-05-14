// lib/features/chat/presentation/chat_screen.dart
// C-1: AI Chat — диетолог-ассистент (stateless: история на клиенте)
// POST /api/v1/chat/message + user_context из профиля

import 'package:flutter/material.dart';
import 'package:ejeweeka_app/shared/widgets/hc_gradient_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:ejeweeka_app/core/network/api_client.dart';
import 'package:ejeweeka_app/core/theme/app_theme.dart';
import 'package:ejeweeka_app/features/chat/data/chat_message_model.dart';
import 'package:ejeweeka_app/features/onboarding/providers/profile_provider.dart';
import 'package:ejeweeka_app/features/plan/providers/plan_provider.dart';
import 'package:ejeweeka_app/core/widgets/status_gate.dart';
import 'package:ejeweeka_app/shared/utils/enum_translator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessageModel> _messages = [];
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  static const _quickQuestions = [
    'Что съесть на завтрак при моей цели?',
    'Какие витамины мне нужны?',
    'Как сочетать питание с тренировками?',
    'Как снизить тягу к сладкому?',
    'Почему вес стоит на месте?',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessageModel(
      role: 'assistant',
      content: 'Привет! Я HC-нутрициолог ejeweeka. Отвечаю на вопросы о питании, витаминах и здоровье на основе профессиональной базы знаний. Чем могу помочь?',
    ));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    final msg = text.trim();
    _textCtrl.clear();

    setState(() {
      _messages.add(ChatMessageModel(role: 'user', content: msg));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final profile = ref.read(profileProvider);
      final authService = ref.read(authServiceProvider);
      final token = await authService.getValidToken();

      // Build history (last 5 for context, server rule)
      final history = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .toList()
          .reversed
          .skip(1) // skip last user msg (will be in 'message' field)
          .take(5)
          .toList()
          .reversed
          .map((m) => m.toJson())
          .toList();

      final res = await ApiClient.instance.post(
        '/api/v1/chat/message',
        data: {
          'message': msg,
          'history': history,
          'user_context': {
            'age': profile.age,
            'gender': profile.gender,
            'goal': EnumTranslator.goal(profile.goal),
            'diseases': profile.diseases,
            'allergies': profile.allergies,
          },
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final reply = data['reply'] as String? ?? '...';
        final sources = (data['sources'] as List<dynamic>?)
            ?.map((s) => Map<String, String>.from(s as Map)).toList() ?? [];

        setState(() {
          _messages.add(ChatMessageModel(
            role: 'assistant', content: reply, sources: sources));
        });
      } else {
        _addError('Ошибка сервера (${res.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        _addError('HC-ассистент временно перегружен. Попробуй через минуту.');
      } else {
        _addError('Нет соединения с сервером.');
      }
    } catch (e) {
      _addError('Ошибка: $e');
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _addError(String msg) => _messages.add(ChatMessageModel(
    role: 'assistant',
    content: '⚠️ $msg',
  ));

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    // AI-Чат (C-1) доступен только Gold/Group Gold/Trial
    final isChatLocked = !hasStatusAccess(ref, RequiredTier.gold);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _header(isChatLocked),

            // ── Quick questions ─────────────────────────────────
            if (_messages.length <= 1) _quickQuestions_(),

            // ── Messages list ───────────────────────────────────
            Expanded(child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _typingIndicator();
                return _messageBubble(_messages[i]);
              },
            )),

            // ── Lock overlay for white/black tier ────────────────────
            if (isChatLocked)
              _lockBanner()
            else
              _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isLocked) => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
    ),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
        padding: const EdgeInsets.only(right: 8),
        constraints: const BoxConstraints(),
      ),
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.psychology_outlined, color: Colors.white, size: 24)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HC-нутрициолог', style: TextStyle(fontFamily: 'Inter', fontSize: 16,
          fontWeight: FontWeight.w800)),
        Text(isLocked ? '🔒 Доступно в Gold' : '● Онлайн',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12,
            color: isLocked ? AppColors.textDisabled : const Color(0xFF4CAF50),
            fontWeight: FontWeight.w500)),
      ])),
      // Clear chat
      if (!isLocked) IconButton(
        onPressed: () => setState(() {
          _messages.clear();
          _messages.add(ChatMessageModel(role: 'assistant',
            content: 'История очищена. Чем могу помочь?'));
        }),
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
      ),
    ]),
  );

  Widget _quickQuestions_() => SizedBox(
    height: 44,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: _quickQuestions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _send(_quickQuestions[i]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Text(_quickQuestions[i], style: const TextStyle(fontFamily: 'Inter',
            fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ),
    ),
  );

  Widget _messageBubble(ChatMessageModel msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _avatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : null,
                    bottomLeft: isUser ? null : const Radius.circular(4),
                  ),
                  border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Text(msg.content, style: TextStyle(
                  fontFamily: 'Inter', fontSize: 14, height: 1.5,
                  color: isUser ? Colors.white : AppColors.textPrimary)),
              ),
              // Sources
              if (msg.sources.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Источник: ${msg.sources.first['doctor_name']} (${msg.sources.first['specialization']})',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                    color: AppColors.textDisabled)),
              ),
            ],
          )),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _avatar() => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Center(child: Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20)),
  );

  Widget _typingIndicator() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      _avatar(),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(0), const SizedBox(width: 4), _dot(150), const SizedBox(width: 4), _dot(300),
        ]),
      ),
    ]),
  );

  Widget _dot(int delayMs) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.3, end: 1.0),
    duration: Duration(milliseconds: 600 + delayMs),
    curve: Curves.easeInOut,
    builder: (_, v, __) => Opacity(opacity: v,
      child: Container(width: 8, height: 8,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))),
  );

  Widget _inputBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: const BoxDecoration(color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
    child: Row(children: [
      Expanded(child: TextField(
        controller: _textCtrl,
        maxLines: 3, minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: _loading ? null : _send,
        decoration: InputDecoration(
          hintText: 'Спросить у нутрициолога...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
      )),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _loading ? null : () => _send(_textCtrl.text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _loading ? AppColors.textDisabled : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _loading
              ? const Padding(padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]),
  );

  Widget _lockBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Color(0xFF1A1A1A),
      border: Border(top: BorderSide(color: Color(0xFF333333))),
    ),
    child: Row(children: [
      const Icon(Icons.lock_rounded, color: Colors.white54, size: 20),
      const SizedBox(width: 10),
      const Expanded(child: Text('HC-чат доступен в ejeweeka Gold',
        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70))),
      HcGradientButton(
        onPressed: () => context.push('/profile/status'),
        text: 'Улучшить статус',
      ),
    ]),
  );
}
