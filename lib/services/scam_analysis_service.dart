import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/analysis_models.dart';

export '../models/analysis_models.dart';

/// Thrown for any failure talking to the ScamShield API. [isNetwork] means the server could not be reached.
class ApiException implements Exception {
  const ApiException(this.message, {this.isNetwork = false});
  final String message;
  final bool isNetwork;

  @override
  String toString() => message;
}

class ScamAnalysisService {
  ScamAnalysisService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const String _configuredUrl = String.fromEnvironment('SCAMSHIELD_API_URL');

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    // Chrome/web and desktop use localhost. The Android emulator reaches the host through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<ScamAnalysisResult> analyze(String text) async {
    final json = await _post('/analyze', {'text': text});
    return ScamAnalysisResult.fromJson(json);
  }

  Future<LinkReport> checkLink(String url) async {
    final json = await _post('/check-link', {'url': url});
    return LinkReport.fromJson(json);
  }

  Future<ReportReceipt> submitReport({
    required String title,
    required String message,
    required String channel,
    required bool consent,
  }) async {
    final json = await _post('/reports', {
      'title': title,
      'message': message,
      'channel': channel,
      'consent_to_store': consent,
    });
    return ReportReceipt.fromJson(json);
  }

  /// Quick health probe used for the "server online" badge. Never throws.
  Future<bool> isOnline() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException('The ScamShield server took too long to answer.', isNetwork: true);
    } catch (_) {
      throw const ApiException('Could not reach the ScamShield server.', isNetwork: true);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(response.statusCode, decoded));
    }
    if (decoded is! Map) {
      throw const ApiException('The server sent an unexpected response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static String _errorMessage(int status, dynamic decoded) {
    if (status == 429) return 'Too many requests. Please wait a minute and try again.';
    if (decoded is Map) {
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty && detail.first is Map) {
        final msg = (detail.first as Map)['msg'];
        if (msg is String && msg.isNotEmpty) return 'Please check your input: $msg';
      }
    }
    return 'The server returned an error ($status).';
  }

  void dispose() => _client.close();
}
