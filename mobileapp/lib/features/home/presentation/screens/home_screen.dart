import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawscan/features/auth/data/repository/user_repository.dart';
import 'package:pawscan/features/detection/data/models/detection_result_model.dart';
import 'package:pawscan/features/detection/data/repository/detection_repository.dart';
import 'package:pawscan/features/detection/presentation/screens/results_screen.dart';
import 'package:pawscan/features/detection/services/detection_service.dart';

import '../../../auth/data/models/user_model.dart';

import '../../widgets/disclaimer_widget.dart';
import '../../widgets/image_source_widget.dart';
import '../../widgets/image_upload_widget.dart';
import '../../widgets/nav_bar.dart';
import '../../widgets/selected_images_grid_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  int _currentNavIndex = 0;

  final DetectionService _detectionService = DetectionService();
  final DetectionRepository _detectionRepo = DetectionRepository.instance;
  final UserRepository _userRepo = UserRepository.instance;

  List<DogProfile> _dogProfiles = [];
  DogProfile? _selectedDog;

  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndDogProfiles();
  }

  Future<void> _loadUserAndDogProfiles() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;

      if (email != null) {
        final user = await _userRepo.getUserDetails(email);

        setState(() {
          _dogProfiles = user.dogProfiles;
          if (_dogProfiles.isNotEmpty) {
            _selectedDog = _dogProfiles.first;
          }
          _loadingUser = false;
        });
      }
    } catch (e) {
      print("❌ Error loading user & dog profiles: $e");
      setState(() => _loadingUser = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick images: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceBottomSheet(
        onCameraSelected: () {
          Navigator.pop(context);
          _pickImageFromCamera();
        },
        onGallerySelected: () {
          Navigator.pop(context);
          _pickImageFromGallery();
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE54D4D),
      ),
    );
  }

  Future<void> _analyzeImages() async {
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please select at least one image');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5CD15A)),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing images...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a moment',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      DetectionResult result = await _detectionService.analyzeImages(
        _selectedImages,
      );

      // ✅ Attach selected dog info before saving
      if (_selectedDog != null) {
        result = result.copyWith(
          dogProfileId: _selectedDog!.dogId,
          dogName: _selectedDog!.name,
        );
      }

      // ✅ Save to Firestore
      await _detectionRepo.saveDetectionResult(result);

      Navigator.pop(context); // close loading dialog

      // ✅ Navigate to results screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultsScreen(result: result)),
      );

      // ✅ Clear selected images
      setState(() => _selectedImages.clear());
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(e.toString());
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _currentNavIndex = index);

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/history');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: const EdgeInsets.only(top: 30),
          padding: const EdgeInsets.only(left: 14, top: 8, right: 8),
          child: const Text(
            'Welcome 👋',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ),
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // ✅ Dog selection dropdown from user model
                      if (_dogProfiles.isNotEmpty) ...[
                        const Text(
                          'Select Dog',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<DogProfile>(
                            value: _selectedDog,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('Select a dog'),
                            items: _dogProfiles.map((dog) {
                              return DropdownMenuItem(
                                value: dog,
                                child: Text('${dog.name} (${dog.breed})'),
                              );
                            }).toList(),
                            onChanged: (dog) => setState(() {
                              _selectedDog = dog;
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ✅ Upload Section
                      const Text(
                        'Upload Dog Images',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Take or upload photos of affected areas',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ImageUploadArea(onTap: _showImageSourceDialog),

                      const SizedBox(height: 20),

                      if (_selectedImages.isNotEmpty) ...[
                        SelectedImagesGrid(
                          images: _selectedImages,
                          onRemoveImage: _removeImage,
                          onClearAll: _clearAllImages,
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _analyzeImages,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5CD15A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Analyze Images',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const DisclaimerWidget(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5CD15A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/find-vets');
          },
          icon: const Icon(Icons.location_on, color: Colors.white, size: 20),
          label: const Text(
            'Find Vets',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5CD15A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}
