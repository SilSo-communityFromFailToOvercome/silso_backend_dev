import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/community_service.dart';
import 'policy_agreement_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final CommunityService _communityService = CommunityService();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _verificationId;
  bool _isLoading = false;
  bool _isCodeSent = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    print("screens/community/phone_verification_screen.dart is showing");
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isLoading = true);

    try {
      await _communityService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        codeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
            _isLoading = false;
            _resendCountdown = 60;
          });
          _startCountdown();
        },
        verificationFailed: (error) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startCountdown();
      }
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification ID not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _communityService.verifySMSCode(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PolicyAgreementScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
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
          'Phone Verification',
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Verify your phone number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification code to ${widget.phoneNumber}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (_isCodeSent) ...[
                // Verification Code Input
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                    ),
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return 'Please enter the 6-digit code';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Resend Code Button
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'Resend code in ${_resendCountdown}s',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        )
                      : TextButton(
                          onPressed: _sendVerificationCode,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ] else ...[
                // Loading state
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sending verification code...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Verify Button
              if (_isCodeSent)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify & Continue',
                            style: TextStyle(
                              fontSize: 18,
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
    );
  }
}