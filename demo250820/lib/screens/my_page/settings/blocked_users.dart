import 'package:flutter/material.dart';
import '../../../models/blocked_user.dart';
import '../../../services/user_service.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final UserService _userService = UserService();
  List<BlockedUser> blockedUsers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      final users = await _userService.getBlockedUsers();
      
      if (mounted) {
        setState(() {
          blockedUsers = users;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _unblockUser(String userId) async {
    try {
      await _userService.unblockUser(userId);
      
      setState(() {
        blockedUsers.removeWhere((user) => user.id == userId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 차단이 해제되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차단 해제에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUnblockConfirmDialog(BlockedUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '차단 해제',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          content: Text(
            '${user.username}님의 차단을 해제하시겠습니까?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unblockUser(user.id);
              },
              child: const Text(
                '해제',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F37CF),
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        );
      },
    );
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
          '차단된 계정',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoadingState(widthRatio, heightRatio)
          : errorMessage != null
              ? _buildErrorState(widthRatio, heightRatio)
              : blockedUsers.isEmpty
                  ? _buildEmptyState(widthRatio, heightRatio)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * widthRatio,
                        vertical: 20 * heightRatio,
                      ),
                      itemCount: blockedUsers.length,
                      itemBuilder: (context, index) {
                        final user = blockedUsers[index];
                        return _buildBlockedUserItem(user, widthRatio, heightRatio);
                      },
                    ),
    );
  }

  Widget _buildLoadingState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40 * widthRatio,
            height: 40 * widthRatio,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
            ),
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            '차단된 계정을 불러오는 중...',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64 * widthRatio,
            color: Colors.red,
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * heightRatio),
          Text(
            errorMessage ?? '알 수 없는 오류',
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFCCCCCC),
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16 * heightRatio),
          ElevatedButton(
            onPressed: _loadBlockedUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F37CF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
            ),
            child: Text(
              '다시 시도',
              style: TextStyle(
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64 * widthRatio,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            '차단된 계정이 없습니다',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * heightRatio),
          Text(
            '다른 사용자를 차단하면 여기에 표시됩니다',
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

  Widget _buildBlockedUserItem(BlockedUser user, double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * heightRatio),
      padding: EdgeInsets.all(16 * widthRatio),
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
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 48 * widthRatio,
            height: 48 * widthRatio,
            decoration: BoxDecoration(
              color: const Color(0xFF5F37CF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24 * widthRatio),
            ),
            child: Center(
              child: user.profileImage.isNotEmpty
                  ? (user.profileImage.length == 1 && user.profileImage.codeUnits.first > 127)
                      ? Text(
                          user.profileImage,
                          style: TextStyle(
                            fontSize: 24 * widthRatio,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24 * widthRatio),
                          child: Image.network(
                            user.profileImage,
                            width: 48 * widthRatio,
                            height: 48 * widthRatio,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 24 * widthRatio,
                                color: const Color(0xFF5F37CF),
                              );
                            },
                          ),
                        )
                  : Icon(
                      Icons.person,
                      size: 24 * widthRatio,
                      color: const Color(0xFF5F37CF),
                    ),
            ),
          ),
          
          SizedBox(width: 12 * widthRatio),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 16 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121212),
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 2 * heightRatio),
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          
          // Unblock Button
          ElevatedButton(
            onPressed: () => _showUnblockConfirmDialog(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F37CF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20 * widthRatio),
              ),
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: 16 * widthRatio,
                vertical: 8 * heightRatio,
              ),
              minimumSize: Size(
                72 * widthRatio,
                32 * heightRatio,
              ),
            ),
            child: Text(
              '차단해제',
              style: TextStyle(
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }
}