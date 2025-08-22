import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';

class AnnouncementAdminPage extends StatefulWidget {
  const AnnouncementAdminPage({super.key});

  @override
  State<AnnouncementAdminPage> createState() => _AnnouncementAdminPageState();
}

class _AnnouncementAdminPageState extends State<AnnouncementAdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Backend service
  final AnnouncementService _announcementService = AnnouncementService();
  
  // Streams for different announcement types
  Stream<List<Announcement>>? _allAnnouncementsStream;
  Stream<List<Announcement>>? _publishedAnnouncementsStream;
  Stream<List<Announcement>>? _draftAnnouncementsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeStreams();
  }

  void _initializeStreams() {
    _allAnnouncementsStream = _announcementService.getAllAnnouncementsForAdmin();
    _publishedAnnouncementsStream = _announcementService.getAllAnnouncementsForAdmin(status: AnnouncementStatus.published);
    _draftAnnouncementsStream = _announcementService.getAllAnnouncementsForAdmin(status: AnnouncementStatus.draft);
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
          'Announcement Management',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: const Color(0xFF7C3AED),
              size: 24 * widthRatio,
            ),
            onPressed: () => _showCreateAnnouncementDialog(widthRatio, heightRatio),
          ),
        ],
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
            Tab(text: 'Published'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamAnnouncementList(_allAnnouncementsStream, widthRatio, heightRatio),
          _buildStreamAnnouncementList(_publishedAnnouncementsStream, widthRatio, heightRatio),
          _buildStreamAnnouncementList(_draftAnnouncementsStream, widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildStreamAnnouncementList(Stream<List<Announcement>>? stream, double widthRatio, double heightRatio) {
    if (stream == null) {
      return _buildEmptyState(widthRatio, heightRatio);
    }

    return StreamBuilder<List<Announcement>>(
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
                  'Failed to load announcements',
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
        
        final announcements = snapshot.data ?? [];
        return _buildAnnouncementList(announcements, widthRatio, heightRatio);
      },
    );
  }

  Widget _buildAnnouncementList(List<Announcement> announcements, double widthRatio, double heightRatio) {
    if (announcements.isEmpty) {
      return _buildEmptyState(widthRatio, heightRatio);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16 * widthRatio),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return _buildAnnouncementItem(announcement, widthRatio, heightRatio);
      },
    );
  }

  Widget _buildEmptyState(double widthRatio, double heightRatio) {
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
            'No announcements found',
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

  Widget _buildAnnouncementItem(Announcement announcement, double widthRatio, double heightRatio) {
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
            color: announcement.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20 * widthRatio),
          ),
          child: Icon(
            announcement.status == AnnouncementStatus.published
                ? Icons.public
                : announcement.status == AnnouncementStatus.draft
                    ? Icons.edit
                    : Icons.archive,
            color: announcement.statusColor,
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
                    announcement.title,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (announcement.isImportant) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * widthRatio,
                          vertical: 2 * heightRatio,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4 * widthRatio),
                        ),
                        child: Text(
                          '중요',
                          style: TextStyle(
                            fontSize: 10 * widthRatio,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      SizedBox(width: 4 * widthRatio),
                    ],
                    if (announcement.isPinned) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * widthRatio,
                          vertical: 2 * heightRatio,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4 * widthRatio),
                        ),
                        child: Text(
                          '고정',
                          style: TextStyle(
                            fontSize: 10 * widthRatio,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      SizedBox(width: 4 * widthRatio),
                    ],
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * widthRatio,
                        vertical: 4 * heightRatio,
                      ),
                      decoration: BoxDecoration(
                        color: announcement.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4 * widthRatio),
                      ),
                      child: Text(
                        announcement.statusDisplayText,
                        style: TextStyle(
                          fontSize: 11 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: announcement.statusColor,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8 * heightRatio),
            Text(
              'By: ${announcement.createdByEmail}',
              style: TextStyle(
                fontSize: 13 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 4 * heightRatio),
            Text(
              'Created: ${DateFormat('yyyy.MM.dd HH:mm').format(announcement.createdAt)}',
              style: TextStyle(
                fontSize: 12 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFCCCCCC),
                fontFamily: 'Pretendard',
              ),
            ),
            if (announcement.publishedAt != null) ...[
              SizedBox(height: 2 * heightRatio),
              Text(
                'Published: ${DateFormat('yyyy.MM.dd HH:mm').format(announcement.publishedAt!)}',
                style: TextStyle(
                  fontSize: 12 * widthRatio,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFCCCCCC),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ],
        ),
        children: [
          _buildAnnouncementDetails(announcement, widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildAnnouncementDetails(Announcement announcement, double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content
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
                    Icons.article_outlined,
                    size: 16 * widthRatio,
                    color: const Color(0xFF7C3AED),
                  ),
                  SizedBox(width: 8 * widthRatio),
                  Text(
                    'Content',
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
                announcement.content,
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

        // Action buttons
        Row(
          children: [
            if (announcement.status == AnnouncementStatus.draft) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _publishAnnouncement(announcement.id),
                  icon: Icon(Icons.publish, size: 16 * widthRatio),
                  label: Text(
                    'Publish',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
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
                onPressed: () => _showEditAnnouncementDialog(announcement, widthRatio, heightRatio),
                icon: Icon(Icons.edit_outlined, size: 16 * widthRatio),
                label: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  padding: EdgeInsets.symmetric(vertical: 12 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6 * widthRatio),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12 * widthRatio),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(announcement),
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

  void _showCreateAnnouncementDialog(double widthRatio, double heightRatio) {
    _showAnnouncementDialog(null, widthRatio, heightRatio);
  }

  void _showEditAnnouncementDialog(Announcement announcement, double widthRatio, double heightRatio) {
    _showAnnouncementDialog(announcement, widthRatio, heightRatio);
  }

  void _showAnnouncementDialog(Announcement? announcement, double widthRatio, double heightRatio) {
    final TextEditingController titleController = TextEditingController(text: announcement?.title ?? '');
    final TextEditingController contentController = TextEditingController(text: announcement?.content ?? '');
    bool isImportant = announcement?.isImportant ?? false;
    bool isPinned = announcement?.isPinned ?? false;
    AnnouncementStatus status = announcement?.status ?? AnnouncementStatus.draft;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                announcement == null ? 'Create Announcement' : 'Edit Announcement',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter announcement title...',
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
                      SizedBox(height: 16 * heightRatio),
                      TextField(
                        controller: contentController,
                        maxLines: 8,
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Content',
                          hintText: 'Enter announcement content...',
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
                      SizedBox(height: 16 * heightRatio),
                      // Options
                      CheckboxListTile(
                        title: Text(
                          'Mark as Important',
                          style: TextStyle(
                            fontSize: 14 * widthRatio,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        value: isImportant,
                        onChanged: (value) => setState(() => isImportant = value ?? false),
                        activeColor: const Color(0xFF7C3AED),
                      ),
                      CheckboxListTile(
                        title: Text(
                          'Pin to Top',
                          style: TextStyle(
                            fontSize: 14 * widthRatio,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        value: isPinned,
                        onChanged: (value) => setState(() => isPinned = value ?? false),
                        activeColor: const Color(0xFF7C3AED),
                      ),
                      SizedBox(height: 16 * heightRatio),
                      // Status selection
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 8 * heightRatio),
                      Wrap(
                        spacing: 8,
                        children: AnnouncementStatus.values.map((statusOption) {
                          return ChoiceChip(
                            label: Text(
                              statusOption == AnnouncementStatus.draft ? '임시저장' :
                              statusOption == AnnouncementStatus.published ? '게시' : '보관',
                              style: TextStyle(
                                fontSize: 12 * widthRatio,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            selected: status == statusOption,
                            onSelected: (selected) {
                              if (selected) setState(() => status = statusOption);
                            },
                            selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: status == statusOption 
                                  ? const Color(0xFF7C3AED) 
                                  : const Color(0xFF8E8E8E),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
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
                    if (titleController.text.trim().isNotEmpty && 
                        contentController.text.trim().isNotEmpty) {
                      _submitAnnouncement(
                        announcement?.id,
                        titleController.text.trim(),
                        contentController.text.trim(),
                        isImportant,
                        isPinned,
                        status,
                      );
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
                    announcement == null ? 'Create' : 'Update',
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
      },
    );
  }

  Future<void> _submitAnnouncement(
    String? id,
    String title,
    String content,
    bool isImportant,
    bool isPinned,
    AnnouncementStatus status,
  ) async {
    try {
      final submission = AnnouncementSubmission(
        title: title,
        content: content,
        isImportant: isImportant,
        isPinned: isPinned,
        status: status,
      );

      if (id == null) {
        // Create new announcement
        await _announcementService.createAnnouncement(submission);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement created successfully'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      } else {
        // Update existing announcement
        await _announcementService.updateAnnouncement(id, submission);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement updated successfully'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save announcement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _publishAnnouncement(String id) async {
    try {
      await _announcementService.publishAnnouncement(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement published successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish announcement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Announcement announcement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Announcement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this announcement? This action cannot be undone.',
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
                _deleteAnnouncement(announcement);
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

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    try {
      await _announcementService.deleteAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted successfully'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete announcement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}