import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../models/magazine_model.dart';

class MagazineService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Collection name for magazine data
  static const String magazineCollection = 'silso_magazine_posts';

  // Check authentication status
  bool get isAuthenticated => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;

  // Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw 'Failed to pick image: ${e.toString()}';
    }
  }

  // Create a new magazine post
  Future<String> createMagazinePost(CreateMagazinePostRequest request) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated. Please sign in to create posts.';
      }

      // Get next order number
      final nextOrder = await _getNextOrderNumber();
      
      final docRef = await _firestore.collection(magazineCollection).add(
        request.toMap(currentUserId!).map((key, value) {
          if (key == 'order') return MapEntry(key, request.order ?? nextOrder);
          return MapEntry(key, value);
        })
      );

      if (kDebugMode) {
        print('✅ Created magazine post: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create magazine post: $e');
      }
      throw 'Failed to create magazine post: ${e.toString()}';
    }
  }

  // Get next order number for posts
  Future<int> _getNextOrderNumber() async {
    try {
      final snapshot = await _firestore
          .collection(magazineCollection)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return 0;
      }
      
      final highestOrder = snapshot.docs.first.data()['order'] as int? ?? 0;
      return highestOrder + 1;
    } catch (e) {
      return 0;
    }
  }

  // Upload image to magazine post
  Future<String> uploadImageToMagazinePost({
    required XFile imageFile,
    required String postId,
  }) async {
    try {
      // Check authentication first
      if (!isAuthenticated) {
        throw 'User not authenticated. Please sign in to upload images.';
      }

      // Debug logging
      if (kDebugMode) {
        print('🔄 Starting magazine image upload...');
        print('   Platform: ${kIsWeb ? "Web" : "Native"}');
        print('   Post ID: $postId');
        print('   File name: ${imageFile.name}');
        print('   File size: ${await imageFile.length()} bytes');
      }

      // Create unique file name
      final String fileName = 'magazine_${postId}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.name)}';
      final String filePath = 'magazine/$postId/$fileName';
      
      if (kDebugMode) {
        print('   Storage path: $filePath');
      }
      
      // Get reference to Firebase Storage
      final Reference ref = _storage.ref().child(filePath);
      
      // Platform-specific upload logic
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web: Use putData with bytes
        if (kDebugMode) {
          print('   Using putData for web platform');
        }
        
        final Uint8List imageBytes = await imageFile.readAsBytes();
        
        final metadata = SettableMetadata(
          contentType: 'image/${_getImageExtension(imageFile.name)}',
          customMetadata: {
            'uploadedBy': currentUserId!,
            'postId': postId,
            'platform': 'web',
            'uploadDate': DateTime.now().toIso8601String(),
          },
        );
        
        uploadTask = ref.putData(imageBytes, metadata);
      } else {
        // Mobile/Desktop: Use putFile with File
        if (kDebugMode) {
          print('   Using putFile for native platform');
        }
        
        final File file = File(imageFile.path);
        
        if (!await file.exists()) {
          throw 'Selected file does not exist at path: ${imageFile.path}';
        }
        
        final metadata = SettableMetadata(
          contentType: 'image/${_getImageExtension(imageFile.name)}',
          customMetadata: {
            'uploadedBy': currentUserId!,
            'postId': postId,
            'platform': 'native',
            'uploadDate': DateTime.now().toIso8601String(),
          },
        );
        
        uploadTask = ref.putFile(file, metadata);
      }
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (kDebugMode) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('   Upload progress: ${progress.toStringAsFixed(1)}%');
        }
      });
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      if (kDebugMode) {
        print('   Upload completed!');
        print('   Bytes transferred: ${snapshot.bytesTransferred}');
      }
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('   Download URL obtained: ${downloadUrl.substring(0, 50)}...');
      }

      // Add image URL to post
      await _addImageToPost(postId, downloadUrl);
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Error: ${e.code} - ${e.message}');
      }
      
      String userFriendlyMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          userFriendlyMessage = 'You don\'t have permission to upload images.';
          break;
        case 'storage/canceled':
          userFriendlyMessage = 'Upload was canceled.';
          break;
        case 'storage/quota-exceeded':
          userFriendlyMessage = 'Storage quota exceeded. Please try again later.';
          break;
        case 'storage/unauthenticated':
          userFriendlyMessage = 'Please sign in to upload images.';
          break;
        default:
          userFriendlyMessage = 'Upload failed: ${e.message ?? 'Unknown error'}';
          break;
      }
      
      throw userFriendlyMessage;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Generic Error: ${e.toString()}');
      }
      
      if (kIsWeb && e.toString().contains('CORS')) {
        throw 'CORS error: Please configure Firebase Storage CORS settings.';
      }
      
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw 'Network error: Please check your internet connection and try again.';
      }
      
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  // Add image URL to existing post
  Future<void> _addImageToPost(String postId, String imageUrl) async {
    try {
      await _firestore.collection(magazineCollection).doc(postId).update({
        'imageUrls': FieldValue.arrayUnion([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('   Image URL added to post: $postId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add image URL to post: $e');
      }
      // Don't throw here as the image upload was successful
    }
  }

  // Get all magazine posts
  Future<List<MagazinePost>> getAllMagazinePosts() async {
    try {
      final snapshot = await _firestore
          .collection(magazineCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      
      return snapshot.docs.map((doc) {
        return MagazinePost.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get magazine posts: $e');
      }
      return [];
    }
  }

  // Get single magazine post
  Future<MagazinePost?> getMagazinePost(String postId) async {
    try {
      final doc = await _firestore.collection(magazineCollection).doc(postId).get();
      
      if (doc.exists) {
        return MagazinePost.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get magazine post: $e');
      }
      return null;
    }
  }

  // Update magazine post
  Future<void> updateMagazinePost(String postId, UpdateMagazinePostRequest request) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated. Please sign in to update posts.';
      }

      await _firestore.collection(magazineCollection).doc(postId).update(request.toMap());
      
      if (kDebugMode) {
        print('✅ Updated magazine post: $postId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update magazine post: $e');
      }
      throw 'Failed to update magazine post: ${e.toString()}';
    }
  }

  // Delete magazine post
  Future<void> deleteMagazinePost(String postId) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated. Please sign in to delete posts.';
      }

      // Get post to get image URLs
      final post = await getMagazinePost(postId);
      
      // Delete all images from storage
      if (post != null) {
        for (final imageUrl in post.imageUrls) {
          try {
            final Reference ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            // Continue deleting other images even if one fails
            if (kDebugMode) {
              print('⚠️ Failed to delete image: $imageUrl');
            }
          }
        }
      }
      
      // Delete post document
      await _firestore.collection(magazineCollection).doc(postId).delete();
      
      if (kDebugMode) {
        print('✅ Deleted magazine post: $postId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete magazine post: $e');
      }
      throw 'Failed to delete magazine post: ${e.toString()}';
    }
  }

  // Remove specific image from post
  Future<void> removeImageFromPost(String postId, String imageUrl) async {
    try {
      // Remove from storage
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      // Remove from post
      await _firestore.collection(magazineCollection).doc(postId).update({
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Removed image from post: $postId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to remove image from post: $e');
      }
      throw 'Failed to remove image: ${e.toString()}';
    }
  }

  // Get image bytes for preview (Web)
  Future<Uint8List> getImageBytes(XFile imageFile) async {
    return await imageFile.readAsBytes();
  }

  // Get image extension from file name
  String _getImageExtension(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'jpeg';
      case '.png':
        return 'png';
      case '.gif':
        return 'gif';
      case '.webp':
        return 'webp';
      default:
        return 'jpeg'; // Default fallback
    }
  }

  // Validate image file
  bool isValidImageFile(XFile file) {
    final String extension = path.extension(file.name).toLowerCase();
    const List<String> validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return validExtensions.contains(extension);
  }

  // Get maximum file size (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  // Check if file size is valid
  Future<bool> isValidFileSize(XFile file) async {
    final int fileSize = await file.length();
    return fileSize <= maxFileSizeBytes;
  }

  // Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}