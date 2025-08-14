import 'package:flutter/material.dart';
import 'todayquestion.dart';
import '../../models/today_question_model.dart';
import '../../models/magazine_model.dart';
import '../../services/today_question_service.dart';
import '../../services/magazine_service.dart';
import '../../widgets/cached_network_image_widget.dart';

class ContentsMainPage extends StatefulWidget {
  const ContentsMainPage({super.key});

  @override
  State<ContentsMainPage> createState() => _ContentsMainPageState();
}

class _ContentsMainPageState extends State<ContentsMainPage> {
  final TodayQuestionService _questionService = TodayQuestionService();
  final MagazineService _magazineService = MagazineService();
  
  TodayQuestion? _currentQuestion;
  TodayQuestionAnswer? _mostRecentAnswer;
  int _totalAnswers = 0;
  bool _isLoadingQuestion = true;
  List<MagazinePost> _magazinePosts = [];
  bool _isLoadingMagazine = true;
  Map<String, int> _currentPageIndexes = {}; // Track current page for each post
  Map<String, PageController> _pageControllers = {}; // PageController for each post

  @override
  void initState() {
    super.initState();
    _loadQuestionData();
  }

  @override
  void dispose() {
    // Dispose all page controllers
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Initialize page controllers and current page indexes for magazine posts
  void _initializeMagazineControllers(List<MagazinePost> posts) {
    // Dispose existing controllers
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    
    // Clear existing data
    _pageControllers.clear();
    _currentPageIndexes.clear();
    
    // Initialize new controllers and indexes
    for (var post in posts) {
      _pageControllers[post.postId] = PageController();
      _currentPageIndexes[post.postId] = 0;
    }
  }

  Future<void> _loadQuestionData() async {
    try {
      setState(() {
        _isLoadingQuestion = true;
        _isLoadingMagazine = true;
      });

      // Initialize service to ensure there's always a question
      await _questionService.initializeService();
      
      // Get current question
      final question = await _questionService.getCurrentQuestion();
      
      // Load magazine posts
      final magazinePosts = await _magazineService.getAllMagazinePosts();
      
      if (question != null) {
        // Get answers for the question
        final answers = await _questionService.getQuestionAnswers(question.questionId);
        
        // Initialize page controllers and indexes for each post
        _initializeMagazineControllers(magazinePosts);
        
        setState(() {
          _currentQuestion = question;
          _totalAnswers = answers.length;
          _mostRecentAnswer = answers.isNotEmpty ? answers.first : null;
          _magazinePosts = magazinePosts;
          _isLoadingQuestion = false;
          _isLoadingMagazine = false;
        });
      } else {
        // Initialize page controllers and indexes for each post
        _initializeMagazineControllers(magazinePosts);
        
        setState(() {
          _magazinePosts = magazinePosts;
          _isLoadingQuestion = false;
          _isLoadingMagazine = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingQuestion = false;
        _isLoadingMagazine = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 393.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(widthRatio),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayQuestionSection(widthRatio),
            SizedBox(height: 24 * widthRatio),
            _buildSilsoMagazineSection(widthRatio),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double widthRatio) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          // silso logo
          Image.asset(
            'assets/images/silso_logo/black_silso_logo.png',
            height: 20 * widthRatio,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 8 * widthRatio),
          // 컨텐츠 title
          Text(
            '컨텐츠',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
      toolbarHeight: 56,
    );
  }

  Widget _buildTodayQuestionSection(double widthRatio) {
    return GestureDetector(
      onTap: () => _navigateToTodayQuestion(),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16 * widthRatio),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED), // Purple color from the image
          borderRadius: BorderRadius.circular(16 * widthRatio),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main question section
            Padding(
              padding: EdgeInsets.all(20 * widthRatio),
              child: _isLoadingQuestion
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16 * widthRatio,
                          height: 16 * widthRatio,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12 * widthRatio),
                        Text(
                          '오늘의 질문을 불러오고 있어요...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * widthRatio,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘의 실큐',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14 * widthRatio,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 8 * widthRatio),
                        Text(
                          _currentQuestion?.questionText ?? '오늘의 질문이 없습니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * widthRatio,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
            ),
            
            // Answer preview section
            if (!_isLoadingQuestion && _currentQuestion != null)
              Container(
                margin: EdgeInsets.fromLTRB(16 * widthRatio, 0, 16 * widthRatio, 16 * widthRatio),
                padding: EdgeInsets.all(16 * widthRatio),
                decoration: BoxDecoration(
                  color: Colors.white ,// Slightly darker purple
                  borderRadius: BorderRadius.circular(12 * widthRatio),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '답변 $_totalAnswers',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12 * widthRatio,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 8 * widthRatio),
                    _mostRecentAnswer != null
                        ? Row(
                            children: [
                              // Avatar
                              Container(
                                width: 24 * widthRatio,
                                height: 24 * widthRatio,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12 * widthRatio),
                                ),
                                child: Center(
                                  child: Text(
                                    _mostRecentAnswer!.avatarEmoji,
                                    style: TextStyle(fontSize: 12 * widthRatio),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8 * widthRatio),
                              Expanded(
                                child: Text(
                                  _mostRecentAnswer!.answerText.length > 35
                                      ? '${_mostRecentAnswer!.answerText.substring(0, 35)}...'
                                      : _mostRecentAnswer!.answerText,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13 * widthRatio,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Pretendard',
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: Text(
                              '아직 답변이 없어요. 가장 먼저 답변을 남겨보세요!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13 * widthRatio,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Pretendard',
                                height: 1.3,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilsoMagazineSection(double widthRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Magazine title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
          child: Text(
            '실소 Magazine',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20 * widthRatio,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        
        SizedBox(height: 16 * widthRatio),
        
        // Magazine content
        _isLoadingMagazine
            ? _buildMagazineLoadingState(widthRatio)
            : _magazinePosts.isEmpty
                ? _buildEmptyMagazineState(widthRatio)
                : _buildMagazineCarousel(widthRatio),
        
        SizedBox(height: 40 * widthRatio),
      ],
    );
  }

  // Loading state for magazine section
  Widget _buildMagazineLoadingState(double widthRatio) {
    return Container(
      height: 280 * widthRatio, // Taller than before
      margin: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16 * widthRatio),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
            ),
            SizedBox(height: 16 * widthRatio),
            Text(
              '매거진을 불러오고 있어요...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state for magazine section
  Widget _buildEmptyMagazineState(double widthRatio) {
    return Container(
      height: 280 * widthRatio, // Taller than before
      margin: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16 * widthRatio),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48 * widthRatio,
              color: Colors.grey,
            ),
            SizedBox(height: 16 * widthRatio),
            Text(
              '아직 등록된 매거진이 없습니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Magazine posts list - show all posts at once
  Widget _buildMagazineCarousel(double widthRatio) {
    return Column(
      children: _magazinePosts.map((post) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16 * widthRatio),
          child: _buildMagazinePostCard(post, widthRatio),
        );
      }).toList(),
    );
  }

  // Build individual magazine post card
  Widget _buildMagazinePostCard(MagazinePost post, double widthRatio) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
      child: Column(
        children: [
          // Image container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 * widthRatio),
              color: const Color(0xFF7C3AED), // Default purple color
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16 * widthRatio),
              child: _buildPostBackground(post, widthRatio),
            ),
          ),
          // Dot indicators below the image
          if (post.hasImages && post.imageUrls.length > 1) ...[
            SizedBox(height: 12 * widthRatio),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(post.imageUrls.length, (index) {
                final isActive = (_currentPageIndexes[post.postId] ?? 0) == index;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 3 * widthRatio),
                  width: 8 * widthRatio,
                  height: 8 * widthRatio,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.black : Colors.grey.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // Build post background with images or default gradient
  Widget _buildPostBackground(MagazinePost post, double widthRatio) {
    if (post.hasImages) {
      // If there are multiple images, show them in a horizontal PageView
      if (post.imageUrls.length > 1) {
        final controller = _pageControllers[post.postId];
        return SizedBox(
          height: 450 * widthRatio,
          child: PageView.builder(
            controller: controller,
            itemCount: post.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndexes[post.postId] = index;
              });
            },
            itemBuilder: (context, index) {
              return MobileCompatibleNetworkImage(
                imageUrl: post.imageUrls[index],
                fit: BoxFit.cover,
                errorWidget: _buildDefaultPostBackground(post, widthRatio),
              );
            },
          ),
        );
      } else {
        // Single image
        return SizedBox(
          height: 450 * widthRatio,
          child: MobileCompatibleNetworkImage(
            imageUrl: post.imageUrls.first,
            fit: BoxFit.cover,
            errorWidget: _buildDefaultPostBackground(post, widthRatio),
          ),
        );
      }
    } else {
      // No images - show clean gradient background
      return SizedBox(
        height: 450 * widthRatio,
        child: _buildDefaultPostBackground(post, widthRatio),
      );
    }
  }

  // Clean gradient background when no images (no text or icons)
  Widget _buildDefaultPostBackground(MagazinePost post, double widthRatio) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C3AED), // Default purple color
            const Color(0xFF7C3AED).withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  void _navigateToTodayQuestion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TodayQuestionPage(),
      ),
    );
  }
}