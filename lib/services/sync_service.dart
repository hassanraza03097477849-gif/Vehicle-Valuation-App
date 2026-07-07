import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SyncService extends ChangeNotifier {
  final String baseUrl = 'http://192.168.18.183:8000/api';

  Future<void> saveSurvey(
    String jobId,
    String bankName,
    Map<String, dynamic> data,
  ) async {
    final box = Hive.box('surveyQueue');
    await box.put(jobId, {
      'jobId': jobId,
      'bankName': bankName,
      'payload': data,
      'synced': false,
    });
    notifyListeners();
  }

  Future<void> queueImage({
    required String jobId,
    required String imagePath,
    required String imageType,
  }) async {
    final box = Hive.box('imageQueue');
    
    // Check if an image of this type already exists for this job
    dynamic existingKey;
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['jobId'] == jobId && item['imageType'] == imageType) {
        existingKey = key;
        break;
      }
    }
    
    final payload = {
      'jobId': jobId,
      'imagePath': imagePath,
      'imageType': imageType,
      'synced': false,
    };
    
    if (existingKey != null) {
      await box.put(existingKey, payload);
    } else {
      await box.add(payload);
    }
    
    notifyListeners();
  }

  Future<void> syncPendingSurveys() async {
    final box = Hive.box('surveyQueue');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false) {
        String bankName = item['bankName'];
        String jobId = item['jobId'];
        Map<String, dynamic> payload = Map<String, dynamic>.from(
          item['payload'],
        );

        // E.g., /api/storeReportDataBAF/1234
        String endpoint = '$baseUrl/storeReportData$bankName/$jobId';

        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            item['synced'] = true;
            await box.put(key, item);
          }
        } catch (e) {
          debugPrint('Sync failed for $jobId: $e');
        }
      }
    }
    notifyListeners();
  }
}
