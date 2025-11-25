import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawscan/features/auth/data/models/user_model.dart' as models;
import 'package:pawscan/features/auth/data/repository/user_repository.dart';
import '../../data/models/dog_profile_model.dart';

import '../../widgets/collapsed_dog_profile.dart';
import '../../widgets/expanded_dog_profile.dart';

class CreateDogProfileScreen extends StatefulWidget {
  const CreateDogProfileScreen({super.key});

  @override
  State<CreateDogProfileScreen> createState() => _CreateDogProfileScreenState();
}

class _CreateDogProfileScreenState extends State<CreateDogProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<DogProfile> _dogProfiles = []; // UI DogProfile list
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    // Add first dog profile by default
    _addDogProfile();
  }

  @override
  void dispose() {
    for (var profile in _dogProfiles) {
      profile.dispose();
    }
    super.dispose();
  }

  void _addDogProfile() {
    setState(() {
      _dogProfiles.add(DogProfile(isExpanded: true));
    });
  }

  void _removeDogProfile(int index) {
    setState(() {
      final profile = _dogProfiles[index];
      profile.dispose();
      _dogProfiles.removeAt(index);
    });
  }

  void _toggleExpansion(int index) {
    setState(() {
      final profile = _dogProfiles[index];
      profile.isExpanded = !profile.isExpanded;
    });
  }

  void _saveDogProfiles() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get the current authenticated user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null || currentUser.email == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated. Please log in.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final email = currentUser.email!;

        // Fetch the current user model from Firestore
        final currentUserModel = await UserRepository.instance.getUserDetails(
          email,
        );

        // Map UI DogProfile objects to data DogProfile objects
        final updatedDogProfiles = _dogProfiles
            .map(
              (uiProfile) => models.DogProfile(
                dogId:
                    uiProfile.dogId, // Ensure dogId is available in DogProfile
                name: uiProfile.nameController.text.trim(),
                breed: uiProfile.breedController.text.trim(),
                gender: uiProfile.selectedGender ?? '',
                age: int.tryParse(uiProfile.ageController.text.trim()) ?? 0,
              ),
            )
            .toList();

        // Create an updated UserModel with the new dog profiles
        final updatedUser = models.UserModel(
          id: currentUserModel.id,
          fullName: currentUserModel.fullName,
          email: currentUserModel.email,
          password:
              currentUserModel.password, // Ensure passwords are hashed securely
          dogProfiles: updatedDogProfiles,
        );

        // Update the user record in Firestore
        await UserRepository.instance.updateUserRecord(updatedUser);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dog profiles saved successfully!'),
            backgroundColor: Color(0xFF5CD15A),
          ),
        );

        // Navigate to the home screen
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        // Handle errors (e.g., network issues, Firestore errors)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dog profiles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _skipForNow() {
    // Navigate to home screen without saving
    Navigator.pushReplacementNamed(context, '/home');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can add dog profile later from settings'),
      ),
    );
  }

  Widget _buildCollapsedProfile(DogProfile profile, int index) {
    return CollapsedDogProfile(
      profile: profile,
      index: index,
      onRemove: () => _removeDogProfile(index),
      onToggle: () => _toggleExpansion(index),
    );
  }

  Widget _buildExpandedProfile(DogProfile profile, int index) {
    return ExpandedDogProfile(
      profile: profile,
      index: index,
      onRemove: () => _removeDogProfile(index),
      onToggle: () => _toggleExpansion(index),
      genders: _genders,
      onGenderChanged: (String? newValue) {
        setState(() {
          profile.selectedGender = newValue;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF2D2D2D),
                ),
                splashRadius: 20,
              ),
              const Text(
                'Create Dog Profile',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - 160),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Dog Profiles
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _dogProfiles.length,
                      itemBuilder: (context, index) {
                        final profile = _dogProfiles[index];
                        return profile.isExpanded
                            ? _buildExpandedProfile(profile, index)
                            : _buildCollapsedProfile(profile, index);
                      },
                    ),

                    // Add Another Dog Profile Button
                    GestureDetector(
                      onTap: _addDogProfile,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF5CD15A),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add, color: Color(0xFF5CD15A), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Add Another Dog Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5CD15A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveDogProfiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5CD15A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Dog Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Skip Button
                    Center(
                      child: TextButton(
                        onPressed: _skipForNow,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
