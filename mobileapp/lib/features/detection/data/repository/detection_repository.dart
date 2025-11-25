import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/detection_result_model.dart';

class DetectionRepository extends GetxController {
  static DetectionRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Save detection result to Firestore
  Future<void> saveDetectionResult(DetectionResult result) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('DetectionHistory')
          .add(result.toFirestore());

      Get.snackbar(
        'Success',
        'Analysis saved to history',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      print('Error saving detection result: $e');
      Get.snackbar(
        'Error',
        'Failed to save to history',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      rethrow;
    }
  }

  // Get all detection history for current user
  Future<List<DetectionResult>> getDetectionHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _db
          .collection('Users')
          .doc(userId)
          .collection('DetectionHistory')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DetectionResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching detection history: $e');
      return [];
    }
  }

  // Get detection history filtered by dog
  Future<List<DetectionResult>> getDetectionHistoryByDog(
    String dogProfileId,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _db
          .collection('Users')
          .doc(userId)
          .collection('DetectionHistory')
          .where('dogProfileId', isEqualTo: dogProfileId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DetectionResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching detection history by dog: $e');
      return [];
    }
  }

  // Stream detection history (real-time updates)
  Stream<List<DetectionResult>> streamDetectionHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('Users')
        .doc(userId)
        .collection('DetectionHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DetectionResult.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete detection result
  Future<void> deleteDetectionResult(String detectionId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('DetectionHistory')
          .doc(detectionId)
          .delete();

      Get.snackbar(
        'Success',
        'Detection result deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      print('Error deleting detection result: $e');
      rethrow;
    }
  }
}
