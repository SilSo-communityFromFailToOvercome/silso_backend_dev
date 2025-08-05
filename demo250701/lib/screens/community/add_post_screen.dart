import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/community_service.dart';
import '../../services/image_service.dart';
import '../../models/post_model.dart';
import '../../models/community_model.dart';
import '../../widgets/firebase_debug_widget.dart';
import '../../widgets/cors_test_widget.dart';

class AddPostScreen extends StatefulWidget {
  final Community community;

  const AddPostScreen({
    super.key,
    required this.community,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  
  final CommunityService _communityService = CommunityService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;
  bool _isAnonymous = false;
  String? _imageUrl;
  XFile? _selectedImage;
  Uint8List? _imageBytes; // For web preview

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imageService.pickImage();
      if (image != null) {
        // Validate file type and size
        if (!_imageService.isValidImageFile(image)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image file (jpg, png, gif, webp)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!await _imageService.isValidFileSize(image)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image size too large. Maximum size is ${_imageService.formatFileSize(ImageService.maxFileSizeBytes)}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // For web, get bytes for preview
        Uint8List? imageBytes;
        if (kIsWeb) {
          imageBytes = await _imageService.getImageBytes(image);
        }

        setState(() {
          _selectedImage = image;
          _imageBytes = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _imageUrl = null;
    });
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? uploadedImageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        // Create a temporary post ID for the image upload path
        final tempPostId = DateTime.now().millisecondsSinceEpoch.toString();
        uploadedImageUrl = await _imageService.uploadPostImage(
          imageFile: _selectedImage!,
          postId: tempPostId,
          userId: _communityService.currentUserId!,
        );
      }

      final request = CreatePostRequest(
        communityId: widget.community.communityId,
        title: _titleController.text.trim(),
        caption: _captionController.text.trim(),
        anonymous: _isAnonymous,
        imageUrl: uploadedImageUrl,
      );

      await _communityService.createPost(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Community Info Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.post_add,
                            size: 32,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posting to',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  widget.community.communityName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title Field
                _buildSectionTitle('Post Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _buildInputDecoration(
                    'What would you like to share?',
                    Icons.title,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.trim().length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Caption Field
                _buildSectionTitle('Caption'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: _buildInputDecoration(
                    'Share more details about your experience...',
                    Icons.description,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Caption is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Image Upload Section
                _buildSectionTitle('Image (Optional)'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _pickImage,
                              child: const Text(
                                'Add Image',
                                style: TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImagePreview(),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Anonymous Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        color: _isAnonymous 
                            ? const Color(0xFF6C5CE7) 
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Post Anonymously',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your identity will be hidden from other members',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() => _isAnonymous = value);
                        },
                        activeColor: const Color(0xFF6C5CE7),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Debug Widgets (temporary - remove in production)
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  const FirebaseDebugWidget(),
                  const SizedBox(height: 16),
                  const CorsTestWidget(),
                  const SizedBox(height: 24),
                ],
                
                // Create Post Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Create Post',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();

    if (kIsWeb && _imageBytes != null) {
      // Web: Use Image.memory with bytes
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withValues(alpha: 0.1),
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
      );
    } else if (!kIsWeb) {
      // Mobile/Desktop: Use Image.file
      return Image.file(
        File(_selectedImage!.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withValues(alpha: 0.1),
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
      );
    }

    // Fallback
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.1),
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6C5CE7),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF6C5CE7),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }
}