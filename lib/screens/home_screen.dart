import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/scan_result.dart';
import '../routes/app_routes.dart';
import '../services/mock_analysis_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_logo.dart';
import '../widgets/feature_card.dart';
import '../widgets/result_card.dart';

/// Home: hero + message scanner + how-it-works.
/// Analysis uses a mock service until the REST API exists.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _samples = <String>[
    'URGENT! Your GCash account is locked. Verify your OTP at http://bit.ly/gc-verify within 24 hours.',
    'Congratulations! You won a free prize. Claim your reward now: www.claim-now.example',
    'Hi, are we still meeting for lunch at 12 tomorrow?',
  ];

  final TextEditingController _controller = TextEditingController();
  final MockAnalysisService _service = const MockAnalysisService();
  bool _loading = false;
  ScanResult? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Paste or type a message to check first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final ScanResult r = await _service.analyze(text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = r;
    });
  }

  void _reset() {
    _controller.clear();
    setState(() {
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _hero(context, wide),
            _howItWorks(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AppButton(
                  label: 'Report a scam message',
                  icon: Icons.flag_outlined,
                  secondary: true,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.report),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Text(
                'Results are automated estimates and are not a guarantee. '
                'When in doubt, contact the sender through an official channel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, bool wide) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[AppColors.heroStart, AppColors.heroEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: <Widget>[
                    const AppLogo(light: true),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      child: const Text('Log in'),
                    ),
                    if (wide)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.report),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text('Report a scam'),
                      )
                    else
                      IconButton(
                        tooltip: 'Report a scam',
                        color: Colors.white,
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.report),
                        icon: const Icon(Icons.flag_outlined),
                      ),
                    if (wide) ...<Widget>[
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.heroStart,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text('Sign up'),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Think it\'s a scam?\nCheck it in seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: wide ? 46 : 30,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${AppConstants.appTagline}. Paste a text, chat or '
                        'email and get a clear risk level.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 28),
                      _scannerCard(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _scannerCard(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
                color: Color(0x33000000), blurRadius: 30, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Paste the message',
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 8,
              maxLength: AppConstants.maxMessageLength,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Paste a suspicious message here...',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const Text('Try an example:',
                    style: TextStyle(color: AppColors.muted)),
                for (int i = 0; i < _samples.length; i++)
                  ActionChip(
                    label: Text('Example ${i + 1}'),
                    onPressed: () => setState(() {
                      _controller.text = _samples[i];
                      _error = null;
                      _result = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Check message',
                    icon: Icons.search_rounded,
                    loading: _loading,
                    onPressed: _analyze,
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Clear',
                  secondary: true,
                  onPressed: _reset,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              alignment: Alignment.topCenter,
              child: _result == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: <Widget>[
                          ResultCard(result: _result!, onScanAnother: _reset),
                          const SizedBox(height: 12),
                          _guestBanner(context),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );

  Widget _guestBanner(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.history_rounded, color: AppColors.muted),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Log in to save your scans to a history.'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Log in'),
            ),
          ],
        ),
      );

  Widget _howItWorks() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
        child: Column(
          children: <Widget>[
            const Text('How it works',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 24),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: <Widget>[
                FeatureCard(
                  icon: Icons.content_paste_rounded,
                  title: '1. Paste',
                  text: 'Copy the suspicious text, chat or email and paste it in.',
                ),
                FeatureCard(
                  icon: Icons.manage_search_rounded,
                  title: '2. Analyze',
                  text: 'We look for warning signs like fake links, pressure and requests for codes.',
                ),
                FeatureCard(
                  icon: Icons.gpp_good_rounded,
                  title: '3. Stay safe',
                  text: 'Get a clear risk level with the reasons behind it.',
                ),
              ],
            ),
          ],
        ),
      );
}
