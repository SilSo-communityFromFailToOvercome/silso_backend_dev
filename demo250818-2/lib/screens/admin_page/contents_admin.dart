import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/today_question_model.dart';
import '../../models/magazine_model.dart';
import '../../services/today_question_service.dart';
import '../../services/magazine_service.dart';
import '../../widgets/cached_network_image_widget.dart';

class ContentsAdminPage extends StatefulWidget {
  const ContentsAdminPage({super.key});

  @override
  State<ContentsAdminPage> createState() => _ContentsAdminPageState();
}

class _ContentsAdminPageState extends State<ContentsAdminPage> {
  final TextEditingController _questionController = TextEditingController();
  final TodayQuestionService _questionService = TodayQuestionService();
  final MagazineService _magazineService = MagazineService();
  
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  TodayQuestion? _currentQuestion;
  List<TodayQuestion> _allQuestions = [];
  
  // Magazine data
  List<MagazinePost> _magazinePosts = [];
  bool _isLoadingMagazine = false;
  
  // No controllers needed for image-only posts

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load question data
      await _questionService.initializeService();
      final currentQuestion = await _questionService.getCurrentQuestion();
      final allQuestions = await _questionService.getAllQuestions();

      // Load magazine posts
      final magazinePosts = await _magazineService.getAllMagazinePosts();

      setState(() {
        _currentQuestion = currentQuestion;
        _allQuestions = allQuestions;
        _magazinePosts = magazinePosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 393.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(widthRatio),
      body: _isLoading
          ? _buildLoadingState(widthRatio)
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16 * widthRatio),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayQuestionSection(widthRatio),
                    SizedBox(height: 32 * widthRatio),
                    _buildMagazineSection(widthRatio),
                    SizedBox(height: 32 * widthRatio),
                    _buildQuestionHistorySection(widthRatio),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(double widthRatio) {
    return AppBar(
      backgroundColor: const Color(0xFF7C3AED),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '컨텐츠 관리자',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18 * widthRatio,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoadingState(double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            '데이터를 불러오고 있어요...',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14 * widthRatio,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayQuestionSection(double widthRatio) {
    return Container(
      padding: EdgeInsets.all(20 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * widthRatio),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: const Color(0xFF7C3AED),
                size: 24 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '오늘의 질문 관리',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * widthRatio),
          
          // Current question display
          if (_currentQuestion != null) ...[
            Container(
              padding: EdgeInsets.all(16 * widthRatio),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12 * widthRatio),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 활성 질문',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 8 * widthRatio),
                  Text(
                    _currentQuestion!.questionText,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      color: const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16 * widthRatio),
          ],
          
          // New question input
          TextField(
            controller: _questionController,
            maxLines: 3,
            maxLength: 200,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontFamily: 'Pretendard',
            ),
            decoration: InputDecoration(
              hintText: '새로운 오늘의 질문을 입력하세요...',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * widthRatio),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16 * widthRatio),
            ),
          ),
          SizedBox(height: 16 * widthRatio),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitNewQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * widthRatio),
                ),
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
                  : Text(
                      '새 질문 등록',
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

  Widget _buildMagazineSection(double widthRatio) {
    return Container(
      padding: EdgeInsets.all(20 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * widthRatio),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: const Color(0xFF7C3AED),
                size: 24 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '실소 Magazine 관리',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoadingMagazine ? null : _showCreatePostDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * widthRatio,
                    vertical: 8 * widthRatio,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * widthRatio),
                  ),
                ),
                icon: Icon(Icons.add, size: 16 * widthRatio),
                label: Text(
                  '새 포스트',
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * widthRatio),
          
