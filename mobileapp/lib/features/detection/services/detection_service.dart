import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:pawscan/features/detection/data/models/detection_result_model.dart';

class DetectionService {
  // CHANGE THIS TO YOUR API URL
  // Android Emulator: 'http://10.0.2.2:8000'
  // iOS Simulator: 'http://localhost:8000'
  // Real Device: 'http://YOUR_COMPUTER_IP:8000'
  // Production: 'https://your-api.com'

  static const String baseUrl =
      'https://pawscan-dog-skin-diseases-detection.onrender.com';

  Future<DetectionResult> analyzeImages(List<XFile> images) async {
    if (images.isEmpty) {
      throw Exception('No images provided');
    }

    try {
      var uri = Uri.parse('$baseUrl/analyze_files');
      var request = http.MultipartRequest('POST', uri);

      // Add all images to request
      for (int i = 0; i < images.length; i++) {
        var file = await http.MultipartFile.fromPath(
          'files',
          images[i].path,
          filename: 'image_$i.jpg',
        );
        request.files.add(file);
      }

      print('📤 Sending ${images.length} images to API...');

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Server took too long to respond.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Analysis successful: ${jsonData['disease']}');
        return DetectionResult.fromJson(jsonData);
      } else {
        throw Exception(
          'Server error: ${response.statusCode}\n${response.body}',
        );
      }
    } on SocketException {
      throw Exception(
        'Network error: Cannot connect to server.\n\nMake sure:\n1. Your API is running\n2. You\'re using the correct IP address\n3. Firewall allows connection',
      );
    } on TimeoutException {
      throw Exception('Request timeout: Server took too long to respond.');
    } catch (e) {
      print('❌ Error analyzing images: $e');
      rethrow;
    }
  }
}
