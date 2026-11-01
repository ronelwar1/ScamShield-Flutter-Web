import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/history_store.dart';
import '../services/prefill.dart';
import '../services/scam_analysis_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shield_logo.dart';
import 'auth_screen.dart';
import 'guide_screen.dart';
import 'history_screen.dart';
import 'link_checker_screen.dart';
import 'recovery_screen.dart';
import 'report_form_screen.dart';
import 'scan_screen.dart';

class _Destination {
  const _Destination(this.label, this.title, this.icon, this.selectedIcon);
  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_Destination> _destinations = [
  _Destination('Check', 'Check a message', Icons.shield_outlined, Icons.shield_rounded),
  _Destination('Links', 'Link checker', Icons.link_rounded, Icons.link_rounded),
  _Destination('Guide', 'How scams work', Icons.menu_book_outlined, Icons.menu_book_rounded),
  _Destination('History', 'Your checks', Icons.history_rounded, Icons.history_rounded),
  _Destination('Help', 'I think I got scammed', Icons.health_and_safety_outlined, Icons.health_and_safety_rounded),
];

const int _pageScan = 0;
const int _pageGuide = 2;
const int _pageHelp = 4;

/// Responsive scaffold: bottom bar on phones, navigation rail on tablets, side bar on desktops.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.service});

  /// Injectable for tests; the app creates its own when this is null.
  final ScamAnalysisService? service;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ScamAnalysisService _service = widget.service ?? ScamAnalysisService();
  final HistoryStore _history = HistoryStore();
  final Prefill _scanPrefill = Prefill();
  final Prefill _linkPrefill = Prefill();
  final Prefill _guidePrefill = Prefill();

  int _index = _pageScan;

  @override
  void initState() {
    super.initState();
    _history.load();
  }

  @override
  void dispose() {
    _service.dispose();
    _history.dispose();
    _scanPrefill.dispose();
    _linkPrefill.dispose();
    _guidePrefill.dispose();
    super.dispose();
  }

  void _go(int index) => setState(() => _index = index);

  void _openReport([String? text]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReportFormScreen(service: _service, initialMessage: text)),
    );
  }

  void _openAuth() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
  }

  void _showGuide(String scamTypeId) {
    _go(_pageGuide);
    _guidePrefill.send(scamTypeId);
  }

  void _scanAgain(String text) {
    _go(_pageScan);
    _scanPrefill.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < Breakpoints.tablet || size.height < 520;
    final desktop = !mobile && size.width >= Breakpoints.desktop;

    final pages = IndexedStack(
      index: _index,
      children: [
        ScanScreen(
          service: _service,
          history: _history,
          prefill: _scanPrefill,
          onReport: _openReport,
          onShowGuide: _showGuide,
          onOpenHelp: () => _go(_pageHelp),
        ),
        LinkCheckerScreen(service: _service, prefill: _linkPrefill),
        GuideScreen(prefill: _guidePrefill),
        HistoryScreen(history: _history, onScanAgain: _scanAgain, onReport: _openReport, onShowGuide: _showGuide),
        const RecoveryScreen(),
      ],
    );

    final topBar = _TopBar(
      title: _destinations[_index].title,
      showBrand: !desktop,
      onReport: () => _openReport(),
      onAuth: _openAuth,
    );

    if (desktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(index: _index, onSelect: _go, onReport: () => _openReport(), onAuth: _openAuth),
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(child: pages),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!mobile) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              indicatorColor: AppColors.mint,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(child: pages),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Phone layout: all five destinations fit in the bottom bar. Report and sign-in live in the top bar.
    return Scaffold(
      body: Column(
        children: [
          topBar,
          Expanded(child: pages),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        onDestinationSelected: _go,
        destinations: [
          for (final d in _destinations) NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.showBrand, required this.onReport, required this.onAuth});
  final String title;
  final bool showBrand;
  final VoidCallback onReport;
  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 480;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.primary, Color(0xFF12A096)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 10, narrow ? 6 : 14, 10),
          child: Row(
            children: [
              if (showBrand) ...[
                const ShieldLogo(size: 38, onDark: true),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBrand)
                      const Text('ScamShield', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3, height: 1.1)),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: showBrand ? const Color(0xFFD9F6F0) : Colors.white,
                        fontSize: showBrand ? 12.5 : 19,
                        fontWeight: showBrand ? FontWeight.w600 : FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (narrow) ...[
                IconButton(tooltip: 'Report a message', onPressed: onReport, icon: const Icon(Icons.flag_rounded, color: Colors.white)),
                IconButton(tooltip: 'Sign in', onPressed: onAuth, icon: const Icon(Icons.account_circle_outlined, color: Colors.white)),
              ] else ...[
                TextButton.icon(
                  onPressed: onReport,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: const Text('Report', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: onAuth,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.sunshine, foregroundColor: AppColors.text),
                  child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.index, required this.onSelect, required this.onReport, required this.onAuth});
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onReport;
  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryDark, Color(0xFF0B6B66)]),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 18, 18),
              child: Row(
                children: [
                  ShieldLogo(size: 44, onDark: true),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('ScamShield', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (var i = 0; i < _destinations.length; i++)
                      _SidebarItem(
                        icon: index == i ? _destinations[i].selectedIcon : _destinations[i].icon,
                        label: _destinations[i].title,
                        selected: index == i,
                        onTap: () => onSelect(i),
                      ),
                    const SizedBox(height: 8),
                    _SidebarItem(icon: Icons.flag_rounded, label: 'Report a message', selected: false, onTap: onReport),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.person_outline_rounded, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Guest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  TextButton(
                    onPressed: onAuth,
                    style: TextButton.styleFrom(foregroundColor: AppColors.sunshine),
                    child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? AppColors.primary : Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColors.primaryDark : Colors.white,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