          // Magazine posts list
          if (_magazinePosts.isEmpty)
            Container(
              padding: EdgeInsets.all(32 * widthRatio),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48 * widthRatio,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(height: 16 * widthRatio),
                    Text(
                      '아직 생성된 매거진 포스트가 없습니다.\n새 포스트를 추가해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14 * widthRatio,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_magazinePosts.length, (index) {
              return _buildMagazinePostCard(_magazinePosts[index], widthRatio);
            }),
        ],
      ),
    );
  }

  Widget _buildQuestionHistorySection(double widthRatio) {
    return Container(
      padding: EdgeInsets.all(20 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * widthRatio),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: const Color(0xFF7C3AED),
                size: 24 * widthRatio,
              ),
              SizedBox(width: 8 * widthRatio),
              Text(
                '질문 히스토리',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * widthRatio),
          
          // Question list
          if (_allQuestions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32 * widthRatio),
                child: Text(
                  '등록된 질문이 없습니다.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            )
          else
            ...List.generate(_allQuestions.length, (index) {
              final question = _allQuestions[index];
              final isActive = question.questionId == _currentQuestion?.questionId;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12 * widthRatio),
                padding: EdgeInsets.all(16 * widthRatio),
                decoration: BoxDecoration(
                  color: isActive 
                      ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12 * widthRatio),
                  border: isActive 
                      ? Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    if (isActive)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * widthRatio,
                          vertical: 4 * widthRatio,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(12 * widthRatio),
                        ),
                        child: Text(
                          '활성',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * widthRatio,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    if (isActive) SizedBox(width: 12 * widthRatio),
                    Expanded(
                      child: Text(
                        question.questionText,
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          color: const Color(0xFF333333),
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    if (!isActive)
                      TextButton(
                        onPressed: () => _activateQuestion(question.questionId),
                        child: Text(
                          '활성화',
                          style: TextStyle(
                            color: const Color(0xFF7C3AED),
                            fontSize: 12 * widthRatio,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _submitNewQuestion() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('질문을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CreateTodayQuestionRequest(
        questionText: questionText,
        isActive: true,
      );

      await _questionService.createTodayQuestion(request);
      
      if (!mounted) return;

      _questionController.clear();
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새 질문이 등록되었습니다!'),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('질문 등록 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _activateQuestion(String questionId) async {
    try {
      await _questionService.updateQuestion(questionId, isActive: true);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('질문이 활성화되었습니다!'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('질문 활성화 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build magazine post card
  Widget _buildMagazinePostCard(MagazinePost post, double widthRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * widthRatio),
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: Color(post.colorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12 * widthRatio),
        border: Border.all(
          color: Color(post.colorValue).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Magazine Post ${post.order + 1}',
                      style: TextStyle(
                        fontSize: 16 * widthRatio,
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _deletePost(post);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 12 * widthRatio),
          
          // Images section
          if (post.imageUrls.isNotEmpty) ...[
            SizedBox(
              height: 80 * widthRatio,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 8 * widthRatio),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8 * widthRatio),
                          child: MobileCompatibleNetworkImage(
                            imageUrl: post.imageUrls[index],
                            width: 80 * widthRatio,
                            height: 80 * widthRatio,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImageFromPost(post, post.imageUrls[index]),
                            child: Container(
                              padding: EdgeInsets.all(2 * widthRatio),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12 * widthRatio,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12 * widthRatio),
          ],
          
          // Add image button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addImageToPost(post),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED)),
                padding: EdgeInsets.symmetric(vertical: 12 * widthRatio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * widthRatio),
                ),
              ),
              icon: Icon(Icons.add_photo_alternate, size: 16 * widthRatio),
              label: Text(
                '이미지 추가',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
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

  // Show create post dialog
  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 매거진 포스트'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library,
                size: 48,
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 16),
              Text(
                '새 매거진 포스트를 생성하고\n이미지를 업로드하세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton.icon(
              onPressed: _createPostAndUploadImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('생성 & 이미지 업로드'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Create new post and immediately upload image
  Future<void> _createPostAndUploadImage() async {
    try {
      setState(() {
        _isLoadingMagazine = true;
      });

      // First close the dialog
      Navigator.pop(context);

      // Create the post
      final request = CreateMagazinePostRequest();
      final postId = await _magazineService.createMagazinePost(request);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('포스트가 생성되었습니다! 이미지를 선택하세요.'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );

        // Immediately pick and upload an image
        try {
          final image = await _magazineService.pickImage();
          
          if (image != null) {
            // Validate file
            if (!_magazineService.isValidImageFile(image)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('올바른 이미지 파일을 선택해주세요 (jpg, png, gif, webp)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            if (!await _magazineService.isValidFileSize(image)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('이미지 크기가 너무 큽니다. 최대 크기: ${_magazineService.formatFileSize(MagazineService.maxFileSizeBytes)}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Upload the image
            await _magazineService.uploadImageToMagazinePost(
              imageFile: image,
              postId: postId,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('이미지가 업로드되었습니다! 더 많은 이미지를 추가할 수 있습니다.'),
                  backgroundColor: Color(0xFF7C3AED),
                ),
              );
            }
          }
        } catch (imageError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 업로드 실패: ${imageError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        // Reload data to show the new post
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('포스트 생성 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMagazine = false;
        });
      }
    }
  }

  // Add image to post
  Future<void> _addImageToPost(MagazinePost post) async {
    try {
      final XFile? image = await _magazineService.pickImage();
      
      if (image != null) {
        // Validate file
        if (!_magazineService.isValidImageFile(image)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('올바른 이미지 파일을 선택해주세요 (jpg, png, gif, webp)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!await _magazineService.isValidFileSize(image)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 크기가 너무 큽니다. 최대 크기: ${_magazineService.formatFileSize(MagazineService.maxFileSizeBytes)}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Upload image
        setState(() {
          _isLoadingMagazine = true;
        });

        try {
          await _magazineService.uploadImageToMagazinePost(
            imageFile: image,
            postId: post.postId,
          );

          if (mounted) {
            await _loadData();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미지가 추가되었습니다!'),
                backgroundColor: Color(0xFF7C3AED),
              ),
            );
          }
        } catch (uploadError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 업로드 실패: ${uploadError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMagazine = false;
        });
      }
    }
  }

  // Remove image from post
  Future<void> _removeImageFromPost(MagazinePost post, String imageUrl) async {
    try {
      setState(() {
        _isLoadingMagazine = true;
      });

      await _magazineService.removeImageFromPost(post.postId, imageUrl);
      
      if (mounted) {
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지가 삭제되었습니다'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 삭제 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMagazine = false;
        });
      }
    }
  }


  // Delete post
  Future<void> _deletePost(MagazinePost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('포스트 삭제'),
          content: Text('${post.title} 포스트를 삭제하시겠습니까?\n모든 이미지도 함께 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _magazineService.deleteMagazinePost(post.postId);
        
        if (mounted) {
          await _loadData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('포스트가 삭제되었습니다'),
              backgroundColor: Color(0xFF7C3AED),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('포스트 삭제 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}