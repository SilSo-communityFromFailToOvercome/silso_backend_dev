import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  // Cache for pet IDs to reduce Firestore calls
  final Map<String, String> _petCache = {};
  
  /// Get the current user's selected pet ID
  Future<String> getCurrentUserPetId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'pet5'; // Default pet
      
      // Check cache first
      if (_petCache.containsKey(user.uid)) {
        return _petCache[user.uid]!;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      String petId = '5.0'; // Default
      if (doc.exists && doc.data()?['selectedPet'] != null) {
        final petNumber = doc.data()!['selectedPet'];
        final petOutfit = doc.data()?['selectedPetOutfit'] ?? 0;
        petId = '$petNumber.$petOutfit'; // Combine pet number and outfit
      }
      
      // Cache the result
      _petCache[user.uid] = petId;
      return petId;
    } catch (e) {
      return '5.0'; // Default on error
    }
  }
  
  /// Get a specific user's pet ID
  Future<String> getUserPetId(String userId) async {
    try {
      // Check cache first
      if (_petCache.containsKey(userId)) {
        return _petCache[userId]!;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      String petId = '5.0'; // Default
      if (doc.exists && doc.data()?['selectedPet'] != null) {
        final petNumber = doc.data()!['selectedPet'];
        final petOutfit = doc.data()?['selectedPetOutfit'] ?? 0;
        petId = '$petNumber.$petOutfit'; // Combine pet number and outfit
      }
      
      // Cache the result
      _petCache[userId] = petId;
      return petId;
    } catch (e) {
      return '5.0'; // Default on error
    }
  }
  
  /// Update the current user's pet selection
  Future<void> updateCurrentUserPet(String petId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'selectedPet': petId});
        
        // Update cache
        _petCache[user.uid] = petId;
      }
    } catch (e) {
      // Handle error silently or log it
      print('Error updating pet selection: $e');
    }
  }
  
  /// Clear the cache (useful when user logs out)
  void clearCache() {
    _petCache.clear();
  }
  
  /// Remove specific user from cache
  void removeCacheEntry(String userId) {
    _petCache.remove(userId);
  }
}