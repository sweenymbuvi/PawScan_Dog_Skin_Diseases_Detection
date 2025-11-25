import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResult {
  final String? id;
  final String disease;
  final double confidence;
  final String severity;
  final String description;
  final List<String> recommendations;
  final DateTime timestamp;
  final String? dogProfileId;
  final String? dogName;
  final int imageCount;

  DetectionResult({
    this.id,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.recommendations,
    DateTime? timestamp,
    this.dogProfileId,
    this.dogName,
    this.imageCount = 1,
  }) : timestamp = timestamp ?? DateTime.now();

  // From FastAPI response
  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'unknown',
      description: json['description'] ?? 'No description available',
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : [],
      imageCount: json['per_image_predictions'] != null
          ? (json['per_image_predictions'] as List).length
          : 1,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'description': description,
      'recommendations': recommendations,
      'timestamp': Timestamp.fromDate(timestamp),
      'dogProfileId': dogProfileId,
      'dogName': dogName,
      'imageCount': imageCount,
    };
  }

  // From Firestore
  factory DetectionResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DetectionResult(
      id: doc.id,
      disease: data['disease'] ?? 'Unknown',
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      severity: data['severity'] ?? 'unknown',
      description: data['description'] ?? '',
      recommendations: List<String>.from(data['recommendations'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      dogProfileId: data['dogProfileId'],
      dogName: data['dogName'],
      imageCount: data['imageCount'] ?? 1,
    );
  }

  // Copy with method for updating
  DetectionResult copyWith({
    String? id,
    String? disease,
    double? confidence,
    String? severity,
    String? description,
    List<String>? recommendations,
    DateTime? timestamp,
    String? dogProfileId,
    String? dogName,
    int? imageCount,
  }) {
    return DetectionResult(
      id: id ?? this.id,
      disease: disease ?? this.disease,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      recommendations: recommendations ?? this.recommendations,
      timestamp: timestamp ?? this.timestamp,
      dogProfileId: dogProfileId ?? this.dogProfileId,
      dogName: dogName ?? this.dogName,
      imageCount: imageCount ?? this.imageCount,
    );
  }
}
