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
  String _selectedPetId = 'pet5'; // Default pet
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.petId != null) {
      // If pet ID is provided, use it directly
      _selectedPetId = widget.petId!;
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
              _selectedPetId = doc.data()!['selectedPet'];
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
      child: Image.asset(
        'images/pets/$_selectedPetId.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFBBBBBB),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          );
        },
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'images/pets/$petId.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFBBBBBB),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: size * 0.5,
            ),
          );
        },
      ),
    );
  }
}