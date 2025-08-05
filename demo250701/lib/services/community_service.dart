import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user has completed community setup
  Future<bool> hasCompletedCommunitySetup() async {
    if (currentUserId == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      
      // Check if all required fields are present
      return data.containsKey('communityInterests') &&
             data.containsKey('profile') &&
             data.containsKey('phoneNumber') &&
             data.containsKey('policyAgreementTimestamp');
    } catch (e) {
      return false;
    }
  }

  // Step A: Save community interests
  Future<void> saveCommunityInterests(List<String> interests) async {
    if (currentUserId == null) throw 'User not authenticated';
    if (interests.length < 3) throw 'Please select at least 3 interests';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'communityInterests': interests,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save interests: ${e.toString()}';
    }
  }

  // Step B: Save profile information
  Future<void> saveProfileInformation({
    required String name,
    required String country,
    required String birthdate,
    required String gender,
    required String phoneNumber,
  }) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'profile': {
          'name': name,
          'country': country,
          'birthdate': birthdate,
          'gender': gender,
        },
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save profile: ${e.toString()}';
    }
  }

  // Step B: Verify phone number (placeholder for Firebase Auth phone verification)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          verificationFailed(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      verificationFailed('Failed to verify phone number: ${e.toString()}');
    }
  }

  // Step B: Link phone credential to current user
  Future<void> linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      await user.linkWithCredential(credential);
    } catch (e) {
      throw 'Failed to link phone number: ${e.toString()}';
    }
  }

  // Step B: Verify SMS code and link phone
  Future<void> verifySMSCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      await linkPhoneCredential(credential);
    } catch (e) {
      throw 'Failed to verify SMS code: ${e.toString()}';
    }
  }

  // Step C: Save policy agreement
  Future<void> agreePolicies() async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'policyAgreementTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save policy agreement: ${e.toString()}';
    }
  }

  // Get user's community profile data
  Future<Map<String, dynamic>?> getCommunityProfile() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // Available community interest categories
  static const List<String> availableInterests = [
    'Technology',
    'Sports',
    'Music',
    'Art & Design',
    'Travel',
    'Food & Cooking',
    'Health & Fitness',
    'Books & Literature',
    'Movies & TV',
    'Gaming',
    'Photography',
    'Fashion',
    'Business',
    'Science',
    'History',
    'Politics',
    'Environment',
    'Education',
    'Parenting',
    'Pets & Animals',
  ];

  // Available countries (simplified list)
  static const List<String> availableCountries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'South Korea',
    'Brazil',
    'Mexico',
    'India',
    'China',
    'Russia',
    'Italy',
    'Spain',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
  ];

  // Available genders
  static const List<String> availableGenders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];
}