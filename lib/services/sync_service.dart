import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class SyncService extends ChangeNotifier {
  Future<void> saveSurvey(String jobId, Map<String, dynamic> data) async {
    final box = Hive.box('surveyQueue');
    await box.put(jobId, {'jobId': jobId, 'payload': data, 'synced': false});
    notifyListeners();
  }

  Future<void> queueImage({
    required String jobId,
    required String imagePath,
    required String imageType,
  }) async {
    final box = Hive.box('imageQueue');
    await box.add({
      'jobId': jobId,
      'imagePath': imagePath,
      'imageType': imageType,
      'synced': false,
    });
    notifyListeners();
  }

  Future<void> syncPendingSurveys() async {
    // Sync stub
  }
}
