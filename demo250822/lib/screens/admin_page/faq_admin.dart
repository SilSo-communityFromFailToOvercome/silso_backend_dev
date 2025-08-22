import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/faq.dart';
import '../../services/faq_service.dart';

class FAQAdminPage extends StatefulWidget {
  const FAQAdminPage({super.key});

  @override
  State<FAQAdminPage> createState() => _FAQAdminPageState();
}

class _FAQAdminPageState extends State<FAQAdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Backend service
  final FAQService _faqService = FAQService();
  
  // Streams for different question types
  Stream<List<FAQ>>? _allQuestionsStream;
  Stream<List<FAQ>>? _pendingQuestionsStream;
  Stream<List<FAQ>>? _answeredQuestionsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeStreams();
  }

  void _initializeStreams() {
    _allQuestionsStream = _faqService.getAllQuestions();
    _pendingQuestionsStream = _faqService.getAllQuestions(status: FAQStatus.pending);
    _answeredQuestionsStream = _faqService.getAllQuestions(status: FAQStatus.answered);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          'FAQ Management',
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
          indicatorColor: const Color(0xFF7C3AED),
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF8E8E8E),
          labelStyle: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Answered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamQuestionList(_allQuestionsStream, widthRatio, heightRatio),
          _buildStreamQuestionList(_pendingQuestionsStream, widthRatio, heightRatio),
          _buildStreamQuestionList(_answeredQuestionsStream, widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildStreamQuestionList(Stream<List<FAQ>>? stream, double widthRatio, double heightRatio) {
    if (stream == null) {
      return _buildEmptyState(widthRatio, heightRatio);
    }

    return StreamBuilder<List<FAQ>>(
      stream: stream,
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
                  'Failed to load questions',
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
        return _buildQuestionList(questions, widthRatio, heightRatio);
      },
    );
  }

  Widget _buildQuestionList(List<FAQ> questions, double widthRatio, double heightRatio) {
    if (questions.isEmpty) {
      return _buildEmptyState(widthRatio, heightRatio);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16 * widthRatio),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionItem(question, widthRatio, heightRatio);
      },
    );
  }

  Widget _buildEmptyState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64 * widthRatio,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            'No questions found',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(FAQ question, double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * heightRatio),
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
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(20 * widthRatio),
        childrenPadding: EdgeInsets.only(
          left: 20 * widthRatio,
          right: 20 * widthRatio,
          bottom: 20 * widthRatio,
        ),
        leading: Container(
          width: 40 * widthRatio,
          height: 40 * widthRatio,
          decoration: BoxDecoration(
            color: question.status == FAQStatus.pending
                ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                : const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20 * widthRatio),
          ),
          child: Icon(
            question.status == FAQStatus.pending
                ? Icons.schedule
                : Icons.check_circle,
            color: question.status == FAQStatus.pending
                ? const Color(0xFFF59E0B)
                : const Color(0xFF059669),
            size: 20 * widthRatio,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121212),
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
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4 * widthRatio),
                  ),
                  child: Text(
                    question.category,
                    style: TextStyle(
                      fontSize: 11 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * heightRatio),
            Text(
              'By: ${question.userName} (${question.userEmail})',
              style: TextStyle(
                fontSize: 13 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 4 * heightRatio),
            Text(
              DateFormat('yyyy.MM.dd HH:mm').format(question.submitDate),
              style: TextStyle(
                fontSize: 12 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFCCCCCC),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        children: [
          _buildQuestionDetails(question, widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildQuestionDetails(FAQ question, double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question content
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * widthRatio),
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
                    Icons.help_outline,
                    size: 16 * widthRatio,
                    color: const Color(0xFF7C3AED),
                  ),
                  SizedBox(width: 8 * widthRatio),
                  Text(
                    'Question',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * heightRatio),
              Text(
                question.content,
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

        SizedBox(height: 16 * heightRatio),

        // Answer section
        if (question.status == FAQStatus.answered && question.answer != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * widthRatio),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8 * widthRatio),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 16 * widthRatio,
                      color: const Color(0xFF059669),
                    ),
                    SizedBox(width: 8 * widthRatio),
                    Text(
                      'Admin Answer',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'by ${question.answeredBy} • ${DateFormat('MM.dd HH:mm').format(question.answeredDate!)}',
                      style: TextStyle(
                        fontSize: 12 * widthRatio,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E8E),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * heightRatio),
                Text(
                  question.answer!,
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
          SizedBox(height: 16 * heightRatio),
        ],

        // Action buttons
        Row(
          children: [
            if (question.status == FAQStatus.pending) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAnswerDialog(question, widthRatio, heightRatio),
                  icon: Icon(Icons.reply, size: 16 * widthRatio),
                  label: Text(
                    'Answer',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12 * heightRatio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6 * widthRatio),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12 * widthRatio),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(question),
                icon: Icon(Icons.delete_outline, size: 16 * widthRatio),
                label: Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding: EdgeInsets.symmetric(vertical: 12 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6 * widthRatio),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAnswerDialog(FAQ question, double widthRatio, double heightRatio) {
    final TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Answer Question',
            style: TextStyle(
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question: ${question.question}',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 16 * heightRatio),
                TextField(
                  controller: answerController,
                  maxLines: 5,
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF121212),
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your answer here...',
                    hintStyle: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFCCCCCC),
                      fontFamily: 'Pretendard',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (answerController.text.trim().isNotEmpty) {
                  _submitAnswer(question, answerController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAnswer(FAQ question, String answer) async {
    try {
      await _faqService.answerQuestion(question.id, answer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer submitted successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit answer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(FAQ question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Question',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this question? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteQuestion(question);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteQuestion(FAQ question) async {
    try {
      await _faqService.deleteQuestion(question.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question deleted successfully'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete question: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

