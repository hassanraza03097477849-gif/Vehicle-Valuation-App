import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MetadataService extends ChangeNotifier {
  final String baseUrl = 'http://192.168.18.183:8000/api';
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAllMetadata() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchAndCache('/getClasses', 'vehicle_classes'),
        _fetchAndCache('/getRimTypes', 'rim_types'),
        _fetchAndCache('/getBodyTypes', 'body_types'),
      ]);
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndCache(String endpoint, String cacheKey) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Assuming the API returns a list of objects like [{id: 1, text: 'Sedan'}, ...]
        // or a flat array. We extract the string representation.
        List<String> options = [];
        for (var item in data) {
          if (item is Map && item.containsKey('text')) {
            options.add(item['text'].toString());
          } else if (item is Map && item.containsKey('name')) {
            options.add(item['name'].toString());
          } else {
            options.add(item.toString());
          }
        }
        final box = Hive.box('metadata');
        await box.put(cacheKey, options);
      }
    } catch (e) {
      debugPrint('Error on $endpoint: $e');
    }
  }

  List<String> getCachedOptions(String fieldKey, List<String> fallback) {
    String cacheKey = '';

    // Map specific schema field keys to our cached API data keys
    if (fieldKey == 'car_class' || fieldKey == 'vehicleClass') {
      cacheKey = 'vehicle_classes';
    } else if (fieldKey == 'rim_type') {
      cacheKey = 'rim_types';
    } else if (fieldKey == 'body_type') {
      cacheKey = 'body_types';
    } else {
      return fallback; // For hardcoded fields where API isn't used
    }

    final box = Hive.box('metadata');
    final data = box.get(cacheKey);
    if (data != null && data is List) {
      return List<String>.from(data);
    }
    return fallback;
  }
}
