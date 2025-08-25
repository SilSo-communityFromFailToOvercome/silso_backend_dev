import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetProfilePicture extends StatefulWidget {
  final double size;
  final String? petId; // Optional override for specific pet ID
  final String? userId; // Optional override for specific user
  
  const PetProfilePicture({
    super.key,
    required this.size,
    this.petId,
    this.userId,
  });

  @override
  State<PetProfilePicture> createState() => _PetProfilePictureState();
}

class _PetProfilePictureState extends State<PetProfilePicture> {
  String _selectedPetId = '5.0'; // Default silpet with no outfit
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      // If pet ID is provided, use it directly or convert from legacy format
      if (widget.petId!.startsWith('pet')) {
        // Legacy format (e.g., "pet5") - convert to new format
        final petNumber = widget.petId!.replaceAll('pet', '');
        _selectedPetId = '$petNumber.0'; // Default to no outfit
      } else {
        // New format (e.g., "5.0" or "5.4")
        _selectedPetId = widget.petId!;
      }
      _isLoading = false;
    } else {
      // Load user's selected pet
      _loadUserPetSelection();
    }
  }

  Future<void> _loadUserPetSelection() async {
    try {
      final targetUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUserId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .get();
        
        if (doc.exists && doc.data()?['selectedPet'] != null) {
          if (mounted) {
            setState(() {
              final petNumber = doc.data()!['selectedPet'];
              final petOutfit = doc.data()?['selectedPetOutfit'] ?? 0;
              _selectedPetId = '$petNumber.$petOutfit'; // Combine pet number and outfit
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading pet selection: $e');
    }
  }

  String _buildPetImagePath(String petId) {
    // Parse pet ID (e.g., "5.0" or "5.4")
    final parts = petId.split('.');
    if (parts.length == 2) {
      final petNumber = parts[0];
      // Map pet number to folder name
      final folderName = _getPetFolderName(petNumber);
      return 'images/silpets/$folderName/$petId.png';
    } else {
      // Fallback for invalid format
      return 'images/silpets/5_yellow/5.0.png';
    }
  }

  String _getPetFolderName(String petNumber) {
    switch (petNumber) {
      case '1':
        return '1_red';
      case '2':
        return '2_blue';
      case '3':
        return '3_green';
      case '4':
        return '4_cyan';
      case '5':
        return '5_yellow';
      case '6':
        return '6_green';
      case '7':
        return '7_pink';
      case '8':
        return '8_orange';
      case '9':
        return '9_grey';
      case '10':
        return '10_purple';
      case '11':
        return '11_purplish';
      default:
        return '5_yellow';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE0E0E0),
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.3,
            height: widget.size * 0.3,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E8E)),
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(widget.size * 0.05),
        child: Image.asset(
          _buildPetImagePath(_selectedPetId),
          width: widget.size * 0.9,
          height: widget.size * 0.9,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: widget.size * 0.9,
              height: widget.size * 0.9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFBBBBBB),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: widget.size * 0.4,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Static version for when you already have the pet ID and don't need to load from Firestore
class StaticPetProfilePicture extends StatelessWidget {
  final double size;
  final String petId;
  
  const StaticPetProfilePicture({
    super.key,
    required this.size,
    required this.petId,
  });

  String _buildPetImagePath(String petId) {
    // Parse pet ID (e.g., "5.0" or "5.4")
    final parts = petId.split('.');
    if (parts.length == 2) {
      final petNumber = parts[0];
      // Map pet number to folder name
      final folderName = _getPetFolderName(petNumber);
      return 'images/silpets/$folderName/$petId.png';
    } else {
      // Fallback for invalid format
      return 'images/silpets/5_yellow/5.0.png';
    }
  }

  String _getPetFolderName(String petNumber) {
    switch (petNumber) {
      case '1':
        return '1_red';
      case '2':
        return '2_blue';
      case '3':
        return '3_green';
      case '4':
        return '4_cyan';
      case '5':
        return '5_yellow';
      case '6':
        return '6_green';
      case '7':
        return '7_pink';
      case '8':
        return '8_orange';
      case '9':
        return '9_grey';
      case '10':
        return '10_purple';
      case '11':
        return '11_purplish';
      default:
        return '5_yellow';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * 0.05),
        child: Image.asset(
          _buildPetImagePath(petId),
          width: size * 0.9,
          height: size * 0.9,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFBBBBBB),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: size * 0.4,
              ),
            );
          },
        ),
      ),
    );
  }
}