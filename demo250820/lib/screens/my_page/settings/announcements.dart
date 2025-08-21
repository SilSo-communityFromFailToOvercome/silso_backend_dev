import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  
  // Service for getting announcements from Firebase
  final AnnouncementService _announcementService = AnnouncementService();

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
          '공지사항',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: _announcementService.getPublishedAnnouncements(),
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
                    '공지사항을 불러오는 중 오류가 발생했습니다',
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
          
          final announcements = snapshot.data ?? [];
          
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64 * widthRatio,
                    color: const Color(0xFFCCCCCC),
                  ),
                  SizedBox(height: 16 * heightRatio),
                  Text(
                    '현재 공지사항이 없습니다',
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
          
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * widthRatio,
              vertical: 8 * heightRatio,
            ),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return _buildAnnouncementCard(announcement, widthRatio, heightRatio);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement, double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * heightRatio),
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
        leading: announcement.isImportant
            ? Container(
                width: 8 * widthRatio,
                height: 8 * widthRatio,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: TextStyle(
                fontSize: 15 * widthRatio,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8 * heightRatio),
            Text(
              DateFormat('yyyy.MM.dd').format(announcement.publishedAt ?? announcement.createdAt),
              style: TextStyle(
                fontSize: 12 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.expand_more,
          color: const Color(0xFF8E8E8E),
          size: 20 * widthRatio,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * widthRatio),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8 * widthRatio),
            ),
            child: Text(
              announcement.content,
              style: TextStyle(
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}