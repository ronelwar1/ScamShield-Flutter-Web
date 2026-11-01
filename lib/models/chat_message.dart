import 'analysis_models.dart';

/// One entry in the scan conversation: the user's text, a result, or an error.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.result,
    this.error,
    this.originalText,
  });

  final String text;
  final bool isUser;
  final ScamAnalysisResult? result;

  /// Set when the API could not be reached. No verdict is invented in this case.
  final String? error;

  /// The scanned text a result or error belongs to (used for highlights / retry / report).
  final String? originalText;

  bool get isError => error != null;
}
