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
      'readyToSync': false, // Draft mode by default
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
      'readyToSync': false,
      'dbId': dbId,
    };
    
    if (existingKey != null) {
      await box.put(existingKey, payload);
    } else {
      await box.add(payload);
    }
    
    notifyListeners();
  }

  Future<void> submitSurvey(String jobId) async {
    final box = Hive.box('surveyQueue');
    final item = box.get(jobId);
    if (item != null) {
      item['readyToSync'] = true;
      await box.put(jobId, item);
    }
    
    final imgBox = Hive.box('imageQueue');
    for (var key in imgBox.keys) {
      final img = imgBox.get(key);
      if (img != null && img['jobId'] == jobId) {
        img['readyToSync'] = true;
        await imgBox.put(key, img);
      }
    }
    
    await syncPendingSurveys();
  }


  Future<void> syncPendingSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return; // Cannot sync without token

    final box = Hive.box('surveyQueue');
    for (var key in box.keys) {
      final item = box.get(key);
      if (item != null && item['synced'] == false && item['readyToSync'] == true) {
        String bankName = item['bankName'];
        String jobId = item['jobId'];
        String dbId = item['dbId'] ?? jobId; // fallback for older items
        Map<String, dynamic> payload = Map<String, dynamic>.from(item['payload']);

        String apiBankName = bankName == 'OTHERS' ? 'Others' : bankName;
        String endpoint = '$baseUrl/storeReportData$apiBankName/$dbId';

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
      if (item != null && item['synced'] == false && item['readyToSync'] == true) {
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

          String ext = imagePath.split('.').last;
          if (ext.length > 4 || !imagePath.contains('.')) ext = 'jpg';
          
          request.files.add(await http.MultipartFile.fromPath(
            'myfile', 
            imagePath,
            filename: 'upload.$ext',
          ));

          var response = await request.send();

          if (response.statusCode == 200 || response.statusCode == 201) {
            item['synced'] = true;
            item['error'] = null; // Clear error
            await box.put(key, item);
          } else {
            final respStr = await response.stream.bytesToString();
            debugPrint('Failed to sync image, status: ${response.statusCode}, body: $respStr');
            item['error'] = 'Err: ${response.statusCode}';
            await box.put(key, item);
          }
        } catch (e) {
          debugPrint('Sync image failed: $e');
          item['error'] = 'Net Err';
          await box.put(key, item);
        }
      }
    }
  }
}
