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
  final _hashtagController = TextEditingController();
  
  final CommunityService _communityService = CommunityService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;
  bool _isAnonymous = false;
  PostType _selectedPostType = PostType.failure;
  String? _imageUrl;
  XFile? _selectedImage;
  Uint8List? _imageBytes; // For web preview

  @override
  void initState() {
    super.initState();
    print("screens/community/add_post_screen.dart is showing");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _onHashtagChanged(String value) {
    String newValue = value;
    
    // Auto add # at the beginning if not present
    if (newValue.isNotEmpty && !newValue.startsWith('#')) {
      newValue = '#$newValue';
    }
    
    // Handle space to create new hashtag
    if (newValue.endsWith(' ') && newValue.length > 1) {
      newValue = '$newValue#';
    }
    
    // Update the controller if the value changed
    if (newValue != value) {
      _hashtagController.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
      );
    }
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
                content: Text('올바른 이미지 파일을 선택해주세요 (jpg, png, gif, webp)'),
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
                content: Text('이미지 크기가 너무 큽니다. 최대 크기: ${_imageService.formatFileSize(ImageService.maxFileSizeBytes)}'),
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
            content: Text('이미지 선택에 실패했습니다: ${e.toString()}'),
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

  void _showPostTypeDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24), // Balance the close button
                        const Text(
                          '게시 옵션',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF121212),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF8E8E8E),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Section title
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '게시글 유형',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Post type buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedPostType = PostType.freedom);
                              setState(() => _selectedPostType = PostType.freedom);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedPostType == PostType.freedom
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _selectedPostType == PostType.freedom
                                      ? const Color(0xFF121212)
                                      : const Color(0xFFE0E0E0),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '자유',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedPostType == PostType.freedom
                                      ? Colors.white
                                      : const Color(0xFF8E8E8E),
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedPostType = PostType.failure);
                              setState(() => _selectedPostType = PostType.failure);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedPostType == PostType.failure
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _selectedPostType == PostType.failure
                                      ? const Color(0xFF121212)
                                      : const Color(0xFFE0E0E0),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '실패',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedPostType == PostType.failure
                                      ? Colors.white
                                      : const Color(0xFF8E8E8E),
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        postType: _selectedPostType,
      );

      await _communityService.createPost(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시물이 성공적으로 작성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시물 작성에 실패했습니다: ${e.toString()}'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _showPostTypeDropdown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '게시물',
                style: TextStyle(
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '|',
                style: TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedPostType == PostType.failure ? '실패' : '자유',
                style: const TextStyle(
                  color: Color(0xFF121212),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF121212),
                size: 20,
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121212)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
                    ),
                  )
                : const Text(
                    '완료',
                    style: TextStyle(
                      color: Color(0xFF121212),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(
                          color: Color(0xFF121212),
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: '제목을 입력해주세요.',
                          hintStyle: TextStyle(
                            color: Color(0xFFBBBBBB),
                            fontFamily: 'Pretendard',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '제목을 입력해주세요';
                          }
                          if (value.trim().length < 2) {
                            return '제목은 최소 2글자 이상이어야 합니다';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Divider
                      Container(
                        height: 2,
                        color: const Color(0xFFE0E0E0),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Caption Field
                      TextFormField(
                        controller: _captionController,
                        style: const TextStyle(
                          color: Color(0xFF121212),
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                        ),
                        maxLines: null,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: '커뮤니티 사람들과 자유롭게 이야기를 나누어요.',
                          hintStyle: TextStyle(
                            color: Color(0xFFBBBBBB),
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '내용을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      
                      // Hashtag Field
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: TextFormField(
                          controller: _hashtagController,
                          onChanged: _onHashtagChanged,
                          style: const TextStyle(
                            color: Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            height: 1.0,
                          ),
                          decoration: const InputDecoration(
                            hintText: '#회사 #동료 #일상',
                            hintStyle: TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              height: 1.0,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Image Section
                      if (_selectedImage != null) ...[
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImagePreview(),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
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
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Bottom Bar with Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                child: Row(
                  children: [
                    // Image Picker Button
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF8E8E8E),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Anonymous Toggle
                    GestureDetector(
                      onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _isAnonymous ? const Color(0xFF8E8E8E) : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFFBBBBBB),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _isAnonymous
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '익명',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8E8E8E),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            color: const Color(0xFFF5F5F5),
            child: const Icon(
              Icons.broken_image,
              color: Color(0xFF8E8E8E),
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
            color: const Color(0xFFF5F5F5),
            child: const Icon(
              Icons.broken_image,
              color: Color(0xFF8E8E8E),
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
      color: const Color(0xFFF5F5F5),
      child: const Icon(
        Icons.image,
        color: Color(0xFF8E8E8E),
        size: 40,
      ),
    );
  }
}