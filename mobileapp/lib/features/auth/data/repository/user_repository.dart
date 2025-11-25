import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:pawscan/features/auth/data/models/user_model.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final _firestore = FirebaseFirestore.instance;

  final _db = FirebaseFirestore.instance;
  // store user in Firestore

  Future<void> createUser(UserModel user) async {
    if (user.id == null || user.id!.isEmpty) {
      Get.snackbar(
        "Error",
        "User ID (UID) is required to create user document.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.red,
      );
      throw Exception("User ID (UID) is required");
    }
    await _db
        .collection("Users")
        .doc(user.id)
        .set(user.toJson())
        .then((value) {
          Get.snackbar(
            "Success",
            "Your account has been created",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
          );
        })
        .catchError((error) {
          Get.snackbar(
            "Error",
            "Something went wrong. Try again",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withOpacity(0.1),
            colorText: Colors.red,
          );
          print(error.toString());
        });
  }

  // Fetch all users/ user details
  Future<UserModel> getUserDetails(String email) async {
    final snapshot = await _db
        .collection("Users")
        .where("email", isEqualTo: email)
        .get();
    final userData = snapshot.docs.map((e) => UserModel.fromSnapshot(e)).first;
    return userData;
  }

  Future<List<UserModel>> allUsers() async {
    final snapshot = await _db.collection("Users").get();
    final userData = snapshot.docs
        .map((e) => UserModel.fromSnapshot(e))
        .toList();
    return userData;
  }

  //Update
  Future<void> updateUserRecord(UserModel user) async {
    await _db.collection("Users").doc(user.id).update(user.toJson());
  }

  Future<void> updateUserProfilePic(String email, String profilePicUrl) async {
    final snapshot = await _firestore
        .collection('Users')
        .where('Email', isEqualTo: email)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await _firestore.collection('Users').doc(docId).update({
        'ProfilePicUrl': profilePicUrl,
      });
    }

    // Corrected uploadImage method
    // Future<String> uploadImage(String path, XFile image) async {
    //   try {
    //     final ref = FirebaseStorage.instance.ref(path).child(image.name);
    //     // Upload the file to Firebase Storage
    //     await ref.putFile(File(image.path));
    //     // Get the download URL for the uploaded image
    //     final url = await ref.getDownloadURL();
    //     return url;
    //   } on FirebaseException catch (e) {
    //     // Handle Firebase specific errors
    //     print("FirebaseException: ${e.message}");
    //     throw e.message ?? "An error occurred while uploading the image.";
    //   } catch (e) {
    //     // Handle other errors
    //     print("Exception: $e");
    //     throw "Something went wrong. Please try again.";
    //   }
    // }
  }
}
