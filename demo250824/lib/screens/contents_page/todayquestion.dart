import 'package:flutter/material.dart';
import '../../models/today_question_model.dart';
import '../../services/contents/today_question_service.dart';
import 'config_contents.dart';

class TodayQuestionPage extends StatefulWidget {
  const TodayQuestionPage({super.key});

  @override
  State<TodayQuestionPage> createState() => _TodayQuestionPageState();
}

class _TodayQuestionPageState extends State<TodayQuestionPage> {
  final TextEditingController _answerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TodayQuestionService _questionService = TodayQuestionService();
  
  bool _isSubmitting = false;
  bool _isLoading = true;
  TodayQuestion? _currentQuestion;
  List<TodayQuestionAnswer> _answers = [];
  int _userAnswersToday = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestionData();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Initialize service to ensure there's always a question
      await _questionService.initializeService();
      
      // Get current question
      final question = await _questionService.getCurrentQuestion();
      if (question == null) {
        setState(() {
          _errorMessage = '오늘의 질문을 찾을 수 없습니다.';
        });
        return;
      }

      // Get answers for the question
      final answers = await _questionService.getQuestionAnswers(question.questionId);
      
      // Check how many times user has answered today
      final userAnswersToday = await _questionService.getUserAnswersToday(question.questionId);

