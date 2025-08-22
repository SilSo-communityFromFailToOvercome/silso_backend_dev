import 'package:flutter/material.dart';
import '../services/community_service.dart'; // CommunityService 경로
import '../models/community_model.dart';   // Community 모델 경로
import '../screens/community/community_detail_page.dart'; // 상세 페이지 경로

class NavigationHelper {
  /// 커뮤니티 ID를 받아 상세 정보 로딩 후 해당 페이지로 이동시키는 공용 함수
  static Future<void> navigateToCommunityDetail(BuildContext context, String communityId) async {
    // CommunityService 인스턴스를 생성합니다.
    final communityService = CommunityService();

    // 로딩 중임을 나타내는 다이얼로그를 표시합니다.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // 서비스를 통해 커뮤니티 상세 정보를 가져옵니다.
      final Community community = await communityService.getCommunity(communityId);

      // 현재 context가 유효한 경우에만 Navigator를 사용합니다.
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      // 상세 페이지로 이동합니다.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => KoreanCommunityDetailPage(
            community: community,
          ),
        ),
      );
    } catch (e) {
      // 현재 context가 유효한 경우에만 Navigator와 ScaffoldMessenger를 사용합니다.
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 에러 발생 시에도 로딩 다이얼로그 닫기

      // 에러 메시지를 스낵바로 표시합니다.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('커뮤니티 정보를 불러오는 데 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}