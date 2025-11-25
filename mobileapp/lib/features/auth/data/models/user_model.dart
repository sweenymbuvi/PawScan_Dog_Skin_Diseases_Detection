import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    List<DogProfile>? dogProfiles,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      dogProfiles: dogProfiles ?? this.dogProfiles,
    );
  }

  final String? id;
  final String fullName;
  final String email;
  final String password;
  final List<DogProfile> dogProfiles;

  const UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.password,
    this.dogProfiles = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "fullName": fullName,
      "email": email,
      "password": password,
      "dogProfiles": dogProfiles.map((dog) => dog.toJson()).toList(),
    };
  }

  factory UserModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return UserModel(
      id: document.id,
      fullName: data["fullName"],
      email: data["email"],
      password: data["password"],
      dogProfiles:
          (data["dogProfiles"] as List<dynamic>?)
              ?.map((item) => DogProfile.fromMap(item))
              .toList() ??
          [],
    );
  }
}

class DogProfile {
  final String dogId;
  final String name;
  final String breed;
  final String gender;
  final int age;

  const DogProfile({
    required this.dogId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.age,
  });

  Map<String, dynamic> toJson() {
    return {
      "dogId": dogId,
      "name": name,
      "breed": breed,
      "gender": gender,
      "age": age,
    };
  }

  factory DogProfile.fromMap(Map<String, dynamic> map) {
    return DogProfile(
      dogId: map["dogId"] ?? "",
      name: map["name"] ?? "",
      breed: map["breed"] ?? "",
      gender: map["gender"] ?? "",
      age: map["age"] ?? 0,
    );
  }
}
