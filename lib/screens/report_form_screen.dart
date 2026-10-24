import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// The five UI states of this screen.
/// idle    - form is ready for input
/// loading - the (simulated) request is pending
/// success - the report was submitted
/// empty   - there are no saved reports to show
/// error   - the request failed; the user can retry or edit
enum ReportUiState { idle, loading, success, empty, error }

/// In-memory record. Reports are SIMULATED and are not saved to a database.
class ScamReport {
  const ScamReport({
    required this.reference,
    required this.sender,
    required this.type,
    required this.details,
    required this.submittedAt,
  });

  final String reference;
  final String sender;
  final String type;
  final String details;
  final DateTime submittedAt;
}

/// Report a scam: form + loading / success / empty / error states.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  static const List<String> _types = <String>[
    'Phishing link',
    'Fake prize',
    'Fake job or investment',
    'Other',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _sender = TextEditingController();
  final TextEditingController _details = TextEditingController();

  String _type = _types.first;
  ReportUiState _state = ReportUiState.idle;
  bool _showList = false; // false = New report, true = My reports
  bool _simulateFailure = false; // demo switch to show the Error state
  final List<ScamReport> _reports = <ScamReport>[];
  ScamReport? _last;
  int _counter = 0;

  @override
  void dispose() {
    _sender.dispose();
    _details.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- actions

  Future<void> _submit() async {
    // Ignore taps while a request is already pending (no duplicates).
    if (_state == ReportUiState.loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _state = ReportUiState.loading);
    try {
      // SIMULATED asynchronous request (to be replaced by the REST API).
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_simulateFailure) throw Exception('Simulated failure');
      if (!mounted) return;

      _counter++;
      final ScamReport report = ScamReport(
        reference: 'RPT-${_counter.toString().padLeft(4, '0')}',
        sender: _sender.text.trim(),
        type: _type,
        details: _details.text.trim(),
        submittedAt: DateTime.now(),
      );
      setState(() {
        _reports.insert(0, report);
        _last = report;
        _state = ReportUiState.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = ReportUiState.error);
    }
  }

  /// Retry after an error. The demo failure switch is turned off first,
  /// which simulates the connection coming back.
  void _retry() {
    setState(() {
      _simulateFailure = false;
      _state = ReportUiState.idle;
    });
    _submit();
  }

  void _newReport() {
    _sender.clear();
    _details.clear();
    setState(() {
      _type = _types.first;
      _showList = false;
      _state = ReportUiState.idle;
    });
  }

  void _openTab(bool showList) {
    if (_state == ReportUiState.loading) return;
    setState(() {
      _showList = showList;
      if (showList) {
        _state = _reports.isEmpty ? ReportUiState.empty : ReportUiState.idle;
      } else if (_state == ReportUiState.empty) {
        _state = ReportUiState.idle;
      }
    });
  }

  void _clearReports() {
    setState(() {
      _reports.clear();
      _last = null;
      _state = ReportUiState.empty;
    });
  }

  // ---------------------------------------------------------- validators

  String? _validateSender(String? v) {
    final String value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter the sender (number, email or name).';
    if (value.length < 3) return 'Sender must be at least 3 characters.';
    return null;
  }

  String? _validateDetails(String? v) {
    final String value = (v ?? '').trim();
    if (value.isEmpty) return 'Describe the scam message.';
    if (value.length < 10) return 'Please write at least 10 characters.';
    return null;
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final bool loading = _state == ReportUiState.loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Report a scam')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    const ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.edit_note_rounded),
                      label: Text('New report'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: const Icon(Icons.list_alt_rounded),
                      label: Text('My reports (${_reports.length})'),
                    ),
                  ],
                  selected: <bool>{_showList},
                  onSelectionChanged:
                      loading ? null : (Set<bool> s) => _openTab(s.first),
                ),
                const SizedBox(height: 20),
                if (_showList) _list() else _newReportTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newReportTab() {
    switch (_state) {
      case ReportUiState.success:
        return _successCard();
      case ReportUiState.error:
        return _errorCard();
      default:
        return _form(); // idle and loading both show the form
    }
  }

  // ---------------------------------------------------------------- form

  Widget _form() {
    final bool loading = _state == ReportUiState.loading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: 'Sender (number, email or name)',
            icon: Icons.person_search_rounded,
            controller: _sender,
            validator: _validateSender,
            enabled: !loading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          const Text('Type of scam',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String t in _types)
                ChoiceChip(
                  label: Text(t),
                  selected: _type == t,
                  onSelected: loading
                      ? null
                      : (bool _) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'What did the message say?',
            hint: 'Paste or describe the scam message',
            controller: _details,
            validator: _validateDetails,
            enabled: !loading,
            minLines: 4,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate failure (demo only)'),
            subtitle: const Text('Turn on to show the Error state'),
            value: _simulateFailure,
            onChanged:
                loading ? null : (bool v) => setState(() => _simulateFailure = v),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Submit report',
            icon: Icons.send_rounded,
            loading: loading,
            onPressed: _submit,
          ),
          if (loading) ...<Widget>[
            const SizedBox(height: 16),
            _stateCard(
              color: AppColors.primary,
              icon: Icons.hourglass_top_rounded,
              title: 'Submitting your report...',
              message:
                  'Please wait. This is a simulated request (about 3 seconds).',
              spinner: true,
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------- state panels

  Widget _successCard() {
    final ScamReport r = _last!;
    return _stateCard(
      color: AppColors.riskLow,
      icon: Icons.check_circle_rounded,
      title: 'Report submitted',
      message: 'Reference no. ${r.reference}\n'
          '"${r.type}" from ${r.sender} was recorded.\n'
          '(Simulated: not saved to a real database yet.)',
      actions: <Widget>[
        AppButton(
          label: 'Report another',
          icon: Icons.add_rounded,
          onPressed: _newReport,
        ),
        AppButton(
          label: 'View my reports',
          icon: Icons.list_alt_rounded,
          secondary: true,
          onPressed: () => _openTab(true),
        ),
      ],
    );
  }

  Widget _errorCard() => _stateCard(
        color: AppColors.riskHigh,
        icon: Icons.error_rounded,
        title: 'Could not submit your report',
        message: 'Something went wrong. Check your connection and try again.\n'
            '(Simulated failure for the demonstration.)',
        actions: <Widget>[
          AppButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: _retry,
          ),
          AppButton(
            label: 'Edit report',
            icon: Icons.edit_rounded,
            secondary: true,
            onPressed: () => setState(() => _state = ReportUiState.idle),
          ),
        ],
      );

  Widget _list() {
    // EMPTY state: nothing to show yet (this is not an error).
    if (_reports.isEmpty) {
      return _stateCard(
        color: AppColors.muted,
        icon: Icons.inbox_rounded,
        title: 'No reports yet',
        message: 'You have not reported any scam messages. '
            'Create your first report.',
        actions: <Widget>[
          AppButton(
            label: 'Create a report',
            icon: Icons.add_rounded,
            onPressed: () => _openTab(false),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ScamReport r in _reports)
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_rounded),
              title: Text('${r.reference} - ${r.type}'),
              subtitle: Text('${r.sender}\n${r.details}'),
              isThreeLine: true,
            ),
          ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Clear all reports',
          icon: Icons.delete_outline_rounded,
          secondary: true,
          onPressed: _clearReports,
        ),
      ],
    );
  }

  Widget _stateCard({
    required Color color,
    required IconData icon,
    required String title,
    required String message,
    bool spinner = false,
    List<Widget> actions = const <Widget>[],
  }) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: <Widget>[
            if (spinner)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      );
}
