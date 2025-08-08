import 'package:flutter/material.dart';
import '../../../services/community_service.dart';
import '../../../widgets/error_handler_widget.dart';
import 'profile_information_screen.dart';

/// Individual category item representation
class CategoryItem {
  final String id;
  final String name;
  final String? description;
  final String? iconPath;

  const CategoryItem({
    required this.id,
    required this.name,
    this.description,
    this.iconPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryItem(id: $id, name: $name)';
}

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen>
    with TickerProviderStateMixin, ErrorHandlerMixin {
  final CommunityService _communityService = CommunityService();
  final Set<String> _selectedInterests = {};
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  
  // Available categories matching the reference design
  final List<CategoryItem> _availableCategories = [
    const CategoryItem(id: 'business', name: '자영업'),
    const CategoryItem(id: 'startup', name: '스타트업'),
    const CategoryItem(id: 'career_change', name: '이직'),
    const CategoryItem(id: 'resignation', name: '퇴사'),
    const CategoryItem(id: 'employment', name: '취직'),
    const CategoryItem(id: 'study', name: '학업'),
    const CategoryItem(id: 'contest', name: '공모전'),
    const CategoryItem(id: 'mental_care', name: '멘탈케어'),
    const CategoryItem(id: 'relationships', name: '인간관계'),
    const CategoryItem(id: 'daily_life', name: '일상'),
    const CategoryItem(id: 'humor', name: '유머'),
    const CategoryItem(id: 'health', name: '건강'),
  ];
  
  @override
  void initState() {
    super.initState();
    
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
      end: 0.35,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start progress animation
    _progressAnimationController.forward();
  }
  
  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }
  
  void _triggerSelectionAnimation() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
  }

  Future<void> _saveAndContinue() async {
    if (_selectedInterests.isEmpty) {
      _showValidationError('카테고리 선택 필요', '관심있는 카테고리를 최소 1개 이상 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _communityService.saveCommunityInterests(_selectedInterests.toList());
      
      if (mounted) {
        showSuccess('관심 카테고리가 저장되었습니다');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileInformationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await handleError(
          e,
          title: '카테고리 저장 오류',
          endpoint: 'save-interests',
          onRetry: () {
            Navigator.of(context).pop(); // Close error dialog
            _saveAndContinue(); // Retry the operation
          },
        );
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
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context, widthRatio),
      body: Column(
        children: [
          Expanded(
            child: _buildMainContent(context, widthRatio),
          ),
          _buildBottomButton(context, widthRatio),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60 * widthRatio),
            
            // Title - with overflow protection
            Container(
              width: double.infinity,
              child: Text(
                '관심있는 카테고리를\n모두 선택해주세요',
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: (24 * widthRatio).clamp(18.0, 28.0),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.21,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(height: 16 * widthRatio),

            // Subtitle - with overflow protection
            Container(
              width: double.infinity,
              child: Text(
                '내게 꼭 맞는 인사이트를 추천 해드릴게요!',
                style: TextStyle(
                  color: const Color(0xFFC7C7C7),
                  fontSize: (16 * widthRatio).clamp(14.0, 18.0),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.39,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: 32 * widthRatio),

            // Selection counter
            if (_selectedInterests.isNotEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 16 * widthRatio),
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * widthRatio,
                  vertical: 6 * widthRatio,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F37CF),
                  borderRadius: BorderRadius.circular(20 * widthRatio),
                ),
                child: Text(
                  '${_selectedInterests.length}개 선택됨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Category selection area
            _buildCategoryGrid(widthRatio),

            SizedBox(height: 40 * widthRatio),
          ],
        ),
      ),
    );
  }
  
  /// Build category grid with animated chips - overflow safe
  Widget _buildCategoryGrid(double widthRatio) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = (9.27 * widthRatio).clamp(6.0, 12.0);
        final runSpacing = (12 * widthRatio).clamp(8.0, 16.0);
        
        return Container(
          width: constraints.maxWidth,
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: _availableCategories.map((category) => 
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45, // Max width per chip
                  minWidth: 80.0, // Minimum width
                ),
                child: _buildCategoryChip(category, widthRatio, constraints.maxWidth),
              )
            ).toList(),
          ),
        );
      },
    );
  }
  
  /// Build individual category chip with animation - overflow safe
  Widget _buildCategoryChip(CategoryItem category, double widthRatio, double maxWidth) {
    final isSelected = _selectedInterests.contains(category.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(category.id);
          } else {
            _selectedInterests.add(category.id);
          }
        });
        _triggerSelectionAnimation();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(
          maxWidth: maxWidth * 0.45,
          minHeight: 36.0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: (20 * widthRatio).clamp(12.0, 24.0),
          vertical: (10 * widthRatio).clamp(8.0, 12.0),
        ),
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFF5F37CF) : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: (1.63 * widthRatio).clamp(1.0, 2.5),
              color: isSelected 
                  ? const Color(0xFF5F37CF) 
                  : const Color(0xFFC7C7C7),
            ),
            borderRadius: BorderRadius.circular((16.29 * widthRatio).clamp(12.0, 20.0)),
          ),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : const Color(0xFFC7C7C7),
              fontSize: (16.29 * widthRatio).clamp(14.0, 18.0),
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build bottom continue button with animation
  Widget _buildBottomButton(BuildContext context, double widthRatio) {
    final canProceed = _selectedInterests.isNotEmpty;
    
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