import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsageLimitHistoryPage extends StatefulWidget {
  const UsageLimitHistoryPage({super.key});

  @override
  State<UsageLimitHistoryPage> createState() => _UsageLimitHistoryPageState();
}

class _UsageLimitHistoryPageState extends State<UsageLimitHistoryPage> {
  List<UsageLimitRecord> limitRecords = [
    UsageLimitRecord(
      id: '1',
      title: '너 얼굴이 문제가 아닐까?',
      description: '"언니 꺼이 시험엔 잘된 숙제," "자나간 확실한 최룰 봄놓은나다."',
      banDate: DateTime(2025, 8, 18),
      reason: '3일 정지 처분',
      type: BanType.post,
    ),
  ];

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
          '이용 제한 내역',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: limitRecords.isEmpty
          ? _buildEmptyState(widthRatio, heightRatio)
          : ListView.builder(
              padding: EdgeInsets.all(16 * widthRatio),
              itemCount: limitRecords.length,
              itemBuilder: (context, index) {
                final record = limitRecords[index];
                return _buildLimitRecordItem(record, widthRatio, heightRatio);
              },
            ),
    );
  }

  Widget _buildEmptyState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64 * widthRatio,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            '이용 제한 내역이 없습니다',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * heightRatio),
          Text(
            '커뮤니티 가이드라인을 준수해 주셔서 감사합니다',
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

  Widget _buildLimitRecordItem(UsageLimitRecord record, double widthRatio, double heightRatio) {
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
          // Title
          Text(
            record.title,
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          
          SizedBox(height: 8 * heightRatio),
          
          // Description
          Text(
            record.description,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),
          
          SizedBox(height: 16 * heightRatio),
          
          // Date and Ban Reason
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy.MM.dd').format(record.banDate),
                style: TextStyle(
                  fontSize: 13 * widthRatio,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * widthRatio,
                  vertical: 4 * heightRatio,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4 * widthRatio),
                ),
                child: Text(
                  record.reason,
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6B6B),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
          
          // Type indicator
          if (record.type != null) ...[
            SizedBox(height: 12 * heightRatio),
            Row(
              children: [
                Icon(
                  record.type == BanType.post ? Icons.article : Icons.comment,
                  size: 14 * widthRatio,
                  color: const Color(0xFF8E8E8E),
                ),
                SizedBox(width: 4 * widthRatio),
                Text(
                  record.type == BanType.post ? '게시물' : '댓글',
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class UsageLimitRecord {
  final String id;
  final String title;
  final String description;
  final DateTime banDate;
  final String reason;
  final BanType? type;

  UsageLimitRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.banDate,
    required this.reason,
    this.type,
  });
}

enum BanType {
  post,
  comment,
}