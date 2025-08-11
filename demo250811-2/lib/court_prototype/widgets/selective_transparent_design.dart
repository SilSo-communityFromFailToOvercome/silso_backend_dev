import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vote_model.dart';

/// Selective transparency design - only background transparent, content fully visible
class SelectiveTransparentDesign {
  /// AppBar 배경만 투명하게 만드는 래퍼
  static PreferredSizeWidget createTransparentBackgroundAppBar({
    required PreferredSizeWidget originalAppBar,
    bool transparentBackground = true,
  }) {
    return SelectiveTransparentAppBar(
      originalAppBar: originalAppBar,
      transparentBackground: transparentBackground,
    );
  }

  /// Wrapper that makes only the bottom input field background transparent
  static Widget createTransparentBackgroundBottom({
    required Widget originalBottom,
    bool transparentBackground = true,
  }) {
    return SelectiveTransparentBottom(
      originalBottom: originalBottom,
      transparentBackground: transparentBackground,
    );
  }
}

/// AppBar의 배경만 투명하게 만드는 커스텀 AppBar
class SelectiveTransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget originalAppBar;
  final bool transparentBackground;

  const SelectiveTransparentAppBar({
    super.key,
    required this.originalAppBar,
    this.transparentBackground = true,
  });

  @override
  Size get preferredSize => originalAppBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    // Use original AppBar as is, but change only background to transparent
    return Container(
      decoration: BoxDecoration(
        // Set background to transparent
        color: transparentBackground ? Colors.transparent : null,
      ),
      child: originalAppBar,
    );
  }
}

/// Wrapper that makes only the bottom widget background transparent
class SelectiveTransparentBottom extends StatelessWidget {
  final Widget originalBottom;
  final bool transparentBackground;

  const SelectiveTransparentBottom({
    super.key,
    required this.originalBottom,
    this.transparentBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: transparentBackground ? Colors.transparent : null,
      ),
      child: originalBottom,
    );
  }
}

/// VoteAppBarView의 투명 배경 버전
class TransparentBackgroundVoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onQuitPressed;

  const TransparentBackgroundVoteAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onQuitPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(180.0);

  @override
  Widget build(BuildContext context) {
    return Consumer<VoteModel>(
      builder: (context, voteModel, child) {
        return Container(
          // Change background to transparent
          decoration: const BoxDecoration(
            color: Colors.transparent, // Only background transparent
            // boxShadow 제거 (투명한 배경에는 그림자가 어울리지 않음)
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 1st Row: Quit Icon (right aligned) - 콘텐츠는 그대로 유지
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: onQuitPressed ?? () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // 2nd Row: Dynamic Scale Bar - 콘텐츠는 그대로 유지
                TransparentBackgroundScaleBar(voteModel: voteModel),
                // 3rd Row: Vote Control Row - 콘텐츠는 그대로 유지
                TransparentBackgroundVoteControlRow(voteModel: voteModel, title: title),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Scale bar widget with transparent background
class TransparentBackgroundScaleBar extends StatelessWidget {
  final VoteModel voteModel;

  const TransparentBackgroundScaleBar({
    super.key,
    required this.voteModel,
  });

  @override
  Widget build(BuildContext context) {
    final agreeRatio = voteModel.agreeRatio;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Stack(
          children: [
            // Background (oppose color) - keep this part as is
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            // Agree section (dynamically changing area) - keep this part as is too
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: (screenWidth - 32) * agreeRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            // 중앙 표시기 - 이 부분도 그대로 유지
            Positioned(
              left: (screenWidth - 32) * agreeRatio - 20,
              top: -8,
              child: Container(
                width: 40,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${(agreeRatio * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF3F3329),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 투명한 배경을 가진 투표 컨트롤 행 위젯
class TransparentBackgroundVoteControlRow extends StatelessWidget {
  final VoteModel voteModel;
  final String title;

  const TransparentBackgroundVoteControlRow({
    super.key,
    required this.voteModel,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 반대 버튼 - 콘텐츠는 그대로 유지
          GestureDetector(
            onTap: () => voteModel.addVote(false),
            child: Container(
              width: 80,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF44336),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '반대',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // 중앙 제목 영역 - 콘텐츠는 그대로 유지
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // 찬성 버튼 - 콘텐츠는 그대로 유지
          GestureDetector(
            onTap: () => voteModel.addVote(true),
            child: Container(
              width: 80,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '찬성',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 투명한 배경을 가진 하단 입력창
class TransparentBackgroundBottomInput extends StatelessWidget {
  final TextEditingController controller;
  final int participantCount;
  final VoidCallback onSend;

  const TransparentBackgroundBottomInput({
    super.key,
    required this.controller,
    required this.participantCount,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 배경만 투명하게 변경
      child: SafeArea(
        top: false,
        child: Container(
          height: 80, // ChatConfig.inputBarHeight 대신 고정값 사용
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 정보 표시 행 - 콘텐츠는 그대로 유지
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 참여자 수: $participantCount명',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 100),
                    const Text(
                      '남은 시간: 3시간',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 입력창과 아이콘 행 - 콘텐츠는 그대로 유지
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(400),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                style: const TextStyle(color: Colors.black, fontSize: 16),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.only(left: 20),
                                  hintText: '의견을 입력해주세요.',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFBBBBBB),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Color(0xFFBBBBBB)),
                              onPressed: onSend,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.document_scanner, color: Color(0xFFBBBBBB)),
                      onPressed: () {
                        // TODO: 문서 스캐너 아이콘 클릭 시 동작 추가
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택적 투명도 설정
class SelectiveTransparencyController {
  /// AppBar 배경 투명도 (배경만)
  static const bool appBarBackgroundTransparent = true;
  
  /// 하단 입력창 배경 투명도 (배경만)
  static const bool bottomBackgroundTransparent = true;
  
  /// 모든 다른 위젯들의 투명도 (완전히 보이게)
  static const double contentOpacity = 1.0;
  
  /// 배경 이미지 오버레이 투명도
  static const double backgroundOverlayOpacity = 0.3;
}