import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../data/scam_knowledge.dart';
import '../models/chat_message.dart';
import '../services/history_store.dart';
import '../services/prefill.dart';
import '../services/scam_analysis_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/result_card.dart';
import '../widgets/shield_logo.dart';

const List<String> _examples = [
  'Your GCash account is limited. Verify now: gcash-verify.top/login',
  'Your parcel is on hold. Pay PHP 1,200 customs fee at bit.ly/3xYk2P to release it today.',
  'Hi Mom, I lost my phone. This is my new number. Please send PHP 5,000 to this GCash now. Don\'t tell Dad.',
  'Hi! Class is moved to 2 PM tomorrow. See you there.',
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.service,
    required this.history,
    required this.prefill,
    required this.onReport,
    required this.onShowGuide,
    required this.onOpenHelp,
  });

  final ScamAnalysisService service;
  final HistoryStore history;
  final Prefill prefill;
  final void Function(String text) onReport;
  final void Function(String scamTypeId) onShowGuide;
  final VoidCallback onOpenHelp;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  final List<ChatMessage> _messages = [];
  final GlobalKey _lastKey = GlobalKey();

  bool _sending = false;
  bool? _online; // null = still checking

  @override
  void initState() {
    super.initState();
    widget.prefill.addListener(_onPrefill);
    _checkServer();
  }

  @override
  void dispose() {
    widget.prefill.removeListener(_onPrefill);
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onPrefill() {
    final text = widget.prefill.take();
    if (text == null || !mounted) return;
    setState(() => _controller.text = text);
    _focus.requestFocus();
  }

  Future<void> _checkServer() async {
    setState(() => _online = null);
    final ok = await widget.service.isOnline();
    if (!mounted) return;
    setState(() => _online = ok);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) showSnack(context, 'Nothing to paste yet. Copy a message first.');
      return;
    }
    _controller.text = text.trim();
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _focus.requestFocus();
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _controller.text).trim();
    if (text.length < 3 || _sending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    if (override == null) _controller.clear();
    _scrollToEnd();

    try {
      final result = await widget.service.analyze(text);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: '', isUser: false, result: result, originalText: text));
        _sending = false;
        _online = true;
      });
      widget.history.add(text, result);
      _scrollToLatest();
    } catch (error) {
      if (!mounted) return;
      final isNetwork = error is ApiException ? error.isNetwork : true;
      setState(() {
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          error: error is ApiException ? error.message : 'Something went wrong.',
          originalText: text,
        ));
        _sending = false;
        if (isNetwork) _online = false;
      });
      _scrollToLatest();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  /// Brings the top of the newest answer into view so the verdict is seen first.
  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _lastKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusBar(
          online: _online,
          onRetry: _checkServer,
          onNewChat: _messages.isEmpty ? null : _newChat,
        ),
        Expanded(
          child: _messages.isEmpty
              ? _EmptyState(
                  onExample: (t) => _send(t),
                  onOpenHelp: widget.onOpenHelp,
                )
              : SelectionArea(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: PageBody(
                      padding: EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width < 600 ? 12 : 24, 18, MediaQuery.sizeOf(context).width < 600 ? 12 : 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _messages.length; i++)
                            Padding(
                              key: i == _messages.length - 1 ? _lastKey : null,
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _MessageView(
                                message: _messages[i],
                                onRetry: _send,
                                onReport: widget.onReport,
                                onShowGuide: widget.onShowGuide,
                              ),
                            ),
                          if (_sending) const _AnalyzingIndicator(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        _Composer(
          controller: _controller,
          focusNode: _focus,
          sending: _sending,
          onPaste: _paste,
          onSend: () => _send(),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.online, required this.onRetry, required this.onNewChat});
  final bool? online;
  final VoidCallback onRetry;
  final VoidCallback? onNewChat;

  @override
  Widget build(BuildContext context) {
    final Widget chip;
    if (online == null) {
      chip = const Chip(
        avatar: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        label: Text('Checking server…'),
        visualDensity: VisualDensity.compact,
      );
    } else if (online == true) {
      chip = Chip(
        avatar: const Icon(Icons.cloud_done_rounded, size: 18, color: AppColors.safe),
        label: const Text('Checker online'),
        backgroundColor: AppColors.safeSoft,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      );
    } else {
      chip = ActionChip(
        avatar: const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.coralDeep),
        label: const Text('Server offline. Tap to retry'),
        backgroundColor: AppColors.coralSoft,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        onPressed: onRetry,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Flexible(child: chip),
          const Spacer(),
          if (onNewChat != null)
            TextButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text('New check'),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExample, required this.onOpenHelp});
  final void Function(String text) onExample;
  final VoidCallback onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 760,
        child: Column(
          children: [
            SizedBox(height: width < 600 ? 4 : 16),
            const ShieldLogo(size: 76),
            const SizedBox(height: 18),
            Text(
              'Let\'s check that message together! 🕵️',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width < 600 ? 24 : 30,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Paste any suspicious text, email or chat below. I\'ll point out the warning signs and tell you what to do next.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText, fontSize: 15.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            SoftCard(
              color: AppColors.sunshineSoft,
              borderColor: AppColors.sunshine,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tip of the day', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.sunshineDeep, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(tipOfTheDay(), style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.text, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Try an example', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in _examples)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width < 600 ? width - 28 : 360),
                    child: ActionChip(
                      onPressed: () => onExample(e),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      avatar: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                      label: Text(e, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onOpenHelp,
              child: SoftCard(
                color: AppColors.coralSoft,
                borderColor: AppColors.coral,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Text('🆘', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Think you already got scammed?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF8E1F10), fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Open the step-by-step recovery guide.', style: TextStyle(fontSize: 13.5, color: Color(0xFF8E1F10))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E1F10)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your text is sent to your ScamShield server for analysis. Avoid pasting passwords or full card numbers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.mutedText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onRetry, required this.onReport, required this.onShowGuide});
  final ChatMessage message;
  final void Function(String text) onRetry;
  final void Function(String text) onReport;
  final void Function(String scamTypeId) onShowGuide;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85 > 640 ? 640 : MediaQuery.sizeOf(context).width * 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF12948C)]),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
        ),
      );
    }
    if (message.isError) {
      return SoftCard(
        color: AppColors.coralSoft,
        borderColor: AppColors.coral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: AppColors.coralDeep),
                SizedBox(width: 10),
                Expanded(
                  child: Text('I couldn\'t check that message', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF8E1F10))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.error ?? '', style: const TextStyle(color: Color(0xFF8E1F10), fontSize: 14.5, height: 1.45)),
            const SizedBox(height: 8),
            Text(
              'No verdict was made, so this is NOT a sign the message is safe. '
              'Make sure the ScamShield server is running at ${ScamAnalysisService.baseUrl} '
              '(in the backend folder: uvicorn app:app --reload --port 8000).',
              style: const TextStyle(color: Color(0xFF8E1F10), fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => onRetry(message.originalText ?? ''),
              style: FilledButton.styleFrom(backgroundColor: AppColors.coralDeep, foregroundColor: Colors.white),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    final result = message.result;
    if (result == null) return const SizedBox.shrink();
    return ResultCard(
      result: result,
      originalText: message.originalText ?? '',
      onReport: onReport,
      onShowGuide: onShowGuide,
    );
  }
}

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: SoftCard(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 12),
            Text('Sniffing out warning signs… 🔎', style: TextStyle(color: AppColors.mutedText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onPaste,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onPaste;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(width < 600 ? 10 : 20, 8, width < 600 ? 10 : 20, 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Paste from clipboard',
                    onPressed: onPaste,
                    icon: const Icon(Icons.content_paste_rounded, color: AppColors.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 6,
                      maxLength: 5000,
                      buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15.5),
                      decoration: const InputDecoration(
                        hintText: 'Paste or type the message to check…',
                        hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final canSend = value.text.trim().length >= 3 && !sending;
                        return IconButton.filled(
                          tooltip: 'Check this message',
                          onPressed: canSend ? onSend : null,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: sending
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Icon(Icons.shield_rounded),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
