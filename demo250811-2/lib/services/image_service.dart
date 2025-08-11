import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Check authentication status
  bool get isAuthenticated => _auth.currentUser != null;
  
  String? get currentUserId => _auth.currentUser?.uid;

  // Debug Firebase configuration
  Future<Map<String, dynamic>> debugFirebaseConfig() async {
    final debugInfo = <String, dynamic>{};
    
    try {
      debugInfo['platform'] = kIsWeb ? 'web' : 'native';
      debugInfo['authenticated'] = isAuthenticated;
      debugInfo['currentUserId'] = currentUserId;
      debugInfo['firebaseApp'] = _storage.app.name;
      debugInfo['storageBucket'] = _storage.bucket;
      
      // Test basic storage access
      try {
        final testRef = _storage.ref().child('test/connection_test.txt');
        debugInfo['storageAccessible'] = true;
        debugInfo['testRefPath'] = testRef.fullPath;
      } catch (e) {
        debugInfo['storageAccessible'] = false;
        debugInfo['storageError'] = e.toString();
      }
      
      // Check auth token if available
      if (isAuthenticated) {
        try {
          final token = await _auth.currentUser?.getIdToken();
          debugInfo['hasAuthToken'] = token != null;
          debugInfo['tokenLength'] = token?.length ?? 0;
        } catch (e) {
          debugInfo['authTokenError'] = e.toString();
        }
      }
      
    } catch (e) {
      debugInfo['configError'] = e.toString();
    }
    
    return debugInfo;
  }

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

  // Upload image to Firebase Storage with platform-specific logic
  Future<String> uploadPostImage({
    required XFile imageFile,
    required String postId,
    required String userId,
  }) async {
    try {
      // Check authentication first
      if (!isAuthenticated) {
        throw 'User not authenticated. Please sign in to upload images.';
      }

      // Debug logging
      if (kDebugMode) {
        print('🔄 Starting image upload...');
        print('   Platform: ${kIsWeb ? "Web" : "Native"}');
        print('   Authenticated: $isAuthenticated');
        print('   Current User ID: $currentUserId');
        print('   File name: ${imageFile.name}');
        print('   File size: ${await imageFile.length()} bytes');
        print('   User ID: $userId');
        print('   Post ID: $postId');
      }

      // Create unique file name
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.name)}';
      final String filePath = 'posts/$userId/$postId/$fileName';
      
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
        
        if (kDebugMode) {
          print('   Image bytes length: ${imageBytes.length}');
        }
        
        final metadata = SettableMetadata(
          contentType: 'image/${_getImageExtension(imageFile.name)}',
          customMetadata: {
            'uploadedBy': userId,
            'postId': postId,
            'platform': 'web',
          },
        );
        
        if (kDebugMode) {
          print('   Content type: ${metadata.contentType}');
        }
        
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
            'uploadedBy': userId,
            'postId': postId,
            'platform': 'native',
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
      
      if (kDebugMode) {
        print('   Starting upload task...');
      }
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      if (kDebugMode) {
        print('   Upload completed!');
        print('   Bytes transferred: ${snapshot.bytesTransferred}');
        print('   Total bytes: ${snapshot.totalBytes}');
      }
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('   Download URL obtained: ${downloadUrl.substring(0, 50)}...');
      }
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Firebase-specific errors
      if (kDebugMode) {
        print('❌ Firebase Error: ${e.code} - ${e.message}');
        print('   Details: ${e.toString()}');
      }
      
      String userFriendlyMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          userFriendlyMessage = 'You don\'t have permission to upload images. Please check your authentication.';
          break;
        case 'storage/canceled':
          userFriendlyMessage = 'Upload was canceled.';
          break;
        case 'storage/invalid-format':
          userFriendlyMessage = 'Invalid image format. Please use JPG, PNG, GIF, or WebP.';
          break;
        case 'storage/invalid-argument':
          userFriendlyMessage = 'Invalid upload parameters. Please try again.';
          break;
        case 'storage/no-default-bucket':
          userFriendlyMessage = 'No Firebase Storage bucket configured.';
          break;
        case 'storage/object-not-found':
          userFriendlyMessage = 'Upload location not found.';
          break;
        case 'storage/quota-exceeded':
          userFriendlyMessage = 'Storage quota exceeded. Please try again later.';
          break;
        case 'storage/retry-limit-exceeded':
          userFriendlyMessage = 'Upload timeout. Please check your connection and try again.';
          break;
        case 'storage/server-file-wrong-size':
          userFriendlyMessage = 'File size mismatch. Please try selecting the file again.';
          break;
        case 'storage/unauthenticated':
          userFriendlyMessage = 'Please sign in to upload images.';
          break;
        case 'storage/unknown':
        default:
          userFriendlyMessage = 'Upload failed: ${e.message ?? 'Unknown error'}';
          break;
      }
      
      throw userFriendlyMessage;
    } catch (e) {
      // Generic errors
      if (kDebugMode) {
        print('❌ Generic Error: ${e.toString()}');
        print('   Error type: ${e.runtimeType}');
      }
      
      // Check for common web-specific issues
      if (kIsWeb && e.toString().contains('CORS')) {
        throw 'CORS error: Please configure Firebase Storage CORS settings. See CORS_SETUP.md for instructions.';
      }
      
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw 'Network error: Please check your internet connection and try again.';
      }
      
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  // Delete image from Firebase Storage
  Future<void> deletePostImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Handle error silently - image might already be deleted
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