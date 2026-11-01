import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/scam_analysis_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common_widgets.dart';

enum ReportUiState { idle, loading, success, empty, error }

const List<(String, String)> _channels = [
  ('sms', '💬 Text / SMS'),
  ('email', '✉️ Email'),
  ('social', '📱 Social media'),
  ('call', '📞 Phone call'),
  ('other', '🌐 Other'),
];

/// Sends a suspicious message to the ScamShield server (with consent). Text is masked before it is stored.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, required this.service, this.initialMessage});

  final ScamAnalysisService service;
  final String? initialMessage;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final TextEditingController _messageController = TextEditingController(text: widget.initialMessage ?? '');

  ReportUiState _uiState = ReportUiState.empty;
  String _channel = 'sms';
  bool _consent = false;
  bool _consentError = false;
  bool _simulateFailure = false;
  String _statusMessage = '';
  ReportReceipt? _receipt;
  final List<String> _reports = [];

  @override
  void initState() {
    super.initState();
    if ((widget.initialMessage ?? '').isNotEmpty) _uiState = ReportUiState.idle;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_uiState == ReportUiState.loading) return;
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _consentError = !_consent);
    if (!valid || !_consent) return;

    setState(() {
      _uiState = ReportUiState.loading;
      _statusMessage = 'Sending your report…';
      _receipt = null;
    });

    try {
      if (_simulateFailure) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        throw const ApiException('Simulated failure for testing. Untick the box and try again.');
      }
      final title = _titleController.text.trim();
      final receipt = await widget.service.submitReport(
        title: title,
        message: _messageController.text.trim(),
        channel: _channel,
        consent: _consent,
      );
      if (!mounted) return;
      setState(() {
        _reports.insert(0, title.isEmpty ? 'Untitled report' : title);
        _receipt = receipt;
        _uiState = ReportUiState.success;
        _statusMessage = receipt.note;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uiState = ReportUiState.error;
        _statusMessage = e is ApiException && !e.isNetwork
            ? e.message
            : 'Could not reach the ScamShield server at ${ScamAnalysisService.baseUrl}. Your report was not sent. Start the backend and try again.';
      });
    }
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _messageController.clear();
      _consent = false;
      _consentError = false;
      _receipt = null;
      _uiState = ReportUiState.idle;
      _statusMessage = '';
    });
  }

  Widget _statePanel() {
    switch (_uiState) {
      case ReportUiState.loading:
        return _stateCard(title: 'Sending', message: _statusMessage, color: AppColors.primary, showProgress: true);
      case ReportUiState.success:
        return _stateCard(
          icon: Icons.check_circle_rounded,
          title: 'Thank you! Report received 🎉',
          message: '$_statusMessage${_receipt == null ? '' : '\n\nSaved as report #${_receipt!.id}. What we stored (masked): “${_receipt!.storedText}”'}',
          color: AppColors.safe,
          action: AppButton(label: 'Report another', icon: Icons.add_rounded, expand: false, onPressed: _resetForm),
        );
      case ReportUiState.empty:
        return _stateCard(
          icon: Icons.inbox_outlined,
          title: 'No reports yet',
          message: 'Reports you send in this session will be listed below.',
          color: AppColors.mutedText,
        );
      case ReportUiState.error:
        return _stateCard(
          icon: Icons.error_outline_rounded,
          title: 'That didn\'t go through',
          message: _statusMessage,
          color: AppColors.coralDeep,
          action: AppButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            expand: false,
            onPressed: _submitReport,
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
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showProgress)
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              else
                Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.text, fontSize: 14.5, height: 1.5)),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Report a message', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageBody(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeading(
                  emoji: '🚩',
                  title: 'Help protect others',
                  subtitle: 'Send a suspicious message so it can be reviewed and used to improve ScamShield.',
                ),
                const SizedBox(height: 18),
                SoftCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _titleController,
                          label: 'Title (optional)',
                          hintText: 'e.g. Fake parcel fee message',
                          prefixIcon: Icons.title_rounded,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _messageController,
                          label: 'Suspicious message *',
                          hintText: 'Paste the message here…',
                          prefixIcon: Icons.message_outlined,
                          minLines: 4,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return 'Please enter the suspicious message.';
                            if (v.length < 5) return 'Enter at least 5 characters.';
                            if (v.length > 5000) return 'Please keep it under 5,000 characters.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Where did you get it?', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in _channels)
                              ChoiceChip(
                                label: Text(c.$2),
                                selected: _channel == c.$1,
                                selectedColor: AppColors.mint,
                                onSelected: (_) => setState(() => _channel = c.$1),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _consent,
                          onChanged: _uiState == ReportUiState.loading
                              ? null
                              : (v) => setState(() {
                                    _consent = v ?? false;
                                    if (_consent) _consentError = false;
                                  }),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                          title: const Text(
                            'I agree that this message may be stored to help improve ScamShield.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          subtitle: Text(
                            'Codes, emails and long numbers are masked before saving. Please don\'t include anything private.',
                            style: TextStyle(fontSize: 12.5, color: _consentError ? AppColors.coralDeep : AppColors.mutedText),
                          ),
                        ),
                        if (_consentError)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('Please tick the box to send your report.', style: TextStyle(color: AppColors.coralDeep, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        CheckboxListTile(
                          value: _simulateFailure,
                          onChanged: _uiState == ReportUiState.loading ? null : (v) => setState(() => _simulateFailure = v ?? false),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppColors.primary,
                          dense: true,
                          title: const Text('Demo: simulate a failure', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                          subtitle: const Text('Only for showing the error screen.', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: 'Send report',
                          icon: Icons.send_rounded,
                          isLoading: _uiState == ReportUiState.loading,
                          onPressed: _uiState == ReportUiState.loading ? null : _submitReport,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _statePanel(),
                if (_reports.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Sent this session', style: TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  for (final title in _reports)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text))),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to ScamShield'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.all(14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
