import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  void _init() {
    // Stub implementation for connectivity
    // In production, use connectivity_plus
  }
}
