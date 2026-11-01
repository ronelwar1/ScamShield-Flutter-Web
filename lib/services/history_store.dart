import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_models.dart';

class ScanRecord {
  const ScanRecord({required this.id, required this.time, required this.text, required this.result});
  final String id;
  final DateTime time;
  final String text;
  final ScamAnalysisResult result;

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'text': text,
        'result': result.toJson(),
      };

  static ScanRecord? tryParse(Object? raw) {
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      return ScanRecord(
        id: map['id'] as String,
        time: DateTime.parse(map['time'] as String),
        text: map['text'] as String,
        result: ScamAnalysisResult.fromJson(Map<String, dynamic>.from(map['result'] as Map)),
      );
    } catch (_) {
      return null; // skip a corrupt entry instead of losing the whole history
    }
  }
}

/// On-device scan history. Nothing here is sent to the server. The person can switch it off or clear it.
class HistoryStore extends ChangeNotifier {
  static const String _itemsKey = 'scamshield_history_v1';
  static const String _enabledKey = 'scamshield_history_enabled';
  static const int maxItems = 50;

  final List<ScanRecord> _items = [];
  bool _enabled = true;
  bool _loaded = false;

  List<ScanRecord> get items => List.unmodifiable(_items);
  bool get enabled => _enabled;
  bool get loaded => _loaded;

  int countWhere(bool Function(ScanRecord) test) => _items.where(test).length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
      final raw = prefs.getString(_itemsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items
            ..clear()
            ..addAll(decoded.map(ScanRecord.tryParse).whereType<ScanRecord>());
        }
      }
    } catch (_) {
      // Storage can be unavailable (private browsing, blocked storage). The app still works without it.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(String text, ScamAnalysisResult result) async {
    if (!_enabled) return;
    final now = DateTime.now();
    _items.insert(0, ScanRecord(id: now.microsecondsSinceEpoch.toString(), time: now, text: text, result: result));
    if (_items.length > maxItems) _items.removeRange(maxItems, _items.length);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _save();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_itemsKey, jsonEncode(_items.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }
}
