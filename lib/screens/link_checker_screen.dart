import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../services/prefill.dart';
import '../services/scam_analysis_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/link_report_card.dart';

/// Paste a link and see warning signs in its address. The link is NEVER opened or fetched.
class LinkCheckerScreen extends StatefulWidget {
  const LinkCheckerScreen({super.key, required this.service, required this.prefill});

  final ScamAnalysisService service;
  final Prefill prefill;

  @override
  State<LinkCheckerScreen> createState() => _LinkCheckerScreenState();
}

class _LinkCheckerScreenState extends State<LinkCheckerScreen> {
  final TextEditingController _controller = TextEditingController();
  LinkReport? _report;
  String? _error;
  bool _loading = false;

  static const List<String> _samples = [
    'http://secure-bdo-verify.top/login',
    'bit.ly/3xYk2P',
    'https://www.gcash.com/help',
    'http://192.168.4.12/verify',
  ];

  @override
  void initState() {
    super.initState();
    widget.prefill.addListener(_onPrefill);
  }

  @override
  void dispose() {
    widget.prefill.removeListener(_onPrefill);
    _controller.dispose();
    super.dispose();
  }

  void _onPrefill() {
    final url = widget.prefill.take();
    if (url == null || !mounted) return;
    _controller.text = url;
    _check();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (mounted) showSnack(context, 'Nothing to paste yet. Copy a link first.');
      return;
    }
    _controller.text = text;
  }

  Future<void> _check() async {
    final url = _controller.text.trim();
    if (url.length < 3 || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.service.checkLink(url);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _report = null;
        _error = e is ApiException && !e.isNetwork
            ? e.message
            : 'Could not reach the ScamShield server at ${ScamAnalysisService.baseUrl}. No verdict was made, so this does not mean the link is safe.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeading(
              emoji: '🔗',
              title: 'Link checker',
              subtitle: 'Paste a link to look for warning signs in its address. We never open it for you.',
            ),
            const SizedBox(height: 20),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _check(),
                    decoration: InputDecoration(
                      labelText: 'Link or web address',
                      hintText: 'e.g. bit.ly/3xYk2P',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Paste',
                        onPressed: _paste,
                        icon: const Icon(Icons.content_paste_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _loading ? null : _check,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.travel_explore_rounded),
                    label: const Text('Check this link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Try one:', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mutedText, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _samples)
                        ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 13)),
                          backgroundColor: AppColors.mint,
                          side: BorderSide.none,
                          onPressed: () {
                            _controller.text = s;
                            _check();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null)
              SoftCard(
                color: AppColors.coralSoft,
                borderColor: AppColors.coral,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.coralDeep),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFF8E1F10), height: 1.45, fontSize: 14.5))),
                  ],
                ),
              ),
            if (_report != null) ...[
              LinkReportCard(report: _report!),
              const SizedBox(height: 14),
              const Text(
                'This is a text-only check of the address. It cannot see what is on the page, and a clean result does not prove a site is safe.',
                style: TextStyle(fontSize: 12.5, color: AppColors.mutedText, height: 1.45),
              ),
            ],
            if (_report == null && _error == null)
              const SoftCard(
                color: AppColors.sunshineSoft,
                borderColor: AppColors.sunshine,
                child: Text(
                  '💡 Real organisations rarely use shortened links, raw numbers (like 192.168.1.5) or odd endings such as .top or .click for login pages. '
                  'When in doubt, open the official app or type the website yourself.',
                  style: TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
