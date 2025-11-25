import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class DogProfile {
  final String dogId;
  TextEditingController nameController;
  TextEditingController breedController;
  TextEditingController ageController;
  String? selectedGender;
  bool isExpanded;

  DogProfile({String? dogId, this.isExpanded = true})
    : dogId = dogId ?? const Uuid().v4(),
      nameController = TextEditingController(),
      breedController = TextEditingController(),
      ageController = TextEditingController();

  void dispose() {
    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'dogId': dogId,
      'name': nameController.text,
      'breed': breedController.text,
      'age': ageController.text,
      'selectedGender': selectedGender,
      'isExpanded': isExpanded,
    };
  }

  factory DogProfile.fromMap(Map<String, dynamic> map) {
    final profile = DogProfile(
      dogId: map['dogId'],
      isExpanded: map['isExpanded'] ?? true,
    );
    profile.nameController.text = map['name'] ?? '';
    profile.breedController.text = map['breed'] ?? '';
    profile.ageController.text = map['age'] ?? '';
    profile.selectedGender = map['selectedGender'];
    return profile;
  }
}
