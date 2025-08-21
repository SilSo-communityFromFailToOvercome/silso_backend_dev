import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('새 비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual password change logic with AuthService
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessSnackBar('비밀번호가 성공적으로 변경되었습니다.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('비밀번호 변경에 실패했습니다: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          '비밀번호 변경',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20 * widthRatio),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10 * heightRatio),
                
                // Instructions text
                Text(
                  '비밀번호는 최소 6자 이상이어야 하며 숫자, 영문, 특수 문자(\$@\$%*)의 조합을 포함해야 합니다.',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: 30 * heightRatio),
                
                // Current Password Field
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: '현재 비밀번호',
                  isPasswordVisible: _isCurrentPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '현재 비밀번호를 입력해주세요';
                    }
                    return null;
                  },
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),
                
                SizedBox(height: 20 * heightRatio),
                
                // New Password Field
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: '새 비밀번호',
                  isPasswordVisible: _isNewPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '새 비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 최소 6자 이상이어야 합니다';
                    }
                    // Basic password strength validation
                    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]').hasMatch(value)) {
                      return '영문, 숫자, 특수문자(\$@\$%*)를 포함해야 합니다';
                    }
                    return null;
                  },
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),
                
                SizedBox(height: 20 * heightRatio),
                
                // Confirm New Password Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: '새 비밀번호 재입력',
                  isPasswordVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '새 비밀번호를 다시 입력해주세요';
                    }
                    if (value != _newPasswordController.text) {
                      return '새 비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                  widthRatio: widthRatio,
                  heightRatio: heightRatio,
                ),
                
                SizedBox(height: 50 * heightRatio),
                
                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 52 * heightRatio,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F37CF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * widthRatio),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20 * widthRatio,
                            height: 20 * widthRatio,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '비밀번호 변경 완료',
                            style: TextStyle(
                              fontSize: 16 * widthRatio,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isPasswordVisible,
    required VoidCallback onVisibilityToggle,
    required String? Function(String?) validator,
    required double widthRatio,
    required double heightRatio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 8 * heightRatio),
        TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          validator: validator,
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(
                color: Color(0xFF5F37CF),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * widthRatio,
              vertical: 16 * heightRatio,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF8E8E8E),
                size: 20 * widthRatio,
              ),
              onPressed: onVisibilityToggle,
            ),
            hintText: '비밀번호를 입력해주세요',
            hintStyle: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCCCCCC),
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }
}