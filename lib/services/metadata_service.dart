import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class MetadataService extends ChangeNotifier {
  List<String> getCachedOptions(String key, List<String> fallback) {
    final box = Hive.box('metadata');
    final data = box.get(key);
    if (data != null && data is List) {
      return List<String>.from(data);
    }
    return fallback;
  }
}
