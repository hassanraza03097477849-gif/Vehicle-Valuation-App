import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SyncService extends ChangeNotifier {
  final String baseUrl = ApiConfig.baseUrl;

  Future<void> saveSurvey(
    String jobId,
    String bankName,
    Map<String, dynamic> data,
    String dbId,
  ) async {
    final box = Hive.box('surveyQueue');
    await box.put(jobId, {
      'jobId': jobId,
      'bankName': bankName,
      'payload': data,
      'synced': false,
      'dbId': dbId,
    });
    notifyListeners();
  }

  Future<void> queueImage({
    required String jobId,
    required String imagePath,
    required String imageType,
    required String dbId,
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
      'dbId': dbId,
    };
    
    if (existingKey != null) {
      await box.put(existingKey, payload);
    } else {
      await box.add(payload);
    }
    
    notifyListeners();
  }

  Future<void> syncPendingSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return; // Cannot sync without token

    final box = Hive.box('surveyQueue');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false) {
        String bankName = item['bankName'];
        String jobId = item['jobId'];
        String dbId = item['dbId'] ?? jobId; // fallback for older items
        Map<String, dynamic> payload = Map<String, dynamic>.from(item['payload']);

        String endpoint = '$baseUrl/storeReportData$bankName/$dbId';

        try {
          final response = await http.put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
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
    
    // Also sync images
    await syncPendingImages(token);
    
    notifyListeners();
  }

  Future<void> syncPendingImages(String token) async {
    final box = Hive.box('imageQueue');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false) {
        String jobId = item['jobId'];
        String dbId = item['dbId'] ?? jobId; // fallback for older items
        String imagePath = item['imagePath'];
        String imageType = item['imageType'];

        try {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/uploadValuationImages'),
          );
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = 'application/json';
          request.fields['job_id'] = dbId;
          request.fields['filename'] = imageType; // This maps to ftype in backend

          request.files.add(await http.MultipartFile.fromPath('myfile', imagePath));

          var response = await request.send();

          if (response.statusCode == 200 || response.statusCode == 201) {
            item['synced'] = true;
            await box.put(key, item);
          }
        } catch (e) {
          debugPrint('Image sync failed for $jobId: $e');
        }
      }
    }
  }
}
