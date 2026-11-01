import 'package:flutter/foundation.dart';

/// Lets one screen hand a piece of text (a message, a link) to another without tight coupling.
class Prefill extends ChangeNotifier {
  String? _value;

  void send(String value) {
    _value = value;
    notifyListeners();
  }

  /// Returns the pending value once, then clears it.
  String? take() {
    final v = _value;
    _value = null;
    return v;
  }
}
