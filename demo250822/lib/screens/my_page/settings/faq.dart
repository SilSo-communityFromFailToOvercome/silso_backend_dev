import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/faq.dart';
import '../../../services/faq_service.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();
  
  // Backend service
  final FAQService _faqService = FAQService();
  
  // Loading states
  bool _isSubmitting = false;
  
  // Stream for user questions
  Stream<List<FAQ>>? _userQuestionsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUserQuestions();
  }

  void _initializeUserQuestions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userQuestionsStream = _faqService.getUserQuestions(user.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    _attachmentController.dispose();
    super.dispose();
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
          '문의하기',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5F37CF),
          labelColor: const Color(0xFF5F37CF),
          unselectedLabelColor: const Color(0xFF8E8E8E),
          labelStyle: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16 * widthRatio,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
          tabs: const [
            Tab(text: '문의하기'),
            Tab(text: '나의 문의 내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitTab(widthRatio, heightRatio),
          _buildHistoryTab(widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildSubmitTab(double widthRatio, double heightRatio) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20 * widthRatio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          _buildFormField(
            label: '이름',
            controller: _nameController,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
          ),
          
          SizedBox(height: 20 * heightRatio),
          
          // Email field
          _buildFormField(
            label: '이메일',
            controller: _emailController,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
          ),
          
          SizedBox(height: 20 * heightRatio),
          
          // Birth date field
          _buildFormField(
            label: '생년월일',
            controller: _birthDateController,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          
          SizedBox(height: 20 * heightRatio),
          
          // Category field
          _buildFormField(
            label: '제목',
            controller: _categoryController,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
          ),
          
          SizedBox(height: 20 * heightRatio),
          
          // Content field
          _buildFormField(
            label: '문의내용',
            controller: _contentController,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
            maxLines: 8,
            height: 120 * heightRatio,
          ),
          
          SizedBox(height: 20 * heightRatio),
          
          // Attachment field
          _buildFormField(
            label: '첨부파일',
            controller: _attachmentController,
            widthRatio: widthRatio,
            heightRatio: heightRatio,
            readOnly: true,
            suffixIcon: Icons.attach_file,
            onTap: () => _selectAttachment(),
          ),
          
          SizedBox(height: 40 * heightRatio),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F37CF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * widthRatio),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16 * widthRatio,
                          height: 16 * widthRatio,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8 * widthRatio),
                        Text(
                          '접수 중...',
                          style: TextStyle(
                            fontSize: 16 * widthRatio,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '제출하기',
                      style: TextStyle(
                        fontSize: 16 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(double widthRatio, double heightRatio) {
    if (_userQuestionsStream == null) {
      return _buildEmptyState(widthRatio, heightRatio);
    }
    
    return StreamBuilder<List<FAQ>>(
      stream: _userQuestionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64 * widthRatio,
                  color: const Color(0xFFFF6B6B),
                ),
                SizedBox(height: 16 * heightRatio),
                Text(
                  '문의 내역을 불러올 수 없습니다',
                  style: TextStyle(
                    fontSize: 16 * widthRatio,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 8 * heightRatio),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFCCCCCC),
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final questions = snapshot.data ?? [];
        
        if (questions.isEmpty) {
          return _buildEmptyState(widthRatio, heightRatio);
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16 * widthRatio),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return _buildHistoryItem(question, widthRatio, heightRatio);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 64 * widthRatio,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            '문의 내역이 없습니다',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * heightRatio),
          Text(
            '궁금한 점이 있으시면 언제든 문의해 주세요',
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCCCCCC),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(FAQ record, double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * heightRatio),
      padding: EdgeInsets.all(20 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * widthRatio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * widthRatio,
                  vertical: 4 * heightRatio,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F37CF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4 * widthRatio),
                ),
                child: Text(
                  record.category,
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F37CF),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * widthRatio,
                  vertical: 4 * heightRatio,
                ),
                decoration: BoxDecoration(
                  color: record.status.name == 'answered'
                      ? const Color(0xFF059669).withValues(alpha: 0.1)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4 * widthRatio),
                ),
                child: Text(
                  record.status.displayText,
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: record.status.name == 'answered'
                        ? const Color(0xFF059669)
                        : const Color(0xFFF59E0B),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12 * heightRatio),
          
          // Question title
          Text(
            record.question,
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          
          SizedBox(height: 8 * heightRatio),
          
          // Question content
          Text(
            record.content,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 12 * heightRatio),
          
          // Date
          Text(
            DateFormat('yyyy.MM.dd').format(record.submitDate),
            style: TextStyle(
              fontSize: 13 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          
          // Answer if available
          if (record.answer != null) ...[
            SizedBox(height: 16 * heightRatio),
            Container(
              padding: EdgeInsets.all(12 * widthRatio),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 16 * widthRatio,
                        color: const Color(0xFF5F37CF),
                      ),
                      SizedBox(width: 4 * widthRatio),
                      Text(
                        '답변',
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5F37CF),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * heightRatio),
                  Text(
                    record.answer!,
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required double widthRatio,
    required double heightRatio,
    int maxLines = 1,
    double? height,
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 8 * heightRatio),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * widthRatio),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12 * widthRatio),
              hintText: label == '문의내용' ? '문의하실 내용을 상세히 적어주세요' : '',
              hintStyle: TextStyle(
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFCCCCCC),
                fontFamily: 'Pretendard',
              ),
              suffixIcon: suffixIcon != null
                  ? Icon(
                      suffixIcon,
                      color: const Color(0xFF8E8E8E),
                      size: 20 * widthRatio,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F37CF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _selectAttachment() {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('파일 첨부 기능은 준비 중입니다'),
        backgroundColor: Color(0xFF5F37CF),
      ),
    );
  }

  Future<void> _submitQuestion() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 항목을 모두 입력해 주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create FAQ submission
      final submission = FAQSubmission(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        category: _categoryController.text.trim(),
        question: _categoryController.text.trim(),
        content: _contentController.text.trim(),
        birthDate: _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
      );

      // Submit to backend
      await _faqService.submitQuestion(submission);

      // Clear form
      _nameController.clear();
      _emailController.clear();
      _birthDateController.clear();
      _categoryController.clear();
      _contentController.clear();
      _attachmentController.clear();

      // Switch to history tab
      _tabController.animateTo(1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('문의가 접수되었습니다'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('문의 접수 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}