      setState(() {
        _currentQuestion = question;
        _answers = answers;
        _userAnswersToday = userAnswersToday;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 393.0;

    return Scaffold(
      backgroundColor: Color(ContentsConfig.primaryPurple),
      appBar: _buildAppBar(widthRatio),
      body: _isLoading
          ? _buildLoadingState(widthRatio)
          : _errorMessage != null
              ? _buildErrorState(widthRatio)
              : _currentQuestion == null
                  ? _buildNoQuestionState(widthRatio)
                  : Column(
                      children: [
                        _buildQuestionHeader(widthRatio),
                        Expanded(
                          child: _buildAnswersList(widthRatio),
                        ),
                        _buildBottomInput(widthRatio),
                      ],
                    ),
    );
  }

  Widget _buildLoadingState(double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Silso logo
          Image.asset(
            'assets/images/silso_logo/black_silso_logo.png',
            height: 40 * widthRatio,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20 * widthRatio),
          // Loading indicator
          SizedBox(
            width: 24 * widthRatio,
            height: 24 * widthRatio,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(ContentsConfig.primaryPurple)),
            ),
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            '오늘의 질문을 불러오고 있어요...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14 * widthRatio,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(double widthRatio) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * widthRatio),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48 * widthRatio,
              color: Colors.red,
            ),
            SizedBox(height: 16 * widthRatio),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 16 * widthRatio),
            ElevatedButton(
              onPressed: _loadQuestionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              child: Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestionState(double widthRatio) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * widthRatio),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 48 * widthRatio,
              color: Colors.grey,
            ),
            SizedBox(height: 16 * widthRatio),
            Text(
              '오늘의 질문이 아직 준비되지 않았어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 16 * widthRatio),
            ElevatedButton(
              onPressed: _loadQuestionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              child: Text('새로고침'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double widthRatio) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Silso logo for purple background
          Image.asset(
            'assets/images/silso_logo/black_silso_logo.png',
            height: 16 * widthRatio,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 6 * widthRatio),
          Text(
            '컨텐츠',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildQuestionHeader(double widthRatio) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20 * widthRatio, 20 * widthRatio, 20 * widthRatio, 20 * widthRatio),
      decoration: const BoxDecoration(
        color: Color(0xFF7C3AED),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 실큐',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * widthRatio,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * widthRatio),
          Text(
            _currentQuestion?.questionText ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20 * widthRatio,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersList(double widthRatio) {
    if (_answers.isEmpty) {
      return Container(
        margin: EdgeInsets.fromLTRB(
          ContentsConfig.containerPadding * widthRatio,
          5 * widthRatio,
          ContentsConfig.containerPadding * widthRatio,
          ContentsConfig.containerPadding * widthRatio,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ContentsConfig.borderRadius * widthRatio),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Answer count header
            Padding(
              padding: EdgeInsets.fromLTRB(20 * widthRatio, 20 * widthRatio, 20 * widthRatio, 10 * widthRatio),
              child: Text(
                '답변 ${_answers.length}',
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            // Empty state content
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24 * widthRatio),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48 * widthRatio,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16 * widthRatio),
                      Text(
                        '아직 답변이 없어요.\n가장 먼저 답변을 남겨보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14 * widthRatio,
                          fontFamily: 'Pretendard',
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        ContentsConfig.containerPadding * widthRatio,
        5 * widthRatio,
        ContentsConfig.containerPadding * widthRatio,
        ContentsConfig.containerPadding * widthRatio,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ContentsConfig.borderRadius * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Answer count header
          Padding(
            padding: EdgeInsets.fromLTRB(20 * widthRatio, 20 * widthRatio, 20 * widthRatio, 10 * widthRatio),
            child: Text(
              '답변 ${_answers.length}',
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          // Answers list
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(Color(ContentsConfig.primaryPurple)),
                  trackColor: WidgetStateProperty.all(Color(ContentsConfig.primaryPurple).withValues(alpha: 0.2)),
                ),
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 4 * widthRatio,
                radius: Radius.circular(2 * widthRatio),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * widthRatio,
                  ),
                  itemCount: _answers.length,
                  itemBuilder: (context, index) {
                    return _buildAnswerCard(_answers[index], index, widthRatio);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(TodayQuestionAnswer answer, int index, double widthRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: ContentsConfig.answerCardSpacing * widthRatio),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile avatar
          Container(
            width: 32 * widthRatio,
            height: 32 * widthRatio,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * widthRatio),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * widthRatio),
              child: Image.asset(
                'assets/images/profile/egg.png',
                width: 32 * widthRatio,
                height: 32 * widthRatio,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: 32 * widthRatio,
                    height: 32 * widthRatio,
                    child: Center(
                      child: Text(
                        '🥚',
                        style: TextStyle(
                          fontSize: 18 * widthRatio,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 12 * widthRatio),
          // Answer text
          Expanded(
            child: Text(
              answer.answerText,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInput(double widthRatio) {
    // If user has reached max answers per day, show a message instead of input
    if (_userAnswersToday >= ContentsConfig.maxAnswersPerDay) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.all(16 * widthRatio),
        child: SafeArea(
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF7C3AED),
                size: 20 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Expanded(
                child: Text(
                  '오늘 질문에 ${ContentsConfig.maxAnswersPerDay}번 답변하셨어요! 내일 새로운 질문을 기다려주세요.',
                  style: TextStyle(
                    color: const Color(0xFF7C3AED),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF7C3AED),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.all(16 * widthRatio),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _answerController,
                maxLines: 1,
                maxLength: ContentsConfig.maxAnswerLength,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14 * widthRatio,
                  fontFamily: 'Pretendard',
                ),
                decoration: InputDecoration(
                  hintText: '댓글 추가...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20 * widthRatio),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * widthRatio,
                    vertical: 12 * widthRatio,
                  ),
                  counterText: '',
                ),
              ),
            ),
            SizedBox(width: 8 * widthRatio),
            GestureDetector(
              onTap: _isSubmitting || _userAnswersToday >= ContentsConfig.maxAnswersPerDay ? null : _submitAnswer,
              child: Container(
                width: 40 * widthRatio,
                height: 40 * widthRatio,
                decoration: BoxDecoration(
                  color: _userAnswersToday >= ContentsConfig.maxAnswersPerDay ? Colors.grey : const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(20 * widthRatio),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20 * widthRatio,
                        height: 20 * widthRatio,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20 * widthRatio,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitAnswer() async {
    if (_currentQuestion == null) return;
    
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변을 입력해주세요'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_userAnswersToday >= ContentsConfig.maxAnswersPerDay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오늘 최대 ${ContentsConfig.maxAnswersPerDay}번만 답변할 수 있습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create answer request with fixed avatar
      final request = CreateTodayQuestionAnswerRequest(
        questionId: _currentQuestion!.questionId,
        answerText: answerText,
        avatarEmoji: '🥚', // Fixed placeholder since we use image now
      );

      // Submit the answer
      await _questionService.submitAnswer(request, maxAnswersPerDay: ContentsConfig.maxAnswersPerDay);

      if (!mounted) return;

      // Clear input and update state
      _answerController.clear();
      setState(() {
        _userAnswersToday += 1;
        _isSubmitting = false;
      });

      // Reload answers to show the new one
      await _loadQuestionData();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 등록되었습니다!'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );

        // Scroll to top to show new answer
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('답변 등록 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}