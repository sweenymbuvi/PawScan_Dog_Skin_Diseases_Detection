import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageUploadArea extends StatelessWidget {
  final VoidCallback onTap;

  const ImageUploadArea({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF5CD15A),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF5CD15A).withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5CD15A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                size: 48,
                color: Color(0xFF5CD15A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to add images',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5CD15A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera or Gallery',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
