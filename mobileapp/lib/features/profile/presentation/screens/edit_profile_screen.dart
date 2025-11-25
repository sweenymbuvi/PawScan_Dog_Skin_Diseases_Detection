import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pawscan/features/auth/data/models/user_model.dart';
import 'package:pawscan/features/auth/data/repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepo = UserRepository.instance;
  final _auth = FirebaseAuth.instance;

  TextEditingController? _fullNameController;
  TextEditingController? _emailController;

  UserModel? _user;
  bool _loading = true;

  // Track which dog profiles are expanded
  List<bool> _expandedStates = [];

  // Controllers for dog profiles
  List<TextEditingController> dogNameControllers = [];
  List<TextEditingController> dogBreedControllers = [];
  List<TextEditingController> dogAgeControllers = [];
  List<String> dogGenderValues = [];
  List<String> dogIds = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    final user = await _userRepo.getUserDetails(email);
    setState(() {
      _user = user;
      _fullNameController = TextEditingController(text: user.fullName);
      _emailController = TextEditingController(text: user.email);
      _initializeDogControllers();
      _loading = false;
    });
  }

  void _initializeDogControllers() {
    dogNameControllers = _user!.dogProfiles
        .map((dog) => TextEditingController(text: dog.name))
        .toList();
    dogBreedControllers = _user!.dogProfiles
        .map((dog) => TextEditingController(text: dog.breed))
        .toList();
    dogAgeControllers = _user!.dogProfiles
        .map((dog) => TextEditingController(text: dog.age.toString()))
        .toList();
    dogGenderValues = _user!.dogProfiles.map((dog) => dog.gender).toList();
    dogIds = _user!.dogProfiles.map((dog) => dog.dogId).toList();
    _expandedStates = List.generate(_user!.dogProfiles.length, (_) => false);
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedStates[index] = !_expandedStates[index];
    });
  }

  void _addDogProfile() {
    setState(() {
      // Generate a unique ID for the new dog profile
      final newDogId = 'dog_${DateTime.now().millisecondsSinceEpoch}';

      dogNameControllers.add(TextEditingController());
      dogBreedControllers.add(TextEditingController());
      dogAgeControllers.add(TextEditingController());
      dogGenderValues.add('Male'); // Default gender
      dogIds.add(newDogId);
      _expandedStates.add(true); // Open the new profile by default
    });
  }

  void _removeDogProfile(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Dog Profile',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        content: Text(
          'Are you sure you want to delete ${dogNameControllers[index].text.isEmpty ? "this dog profile" : dogNameControllers[index].text}?',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                dogNameControllers[index].dispose();
                dogBreedControllers[index].dispose();
                dogAgeControllers[index].dispose();

                dogNameControllers.removeAt(index);
                dogBreedControllers.removeAt(index);
                dogAgeControllers.removeAt(index);
                dogGenderValues.removeAt(index);
                dogIds.removeAt(index);
                _expandedStates.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Inter', color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController?.dispose();
    _emailController?.dispose();
    for (var controller in dogNameControllers) {
      controller.dispose();
    }
    for (var controller in dogBreedControllers) {
      controller.dispose();
    }
    for (var controller in dogAgeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5CD15A)),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

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
                'Edit My Profile',
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
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name Label & Field
                    const Text(
                      "Full Name",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Color(0xFFE8E8E8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Enter full name"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Email Label & Field
                    const Text(
                      "Email Address",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Color(0xFFE8E8E8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter email" : null,
                    ),
                    const SizedBox(height: 24),

                    // Dog Profiles Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Dog Profiles",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addDogProfile,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Dog'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CD15A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Collapsible Dog Profiles
                    if (dogNameControllers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.pets_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No dog profiles yet',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Add Dog" to create a profile',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dogNameControllers.length,
                        itemBuilder: (context, index) {
                          return _buildDogProfileCard(
                            index,
                            dogNameControllers[index],
                            dogBreedControllers[index],
                            dogAgeControllers[index],
                            dogGenderValues[index],
                          );
                        },
                      ),
                    const SizedBox(height: 80), // Space for fixed buttons
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Validate that at least one dog profile exists
                          if (dogNameControllers.isEmpty) {
                            Get.snackbar(
                              "Error",
                              "Please add at least one dog profile",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Validate all dog profiles have required fields
                          for (int i = 0; i < dogNameControllers.length; i++) {
                            if (dogNameControllers[i].text.trim().isEmpty ||
                                dogBreedControllers[i].text.trim().isEmpty ||
                                dogAgeControllers[i].text.trim().isEmpty) {
                              Get.snackbar(
                                "Error",
                                "Please fill in all fields for Dog Profile ${i + 1}",
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                          }

                          // Update dog profiles from controllers
                          final updatedDogProfiles = List.generate(
                            dogNameControllers.length,
                            (index) {
                              return DogProfile(
                                dogId: dogIds[index],
                                name: dogNameControllers[index].text.trim(),
                                breed: dogBreedControllers[index].text.trim(),
                                age:
                                    int.tryParse(
                                      dogAgeControllers[index].text.trim(),
                                    ) ??
                                    0,
                                gender: dogGenderValues[index],
                              );
                            },
                          );

                          // Update user
                          final updatedUser = UserModel(
                            id: _user!.id,
                            fullName: _fullNameController!.text.trim(),
                            email: _emailController!.text.trim(),
                            password: _user!.password,
                            dogProfiles: updatedDogProfiles,
                          );

                          await _userRepo.updateUserRecord(updatedUser);
                          Get.snackbar(
                            "Success",
                            "Profile updated successfully",
                            backgroundColor: const Color(0xFF5CD15A),
                            colorText: Colors.white,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CD15A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Update Profile",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2D2D2D),
                        side: const BorderSide(
                          color: Color(0xFF2D2D2D),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogProfileCard(
    int index,
    TextEditingController nameController,
    TextEditingController breedController,
    TextEditingController ageController,
    String genderValue,
  ) {
    String displayName = nameController.text.isEmpty
        ? 'Dog Profile ${index + 1}'
        : nameController.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Collapsed Header
          InkWell(
            onTap: () => _toggleExpanded(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5CD15A).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: Color(0xFF5CD15A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        if (breedController.text.isNotEmpty)
                          Text(
                            breedController.text,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () => _removeDogProfile(index),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    splashRadius: 20,
                    tooltip: 'Delete dog profile',
                  ),
                  Icon(
                    _expandedStates[index]
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF2D2D2D),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_expandedStates[index])
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dog Name
                  const Text(
                    "Dog Name",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                      hintText: 'Dog Name',
                      prefixIcon: Icon(Icons.pets),
                      filled: true,
                      fillColor: Color(0xFFE8E8E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter dog name"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Breed
                  const Text(
                    "Breed",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: breedController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'Breed',
                      prefixIcon: Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Color(0xFFE8E8E8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter breed" : null,
                  ),
                  const SizedBox(height: 12),

                  // Age and Gender Row
                  Row(
                    children: [
                      // Age
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Age",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Age',
                                prefixIcon: Icon(Icons.cake_outlined),
                                filled: true,
                                fillColor: Color(0xFFE8E8E8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? "Enter age"
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Gender
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Gender",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: genderValue.isNotEmpty
                                  ? genderValue
                                  : null,
                              decoration: const InputDecoration(
                                hintText: 'Gender',
                                prefixIcon: Icon(Icons.wc_outlined),
                                filled: true,
                                fillColor: Color(0xFFE8E8E8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: ['Male', 'Female'].map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    dogGenderValues[index] = value;
                                  }
                                });
                              },
                              validator: (value) =>
                                  value == null ? "Select gender" : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
