import 'package:flutter/material.dart';

import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

const Color _reportMaroon = Color(0xFF6F1628);
const Color _reportDeepMaroon = Color(0xFF4A0D1C);
const Color _reportBackground = Color(0xFFF8F6F7);
const Color _reportLine = Color(0xFFE9E0E3);
const Color _reportText = Color(0xFF292226);
const Color _reportMuted = Color(0xFF7B7075);

enum ReportUiState { idle, loading, success, empty, error }

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  ReportUiState _uiState = ReportUiState.empty;
  bool _simulateFailure = false;
  String _statusMessage = '';
  final List<String> _reports = [];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_uiState == ReportUiState.loading) return;

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _uiState = ReportUiState.loading;
      _statusMessage = 'Processing your report...';
    });

    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (_simulateFailure) {
      setState(() {
        _uiState = ReportUiState.error;
        _statusMessage =
            'The simulated operation failed. Select Retry to try again.';
      });
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Untitled report'
        : _titleController.text.trim();

    setState(() {
      _reports.insert(0, title);
      _uiState = ReportUiState.success;
      _statusMessage =
          'The simulated submission completed successfully. '
          'No database record was saved.';
    });
  }

  Future<void> _retryReport() async {
    setState(() {
      _simulateFailure = false;
      _uiState = ReportUiState.idle;
    });
    await _submitReport();
  }

  void _clearReports() {
    setState(() {
      _reports.clear();
      _uiState = ReportUiState.empty;
      _statusMessage = '';
    });
  }

  Widget _buildStatePanel() {
    switch (_uiState) {
      case ReportUiState.loading:
        return _stateCard(
          title: 'Loading',
          message: 'Please wait while the report is being processed...',
          color: _reportMaroon,
          showProgress: true,
        );

      case ReportUiState.success:
        return _stateCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Success',
          message: _statusMessage,
          color: Colors.green.shade700,
          action: AppButton(
            label: 'Create Another Report',
            icon: Icons.add_rounded,
            expand: false,
            onPressed: () {
              setState(() {
                _titleController.clear();
                _messageController.clear();
                _uiState = _reports.isEmpty
                    ? ReportUiState.empty
                    : ReportUiState.idle;
                _statusMessage = '';
              });
            },
          ),
        );

      case ReportUiState.empty:
        return _stateCard(
          icon: Icons.inbox_outlined,
          title: 'No reports yet',
          message: 'Your report list is empty. Submit a report to see it here.',
          color: _reportMuted,
          action: AppButton(
            label: 'Create Report',
            icon: Icons.edit_note_rounded,
            expand: false,
            onPressed: () {
              setState(() {
                _uiState = ReportUiState.idle;
                _statusMessage = '';
              });
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        );

      case ReportUiState.error:
        return _stateCard(
          icon: Icons.error_outline_rounded,
          title: 'Error',
          message: _statusMessage,
          color: _reportMaroon,
          action: AppButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            expand: false,
            onPressed: _retryReport,
          ),
        );

      case ReportUiState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _stateCard({
    IconData? icon,
    required String title,
    required String message,
    required Color color,
    bool showProgress = false,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _reportLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showProgress)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _reportMaroon,
                  ),
                )
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: _reportMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _reportBackground,
      appBar: AppBar(
        backgroundColor: _reportMaroon,
        foregroundColor: Colors.white,
        title: const Text(
          'ScamShield Report Form',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Submit a Suspicious Message',
                    style: TextStyle(
                      color: _reportDeepMaroon,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Enter the message you want to review. '
                    'This Activity 9 form uses simulated processing.',
                    style: TextStyle(
                      color: _reportMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _reportLine),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _titleController,
                            label: 'Report Title (optional)',
                            hintText: 'e.g. Suspicious prize message',
                            prefixIcon: Icons.title_rounded,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            controller: _messageController,
                            label: 'Suspicious Message *',
                            hintText: 'Paste the suspicious message here...',
                            prefixIcon: Icons.message_outlined,
                            minLines: 4,
                            maxLines: 6,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the suspicious message.';
                              }
                              if (value.trim().length < 5) {
                                return 'Enter at least 5 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            value: _simulateFailure,
                            onChanged: _uiState == ReportUiState.loading
                                ? null
                                : (value) {
                                    setState(() {
                                      _simulateFailure = value ?? false;
                                    });
                                  },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: _reportMaroon,
                            title: const Text(
                              'Simulate failure for testing',
                              style: TextStyle(
                                color: _reportText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'For the Activity 9 Error screenshot only.',
                              style: TextStyle(
                                color: _reportMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'Submit for Analysis',
                            icon: Icons.shield_outlined,
                            isLoading: _uiState == ReportUiState.loading,
                            onPressed: _uiState == ReportUiState.loading
                                ? null
                                : _submitReport,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Submission Response',
                    style: TextStyle(
                      color: _reportDeepMaroon,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStatePanel(),
                  if (_reports.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Submitted Reports (Demo)',
                            style: TextStyle(
                              color: _reportDeepMaroon,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearReports,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    ..._reports.map(
                      (title) => Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: const Icon(
                            Icons.description_outlined,
                            color: _reportMaroon,
                          ),
                          title: Text(title),
                          subtitle: const Text(
                            'Demo entry — not saved to a database',
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to ScamShield'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _reportMaroon,
                      side: const BorderSide(color: _reportLine),
                      padding: const EdgeInsets.all(14),
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
