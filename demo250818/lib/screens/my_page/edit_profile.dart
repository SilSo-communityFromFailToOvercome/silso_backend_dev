import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../widgets/cached_network_image_widget.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web platform
  String? _selectedImageName; // For web platform
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _displayNameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _currentProfileImageUrl = user.photoURL;
        
        // Load additional user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _phoneController.text = userData['phoneNumber'] ?? '';
          _bioController.text = userData['bio'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러올 수 없습니다: ${e.toString()}'),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _selectedImage = null; // Clear file reference for web
          });
        } else {
          // For mobile platforms
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null; // Clear bytes for mobile
            _selectedImageName = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택할 수 없습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) return null;
    
    try {
      setState(() => _isUploading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      
      UploadTask uploadTask;
      
      if (kIsWeb && _selectedImageBytes != null) {
        // For web platform
        uploadTask = storageRef.putData(
          _selectedImageBytes!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uploaded-by': user.uid},
          ),
        );
      } else if (_selectedImage != null) {
        // For mobile platforms
        uploadTask = storageRef.putFile(
          _selectedImage!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uploaded-by': user.uid},
          ),
        );
      } else {
        return null;
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      String? newProfileImageUrl = _currentProfileImageUrl;
      
      // Upload new image if selected
      if (_selectedImage != null || _selectedImageBytes != null) {
        newProfileImageUrl = await _uploadImage();
        if (newProfileImageUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }
      
      // Update Firebase Auth profile
      await user.updateDisplayName(_displayNameController.text.trim());
      if (newProfileImageUrl != null) {
        await user.updatePhotoURL(newProfileImageUrl);
      }
      
      // Update Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'displayName': _displayNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImageUrl': newProfileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 업데이트 실패: ${e.toString()}'),
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
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF121212),
            size: 20 * widthRatio,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '프로필 수정',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '저장',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                color: _isLoading ? const Color(0xFF8E8E8E) : const Color(0xFF5F37CF),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20 * widthRatio),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 20 * heightRatio),
                    
                    // Profile Picture Section
                    _buildProfilePictureSection(widthRatio, heightRatio),
                    
                    SizedBox(height: 40 * heightRatio),
                    
                    // Form Fields
                    _buildFormFields(widthRatio, heightRatio),
                    
                    SizedBox(height: 40 * heightRatio),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(double widthRatio, double heightRatio) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120 * widthRatio,
              height: 120 * widthRatio,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF5F37CF),
                  width: 3 * widthRatio,
                ),
              ),
              child: ClipOval(
                child: _buildSelectedImageWidget(widthRatio),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 36 * widthRatio,
                  height: 36 * widthRatio,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F37CF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2 * widthRatio,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18 * widthRatio,
                  ),
                ),
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16 * heightRatio),
        Text(
          '프로필 사진 변경',
          style: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5F37CF),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultProfilePicture(double widthRatio) {
    return Container(
      width: 120 * widthRatio,
      height: 120 * widthRatio,
      decoration: const BoxDecoration(
        color: Color(0xFFE8E3FF),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 60 * widthRatio,
        color: const Color(0xFF5F37CF),
      ),
    );
  }

  Widget _buildFormFields(double widthRatio, double heightRatio) {
    return Column(
      children: [
        _buildTextField(
          controller: _displayNameController,
          label: '닉네임',
          hintText: '표시될 닉네임을 입력하세요',
          widthRatio: widthRatio,
          heightRatio: heightRatio,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '닉네임을 입력해주세요';
            }
            if (value.trim().length < 2) {
              return '닉네임은 2글자 이상이어야 합니다';
            }
            return null;
          },
        ),
        
        SizedBox(height: 20 * heightRatio),
        
        _buildTextField(
          controller: _emailController,
          label: '이메일',
          hintText: '이메일 주소를 입력하세요',
          enabled: false, // Email usually can't be changed
          widthRatio: widthRatio,
          heightRatio: heightRatio,
        ),
        
        SizedBox(height: 20 * heightRatio),
        
        _buildTextField(
          controller: _phoneController,
          label: '전화번호',
          hintText: '전화번호를 입력하세요',
          keyboardType: TextInputType.phone,
          widthRatio: widthRatio,
          heightRatio: heightRatio,
        ),
        
        SizedBox(height: 20 * heightRatio),
        
        _buildTextField(
          controller: _bioController,
          label: '자기소개',
          hintText: '간단한 자기소개를 입력하세요',
          maxLines: 3,
          widthRatio: widthRatio,
          heightRatio: heightRatio,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required double widthRatio,
    required double heightRatio,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 8 * heightRatio),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w400,
            color: enabled ? const Color(0xFF121212) : const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(color: Color(0xFF5F37CF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(color: Colors.red),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * widthRatio,
              vertical: 16 * heightRatio,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImageWidget(double widthRatio) {
    // Show selected image (priority: selected > current > default)
    if (kIsWeb && _selectedImageBytes != null) {
      // Web platform - show selected bytes
      return Image.memory(
        _selectedImageBytes!,
        width: 120 * widthRatio,
        height: 120 * widthRatio,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _selectedImage != null) {
      // Mobile platform - show selected file
      return Image.file(
        _selectedImage!,
        width: 120 * widthRatio,
        height: 120 * widthRatio,
        fit: BoxFit.cover,
      );
    } else if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
      // Show current profile image from network
      return MobileCompatibleNetworkImage(
        imageUrl: _currentProfileImageUrl!,
        width: 120 * widthRatio,
        height: 120 * widthRatio,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(60 * widthRatio),
        errorWidget: _buildDefaultProfilePicture(widthRatio),
        placeholder: Container(
          width: 120 * widthRatio,
          height: 120 * widthRatio,
          decoration: const BoxDecoration(
            color: Color(0xFFE8E3FF),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    } else {
      // Show default profile picture
      return _buildDefaultProfilePicture(widthRatio);
    }
  }
}