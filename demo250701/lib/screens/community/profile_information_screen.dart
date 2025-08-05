import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/community_service.dart';
import '../../models/country_data.dart';
import 'phone_verification_screen.dart';

class ProfileInformationScreen extends StatefulWidget {
  const ProfileInformationScreen({super.key});

  @override
  State<ProfileInformationScreen> createState() => _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen>
    with TickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedCountry;
  String? _selectedGender;
  DateTime? _selectedBirthdate;
  bool _isLoading = false;
  CountryData? _selectedCountryData;
  
  // Animation controllers
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize with default country (South Korea)
    _selectedCountryData = CountryService.defaultCountry;
    _selectedCountry = _selectedCountryData?.name;
    
    // Initialize animations
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.67, // 2/3 progress for second step
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start progress animation
    _progressAnimationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _buttonAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _triggerButtonAnimation() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
  }

  /// Handle country selection and update phone field
  void _onCountrySelected(String? countryName) {
    if (countryName == null) return;
    
    final countryData = CountryService.getCountryByName(countryName);
    if (countryData == null) return;
    
    setState(() {
      _selectedCountry = countryName;
      _selectedCountryData = countryData;
    });
    
    // Update phone field with country code if it's empty
    if (_phoneController.text.isEmpty) {
      _phoneController.text = '+${countryData.phoneCode} ';
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: _phoneController.text.length),
      );
    } else {
      // If phone field has content, try to update country code
      _updatePhoneWithCountryCode(countryData);
    }
    
    _triggerButtonAnimation();
  }

  /// Update phone field with new country code
  void _updatePhoneWithCountryCode(CountryData countryData) {
    String currentPhone = _phoneController.text;
    
    // Remove existing country code if present
    if (currentPhone.startsWith('+')) {
      final spaceIndex = currentPhone.indexOf(' ');
      if (spaceIndex != -1) {
        currentPhone = currentPhone.substring(spaceIndex + 1);
      }
    }
    
    // Add new country code
    _phoneController.text = '+${countryData.phoneCode} $currentPhone';
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneController.text.length),
    );
  }

  /// Format phone number as user types
  void _onPhoneChanged(String value) {
    if (_selectedCountryData == null) return;
    
    // Don't format if user is editing the country code part
    if (!value.startsWith('+${_selectedCountryData!.phoneCode}')) {
      return;
    }
    
    // Extract just the phone number part (after country code)
    final countryCodePart = '+${_selectedCountryData!.phoneCode} ';
    if (value.length <= countryCodePart.length) return;
    
    final phoneNumber = value.substring(countryCodePart.length);
    final formattedPhone = _selectedCountryData!.formatPhoneNumber(phoneNumber);
    
    final newValue = countryCodePart + formattedPhone;
    
    if (newValue != value) {
      _phoneController.value = TextEditingValue(
        text: newValue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newValue.length),
        ),
      );
    }
    
    _triggerButtonAnimation();
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F37CF),
              onPrimary: Colors.white,
              surface: Color(0xFFFAFAFA),
              onSurface: Color(0xFF121212),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
      _triggerButtonAnimation();
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null || _selectedGender == null || _selectedBirthdate == null) {
      _showValidationError('필수 정보 누락', '모든 필수 항목을 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get properly formatted phone number with country code
      String formattedPhoneNumber = _phoneController.text.trim();
      if (_selectedCountryData != null && !formattedPhoneNumber.startsWith('+')) {
        formattedPhoneNumber = _selectedCountryData!.getFullPhoneNumber(formattedPhoneNumber);
      }
      
      // Save profile information
      await _communityService.saveProfileInformation(
        name: _nameController.text.trim(),
        country: _selectedCountry!,
        birthdate: _selectedBirthdate!.toIso8601String().split('T')[0],
        gender: _selectedGender!,
        phoneNumber: formattedPhoneNumber,
      );
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhoneVerificationScreen(
              phoneNumber: _phoneController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showValidationError('오류', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showValidationError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFF5F37CF),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 393.0;
    final double widthRatio = screenWidth / baseWidth;
    final bool isFormValid = _nameController.text.isNotEmpty && 
                            _selectedCountry != null && 
                            _selectedGender != null && 
                            _selectedBirthdate != null && 
                            _phoneController.text.isNotEmpty;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context, widthRatio),
      body: Column(
        children: [
          Expanded(
            child: _buildMainContent(context, widthRatio),
          ),
          _buildBottomButton(context, widthRatio, isFormValid),
        ],
      ),
    );
  }

  /// Build app bar with progress indicator
  PreferredSizeWidget _buildAppBar(BuildContext context, double widthRatio) {
    return AppBar(
      backgroundColor: const Color(0xFFFAFAFA),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: const Color(0xFFE0E0E0),
                    color: const Color(0xFF5F37CF),
                    minHeight: 8,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content area
  Widget _buildMainContent(BuildContext context, double widthRatio) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60 * widthRatio),
              
              // Title
              Text(
                '개인정보를\n입력해주세요',
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 24 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.21,
                ),
              ),
              
              SizedBox(height: 16 * widthRatio),

              // Subtitle
              Text(
                '더 나은 커뮤니티 경험을 위해 필요한 정보입니다',
                style: TextStyle(
                  color: const Color(0xFFC7C7C7),
                  fontSize: 16 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.39,
                ),
              ),

              SizedBox(height: 32 * widthRatio),

              // Form Fields
              _buildNameField(widthRatio),
              SizedBox(height: 20 * widthRatio),
              
              _buildCountryDropdown(widthRatio),
              SizedBox(height: 20 * widthRatio),
              
              _buildBirthdateField(widthRatio),
              SizedBox(height: 20 * widthRatio),
              
              _buildGenderDropdown(widthRatio),
              SizedBox(height: 20 * widthRatio),
              
              _buildPhoneField(widthRatio),
              SizedBox(height: 40 * widthRatio),
            ],
          ),
        ),
      ),
    );
  }

  /// Build name input field
  Widget _buildNameField(double widthRatio) {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(
        color: const Color(0xFF121212),
        fontFamily: 'Pretendard',
        fontSize: 16 * widthRatio,
      ),
      decoration: InputDecoration(
        labelText: '이름',
        labelStyle: TextStyle(
          color: const Color(0xFFC7C7C7),
          fontFamily: 'Pretendard',
          fontSize: 16 * widthRatio,
        ),
        filled: true,
        fillColor: Colors.white,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * widthRatio,
        ),
      ),
      onChanged: (value) => _triggerButtonAnimation(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '이름을 입력해주세요';
        }
        return null;
      },
    );
  }

  /// Build country dropdown
  Widget _buildCountryDropdown(double widthRatio) {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      style: TextStyle(
        color: const Color(0xFF121212),
        fontFamily: 'Pretendard',
        fontSize: 16 * widthRatio,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: '국가',
        labelStyle: TextStyle(
          color: const Color(0xFFC7C7C7),
          fontFamily: 'Pretendard',
          fontSize: 16 * widthRatio,
        ),
        filled: true,
        fillColor: Colors.white,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * widthRatio,
        ),
      ),
      items: CountryService.availableCountries.map((countryData) {
        return DropdownMenuItem(
          value: countryData.name,
          child: Row(
            children: [
              Text(
                countryData.flag,
                style: TextStyle(fontSize: 20 * widthRatio),
              ),
              SizedBox(width: 8 * widthRatio),
              Expanded(
                child: Text(
                  countryData.name,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16 * widthRatio,
                  ),
                ),
              ),
              Text(
                '+${countryData.phoneCode}',
                style: TextStyle(
                  color: const Color(0xFFC7C7C7),
                  fontFamily: 'Pretendard',
                  fontSize: 14 * widthRatio,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: _onCountrySelected,
      validator: (value) {
        if (value == null) {
          return '국가를 선택해주세요';
        }
        return null;
      },
    );
  }

  /// Build birthdate selection field
  Widget _buildBirthdateField(double widthRatio) {
    return GestureDetector(
      onTap: _selectBirthdate,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * widthRatio,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * widthRatio),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedBirthdate != null
                  ? '${_selectedBirthdate!.year}년 ${_selectedBirthdate!.month}월 ${_selectedBirthdate!.day}일'
                  : '생년월일 선택',
              style: TextStyle(
                color: _selectedBirthdate != null 
                    ? const Color(0xFF121212)
                    : const Color(0xFFC7C7C7),
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: const Color(0xFFC7C7C7),
              size: 20 * widthRatio,
            ),
          ],
        ),
      ),
    );
  }

  /// Build gender dropdown
  Widget _buildGenderDropdown(double widthRatio) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      style: TextStyle(
        color: const Color(0xFF121212),
        fontFamily: 'Pretendard',
        fontSize: 16 * widthRatio,
      ),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: '성별',
        labelStyle: TextStyle(
          color: const Color(0xFFC7C7C7),
          fontFamily: 'Pretendard',
          fontSize: 16 * widthRatio,
        ),
        filled: true,
        fillColor: Colors.white,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * widthRatio,
        ),
      ),
      items: CommunityService.availableGenders.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedGender = value);
        _triggerButtonAnimation();
      },
      validator: (value) {
        if (value == null) {
          return '성별을 선택해주세요';
        }
        return null;
      },
    );
  }

  /// Build phone number input field
  Widget _buildPhoneField(double widthRatio) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(
        color: const Color(0xFF121212),
        fontFamily: 'Pretendard',
        fontSize: 16 * widthRatio,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
      ],
      decoration: InputDecoration(
        labelText: '전화번호',
        hintText: _selectedCountryData?.phonePlaceholder ?? '010-1234-5678',
        hintStyle: TextStyle(
          color: const Color(0xFFC7C7C7),
          fontFamily: 'Pretendard',
          fontSize: 16 * widthRatio,
        ),
        labelStyle: TextStyle(
          color: const Color(0xFFC7C7C7),
          fontFamily: 'Pretendard',
          fontSize: 16 * widthRatio,
        ),
        prefixIcon: _selectedCountryData != null
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * widthRatio, vertical: 16 * widthRatio),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountryData!.flag,
                      style: TextStyle(fontSize: 18 * widthRatio),
                    ),
                    SizedBox(width: 4 * widthRatio),
                    Text(
                      '+${_selectedCountryData!.phoneCode}',
                      style: TextStyle(
                        color: const Color(0xFF5F37CF),
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * widthRatio,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * widthRatio,
        ),
      ),
      onChanged: _onPhoneChanged,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '전화번호를 입력해주세요';
        }
        
        if (_selectedCountryData != null) {
          // Remove country code for validation
          String phoneOnly = value;
          if (phoneOnly.startsWith('+${_selectedCountryData!.phoneCode}')) {
            phoneOnly = phoneOnly.substring('+${_selectedCountryData!.phoneCode} '.length);
          }
          
          if (!_selectedCountryData!.isValidPhoneNumber(phoneOnly)) {
            return '올바른 ${_selectedCountryData!.name} 전화번호를 입력해주세요';
          }
        } else {
          if (value.trim().length < 10) {
            return '올바른 전화번호를 입력해주세요';
          }
        }
        
        return null;
      },
    );
  }

  /// Build bottom continue button with animation
  Widget _buildBottomButton(BuildContext context, double widthRatio, bool canProceed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0 * widthRatio),
      child: AnimatedBuilder(
        animation: _buttonScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: canProceed ? _buttonScaleAnimation.value : 0.98,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: (_isLoading || !canProceed) ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canProceed 
                      ? const Color(0xFF5F37CF) 
                      : const Color(0xFFBDBDBD),
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
                  elevation: canProceed ? 2 : 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '계속하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: canProceed 
                              ? Colors.white 
                              : const Color(0xFFEEEEEE),
                          fontSize: 18 * widthRatio,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.23,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}