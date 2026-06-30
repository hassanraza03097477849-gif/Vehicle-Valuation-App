import 'package:flutter/foundation.dart';
import 'dart:async';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  void _init() {
    // Stub implementation for connectivity
    // In production, use connectivity_plus
  }
}
