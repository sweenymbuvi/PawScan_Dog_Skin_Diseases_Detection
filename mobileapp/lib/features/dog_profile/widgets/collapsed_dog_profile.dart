import 'package:flutter/material.dart';
import '../data/models/dog_profile_model.dart';

class CollapsedDogProfile extends StatelessWidget {
  final DogProfile profile;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onToggle;

  const CollapsedDogProfile({
    Key? key,
    required this.profile,
    required this.index,
    required this.onRemove,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String displayName = profile.nameController.text.isEmpty
        ? 'Dog Profile ${index + 1}'
        : profile.nameController.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5CD15A).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets, color: Color(0xFF5CD15A), size: 24),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        subtitle: profile.breedController.text.isNotEmpty
            ? Text(
                profile.breedController.text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                splashRadius: 20,
              ),
            IconButton(
              onPressed: onToggle,
              icon: const Icon(Icons.keyboard_arrow_down),
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
