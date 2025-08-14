import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../config/court_config.dart';
import '../models/case_model.dart';

// Screen for submitting new cases to the voting system
class AddCaseScreen extends StatefulWidget {
  const AddCaseScreen({super.key});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final CaseService _caseService = CaseService();
  
  CaseCategory _selectedCategory = CaseCategory.general;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / 393.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          '게시글',
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAFAFA),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFFAFAFA)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _submitCase,
            child: _isCreating
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(
                    '제출',
                    style: TextStyle(
                      color: const Color(0xFFFAFAFA),
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * widthRatio),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  style: TextStyle(
                    fontSize: 20 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFAFAFA),
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                    hintText: '제목을 입력해주세요.',
                    hintStyle: TextStyle(
                      fontSize: 20 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '사건 제목을 입력해주세요';
                    }
                    if (value.trim().length < 10) {
                      return '제목은 최소 10자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                                SizedBox(height: 24 * widthRatio),
                //SizedBox(height: 12 * widthRatio),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: null,
                  minLines: 10,
                  maxLength: 1000,
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFAFAFA),
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                    hintText: '재판소에 올릴 자신의 사건을 등록해주세요.',
                    hintStyle: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFBDBDBD),
                      fontFamily: 'Pretendard',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    counterStyle: TextStyle(
                      fontSize: 12 * widthRatio,
                      color: const Color(0xFFBDBDBD),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '사건 설명을 입력해주세요';
                    }
                    if (value.trim().length < 20) {
                      return '설명은 최소 20자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24 * widthRatio),
                _buildCategorySection(widthRatio),
                SizedBox(height: 24 * widthRatio),
               SizedBox(height: 24 * widthRatio),
                _buildGuidelinesSection(widthRatio),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build guidelines section
  Widget _buildGuidelinesSection(double widthRatio) {
    return Container(
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: const   Color(0xFFFAFAFA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12 * widthRatio),
        border: Border.all(
          color: const Color(0xFFFAFAFA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFFFAFAFA),
                size: 20 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '좋은 사건 제출 가이드',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFAFAFA),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * widthRatio),
          Text(
            '• 논쟁의 여지가 있는 주제를 선택하세요\n'
            '• 명확하고 이해하기 쉬운 제목을 작성하세요\n'
            '• 충분한 배경 정보를 제공하세요\n'
            '• 개인 공격이나 차별적 내용은 피해주세요\n'
            '• 사실에 기반한 내용을 작성해주세요',
            style: TextStyle(
              fontSize: 12 * widthRatio,
              color: const Color(0xFFFAFAFA),
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Build category selection
  Widget _buildCategorySection(double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFAFAFA),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 12 * widthRatio),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E), // Dark background for dropdown
            borderRadius: BorderRadius.circular(12 * widthRatio),
            border: Border.all(
              color: const Color(0xFF424242), // Darker border
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CaseCategory>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: const Color(0xFF2E2E2E), // Dropdown menu background
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFFBDBDBD),
                size: 24 * widthRatio,
              ),
              style: TextStyle(
                fontSize: 16 * widthRatio,
                color: const Color(0xFFFAFAFA), // Text color for selected item
                fontFamily: 'Pretendard',
              ),
              onChanged: (CaseCategory? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
              items: CaseCategory.values.map((category) {
                return DropdownMenuItem<CaseCategory>(
                  value: category,
                  child: Row(
                    children: [
                      Text(
                        category.iconData,
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFFFAFAFA),
                        ),
                      ),
                      SizedBox(width: 8 * widthRatio),
                      Text(
                        category.displayName,
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          color: const Color(0xFFFAFAFA),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Submit case
  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final caseId = await _caseService.createCase(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory.name,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '사건이 성공적으로 제출되었습니다! (ID: ${caseId.substring(0, 8)}...)',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navigate back to case list
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '사건 제출 실패: ${e.toString()}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFE57373),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}