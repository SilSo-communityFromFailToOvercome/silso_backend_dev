import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/community_service.dart';
import '../../services/authentication/auth_service.dart';
import '../../services/image_service.dart';
import '../../models/community_model.dart';

class AdminAddCommunityPage extends StatefulWidget {
  const AdminAddCommunityPage({super.key});

  @override
  State<AdminAddCommunityPage> createState() => _AdminAddCommunityPageState();
}

class _AdminAddCommunityPageState extends State<AdminAddCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _communityService = CommunityService();
  final _authService = AuthService();
  final _imageService = ImageService();
  
  // Form controllers
  final _communityNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _announcementController = TextEditingController();
  final _hashtagsController = TextEditingController();
  
  // Image state
  XFile? _selectedBanner;
  Uint8List? _bannerBytes; // For web preview
  bool _isUploading = false;
  String? _uploadedBannerUrl;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("screens/community/admin_add_community.dart is currently showing");
  }

  @override
  void dispose() {
    _communityNameController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  // Pick and preview banner image
  Future<void> _pickBannerImage() async {
    try {
      final XFile? image = await _imageService.pickImage();
      if (image == null) return;

      // Validate file
      if (!_imageService.isValidImageFile(image)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('잘못된 이미지 형식입니다. JPG, PNG, GIF, WebP 파일만 업로드할 수 있습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check file size
      if (!await _imageService.isValidFileSize(image)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일 크기가 너무 큽니다. 5MB 이하의 파일을 선택해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _selectedBanner = image;
      });

      // Load bytes for preview (especially for web)
      if (kIsWeb) {
        final bytes = await _imageService.getImageBytes(image);
        setState(() {
          _bannerBytes = bytes;
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배너 이미지가 선택되었습니다.'),
          backgroundColor: Color(0xFF5F37CF),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload banner image
  Future<String?> _uploadBannerImage() async {
    if (_selectedBanner == null) return null;

    setState(() => _isUploading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw '로그인이 필요합니다.';
      }

      // Create a temporary community ID for upload path
      final communityId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      // Use a modified upload method for community banners
      final bannerUrl = await _uploadCommunityBanner(
        imageFile: _selectedBanner!,
        communityId: communityId,
        userId: currentUser.uid,
      );

      setState(() {
        _uploadedBannerUrl = bannerUrl;
      });

      return bannerUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('배너 업로드에 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Custom method for community banner upload
  Future<String> _uploadCommunityBanner({
    required XFile imageFile,
    required String communityId,
    required String userId,
  }) async {
    // For now, use the existing uploadPostImage method and adapt it
    // In a real implementation, you'd want to add a specific method to ImageService
    return await _imageService.uploadPostImage(
      imageFile: imageFile,
      postId: 'banner_$communityId',
      userId: userId,
    );
  }

  // Get image extension helper
  String _getImageExtension(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }

  // Remove selected banner
  void _removeBanner() {
    setState(() {
      _selectedBanner = null;
      _bannerBytes = null;
      _uploadedBannerUrl = null;
    });
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw '로그인이 필요합니다.';
      }

      String? bannerUrl;

      // Upload banner if selected
      if (_selectedBanner != null) {
        bannerUrl = await _uploadBannerImage();
        if (bannerUrl == null) {
          throw '배너 업로드에 실패했습니다.';
        }
      }

      // Parse hashtags (split by comma and trim)
      final hashtags = _hashtagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create description from both description and announcement fields
      String? finalAnnouncement;
      if (_descriptionController.text.trim().isNotEmpty && 
          _announcementController.text.trim().isNotEmpty) {
        finalAnnouncement = '${_descriptionController.text.trim()}\n\n${_announcementController.text.trim()}';
      } else if (_descriptionController.text.trim().isNotEmpty) {
        finalAnnouncement = _descriptionController.text.trim();
      } else if (_announcementController.text.trim().isNotEmpty) {
        finalAnnouncement = _announcementController.text.trim();
      }

      final request = CreateCommunityRequest(
        communityName: _communityNameController.text.trim(),
        announcement: finalAnnouncement,
        communityBanner: bannerUrl,
        hashtags: hashtags,
      );

      final communityId = await _communityService.createCommunity(request);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('커뮤니티가 성공적으로 생성되었습니다!'),
            backgroundColor: Color(0xFF5F37CF),
          ),
        );

        // Clear form
        _communityNameController.clear();
        _descriptionController.clear();
        _announcementController.clear();
        _hashtagsController.clear();
        _removeBanner();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('커뮤니티 생성에 실패했습니다: ${e.toString()}'),
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
    // Responsive design calculations
    const double designWidth = 393.0;
    const double designHeight = 870.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / designWidth;
    final heightRatio = screenHeight / designHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F37CF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Admin Add Community',
          style: TextStyle(
            color: const Color(0xFF5F37CF),
            fontSize: 20 * widthRatio,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24 * heightRatio),
                
                // Development notice
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16 * widthRatio),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    border: Border.all(color: const Color(0xFFFFE69C)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFF856404)),
                      SizedBox(width: 8 * widthRatio),
                      Expanded(
                        child: Text(
                          'Development Tool - Admin Only',
                          style: TextStyle(
                            color: const Color(0xFF856404),
                            fontSize: 14 * widthRatio,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32 * heightRatio),

                // Community Name Field
                _buildFieldLabel('커뮤니티 이름', true, widthRatio),
                SizedBox(height: 8 * heightRatio),
                _buildTextFormField(
                  controller: _communityNameController,
                  hintText: '커뮤니티 이름을 입력하세요',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '커뮤니티 이름을 입력해주세요';
                    }
                    if (value.trim().length < 2) {
                      return '커뮤니티 이름은 2글자 이상이어야 합니다';
                    }
                    return null;
                  },
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),

                SizedBox(height: 24 * heightRatio),

                // Description Field
                _buildFieldLabel('설명', true, widthRatio),
                SizedBox(height: 8 * heightRatio),
                _buildTextFormField(
                  controller: _descriptionController,
                  hintText: '커뮤니티에 대한 간단한 설명을 입력하세요',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '커뮤니티 설명을 입력해주세요';
                    }
                    if (value.trim().length < 10) {
                      return '설명은 10글자 이상이어야 합니다';
                    }
                    return null;
                  },
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),

                SizedBox(height: 24 * heightRatio),

                // Banner Upload Section
                _buildFieldLabel('배너 이미지', false, widthRatio),
                SizedBox(height: 8 * heightRatio),
                _buildBannerUploadSection(widthRatio, heightRatio),

                SizedBox(height: 24 * heightRatio),

                // Announcement Field
                _buildFieldLabel('공지사항', false, widthRatio),
                SizedBox(height: 8 * heightRatio),
                _buildTextFormField(
                  controller: _announcementController,
                  hintText: '커뮤니티 공지사항을 입력하세요 (선택사항)',
                  maxLines: 3,
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),

                SizedBox(height: 24 * heightRatio),

                // Hashtags Field
                _buildFieldLabel('해시태그', true, widthRatio),
                SizedBox(height: 8 * heightRatio),
                _buildTextFormField(
                  controller: _hashtagsController,
                  hintText: '해시태그를 쉼표로 구분해서 입력하세요 (예: 자영업,창업,취업)',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '최소 1개의 해시태그를 입력해주세요';
                    }
                    return null;
                  },
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),

                SizedBox(height: 8 * heightRatio),
                Text(
                  '쉼표(,)로 구분하여 여러 해시태그를 입력할 수 있습니다',
                  style: TextStyle(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 12 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 40 * heightRatio),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 50 * heightRatio,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createCommunity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F37CF),
                      disabledBackgroundColor: const Color(0xFFC7C7C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20 * widthRatio,
                            height: 20 * widthRatio,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '커뮤니티 생성',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * widthRatio,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 40 * heightRatio),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isRequired, double widthRatio) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: const Color(0xFF121212),
              fontSize: 16 * widthRatio,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
    required double widthRatio,
    required double heightRatio,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        color: const Color(0xFF121212),
        fontSize: 14 * widthRatio,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFC7C7C7),
          fontSize: 14 * widthRatio,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5F37CF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * heightRatio,
        ),
      ),
    );
  }

  Widget _buildBannerUploadSection(double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button or preview
        Container(
          width: double.infinity,
          height: 120 * heightRatio,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedBanner != null ? const Color(0xFF5F37CF) : const Color(0xFFE9E9E9),
              width: _selectedBanner != null ? 2 : 1,
            ),
          ),
          child: _selectedBanner != null ? _buildBannerPreview(widthRatio, heightRatio) : _buildUploadButton(widthRatio, heightRatio),
        ),
        
        SizedBox(height: 8 * heightRatio),
        
        // Helper text
        Text(
          '권장 크기: 1200x400px, 최대 5MB (JPG, PNG, GIF, WebP)',
          style: TextStyle(
            color: const Color(0xFF8E8E8E),
            fontSize: 12 * widthRatio,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        
        // Upload status
        if (_isUploading) ...[
          SizedBox(height: 8 * heightRatio),
          Row(
            children: [
              SizedBox(
                width: 16 * widthRatio,
                height: 16 * widthRatio,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '배너 이미지 업로드 중...',
                style: TextStyle(
                  color: const Color(0xFF5F37CF),
                  fontSize: 12 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUploadButton(double widthRatio, double heightRatio) {
    return InkWell(
      onTap: _pickBannerImage,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32 * widthRatio,
              color: const Color(0xFFC7C7C7),
            ),
            SizedBox(height: 8 * heightRatio),
            Text(
              '배너 이미지 업로드',
              style: TextStyle(
                color: const Color(0xFF8E8E8E),
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4 * heightRatio),
            Text(
              '클릭하여 이미지를 선택하세요',
              style: TextStyle(
                color: const Color(0xFFC7C7C7),
                fontSize: 12 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPreview(double widthRatio, double heightRatio) {
    return Stack(
      children: [
        // Image preview
        Container(
          width: double.infinity,
          height: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb && _bannerBytes != null
                ? Image.memory(
                    _bannerBytes!,
                    fit: BoxFit.cover,
                  )
                : _selectedBanner != null
                    ? Image.file(
                        File(_selectedBanner!.path),
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(),
          ),
        ),
        
        // Dark overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Remove button
        Positioned(
          top: 8 * heightRatio,
          right: 8 * widthRatio,
          child: GestureDetector(
            onTap: _removeBanner,
            child: Container(
              padding: EdgeInsets.all(4 * widthRatio),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16 * widthRatio,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Change button
        Positioned(
          bottom: 8 * heightRatio,
          right: 8 * widthRatio,
          child: GestureDetector(
            onTap: _pickBannerImage,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * widthRatio,
                vertical: 6 * heightRatio,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF5F37CF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '변경',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}