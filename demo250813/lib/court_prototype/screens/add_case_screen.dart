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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: Text(
          '사건 제출',
          style: TextStyle(
            fontSize: 20 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF121212)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24 * widthRatio),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guidelines section
                      _buildGuidelinesSection(widthRatio),
                      
                      SizedBox(height: 32 * widthRatio),
                      
                      // Category selection
                      _buildCategorySection(widthRatio),
                      
                      SizedBox(height: 24 * widthRatio),
                      
                      // Title field
                      _buildTitleField(widthRatio),
                      
                      SizedBox(height: 24 * widthRatio),
                      
                      // Description field
                      _buildDescriptionField(widthRatio),
                      
                      SizedBox(height: 32 * widthRatio),
                      
                      // Voting info card
                      _buildVotingInfoCard(widthRatio),
                    ],
                  ),
                ),
              ),
              
              // Submit button
              _buildSubmitButton(widthRatio),
            ],
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
        color: const Color(0xFF5F37CF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12 * widthRatio),
        border: Border.all(
          color: const Color(0xFF5F37CF).withValues(alpha: 0.2),
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
                color: const Color(0xFF5F37CF),
                size: 20 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '좋은 사건 제출 가이드',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F37CF),
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
              color: const Color(0xFF5F37CF),
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
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 12 * widthRatio),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * widthRatio),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CaseCategory>(
              value: _selectedCategory,
              isExpanded: true,
              style: TextStyle(
                fontSize: 16 * widthRatio,
                color: const Color(0xFF121212),
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
                        style: TextStyle(fontSize: 16 * widthRatio),
                      ),
                      SizedBox(width: 8 * widthRatio),
                      Text(category.displayName),
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

  // Build title field
  Widget _buildTitleField(double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사건 제목',
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 8 * widthRatio),
        TextFormField(
          controller: _titleController,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: '예: "원격근무가 사무실 근무보다 생산적인가?"',
            hintStyle: TextStyle(
              fontSize: 16 * widthRatio,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
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
            counterStyle: TextStyle(
              fontSize: 12 * widthRatio,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          style: TextStyle(
            fontSize: 16 * widthRatio,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
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
      ],
    );
  }

  // Build description field
  Widget _buildDescriptionField(double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사건 설명',
          style: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 8 * widthRatio),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: '배경 정보, 쟁점, 고려할 요소들을 상세히 설명해주세요...',
            hintStyle: TextStyle(
              fontSize: 16 * widthRatio,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
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
            counterStyle: TextStyle(
              fontSize: 12 * widthRatio,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          style: TextStyle(
            fontSize: 16 * widthRatio,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
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
      ],
    );
  }

  // Build voting info card
  Widget _buildVotingInfoCard(double widthRatio) {
    return Container(
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12 * widthRatio),
        border: Border.all(
          color: const Color(0xFF2196F3).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                color: const Color(0xFF2196F3),
                size: 20 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '투표 시스템 안내',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2196F3),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * widthRatio),
          Text(
            '• 투표 기간: ${CourtSystemConfig.caseExpiryDays}일\n'
            '• 승급 조건: ${CourtSystemConfig.minVotesForPromotion}표 이상 + ${CourtSystemConfig.controversyRatioMin.toInt()}-${CourtSystemConfig.controversyRatioMax.toInt()}% 비율\n'
            '• 승급 시 법정 토론으로 진행 (${CourtSystemConfig.sessionDurationHours}시간)\n'
            '• 일일 사건 제출 한도: ${CourtSystemConfig.maxCasesCreatedPerDay}개',
            style: TextStyle(
              fontSize: 12 * widthRatio,
              color: const Color(0xFF2196F3),
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Build submit button
  Widget _buildSubmitButton(double widthRatio) {
    return Padding(
      padding: EdgeInsets.all(24 * widthRatio),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCreating ? null : _submitCase,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F37CF),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * widthRatio),
            ),
            elevation: 2,
          ),
          child: _isCreating
              ? SizedBox(
                  height: 20 * widthRatio,
                  width: 20 * widthRatio,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '사건 제출하기',
                  style: TextStyle(
                    fontSize: 16 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
        ),
      ),
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