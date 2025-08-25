import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';

class ReportsAdminPage extends StatefulWidget {
  const ReportsAdminPage({super.key});

  @override
  State<ReportsAdminPage> createState() => _ReportsAdminPageState();
}

class _ReportsAdminPageState extends State<ReportsAdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Backend service
  final ReportService _reportService = ReportService();
  
  // Streams for different report types
  Stream<List<Report>>? _allReportsStream;
  Stream<List<Report>>? _pendingReportsStream;
  Stream<List<Report>>? _reviewReportsStream;
  Stream<List<Report>>? _resolvedReportsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeStreams();
  }

  void _initializeStreams() {
    _allReportsStream = _reportService.getAllReportsForAdmin();
    _pendingReportsStream = _reportService.getAllReportsForAdmin(status: ReportStatus.pending);
    _reviewReportsStream = _reportService.getAllReportsForAdmin(status: ReportStatus.underReview);
    _resolvedReportsStream = _reportService.getAllReportsForAdmin(status: ReportStatus.resolved);
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
          'Reports Management',
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
              Icons.analytics_outlined,
              color: const Color(0xFF7C3AED),
              size: 24 * widthRatio,
            ),
            onPressed: () => _showStatisticsDialog(widthRatio, heightRatio),
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
            Tab(text: 'Pending'),
            Tab(text: 'Review'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamReportList(_allReportsStream, widthRatio, heightRatio),
          _buildStreamReportList(_pendingReportsStream, widthRatio, heightRatio),
          _buildStreamReportList(_reviewReportsStream, widthRatio, heightRatio),
          _buildStreamReportList(_resolvedReportsStream, widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildStreamReportList(Stream<List<Report>>? stream, double widthRatio, double heightRatio) {
    if (stream == null) {
      return _buildEmptyState(widthRatio, heightRatio);
    }

    return StreamBuilder<List<Report>>(
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
                  'Failed to load reports',
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
        
        final reports = snapshot.data ?? [];
        return _buildReportList(reports, widthRatio, heightRatio);
      },
    );
  }

  Widget _buildReportList(List<Report> reports, double widthRatio, double heightRatio) {
    if (reports.isEmpty) {
      return _buildEmptyState(widthRatio, heightRatio);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16 * widthRatio),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportItem(report, widthRatio, heightRatio);
      },
    );
  }

  Widget _buildEmptyState(double widthRatio, double heightRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64 * widthRatio,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 16 * heightRatio),
          Text(
            'No reports found',
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

  Widget _buildReportItem(Report report, double widthRatio, double heightRatio) {
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
            color: report.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20 * widthRatio),
          ),
          child: Icon(
            _getReportIcon(report.reportType),
            color: report.statusColor,
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
                    '${report.reportTypeDisplayText} - ${report.contentTypeDisplayText}',
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * widthRatio,
                    vertical: 4 * heightRatio,
                  ),
                  decoration: BoxDecoration(
                    color: report.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4 * widthRatio),
                  ),
                  child: Text(
                    report.statusDisplayText,
                    style: TextStyle(
                      fontSize: 11 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: report.statusColor,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * heightRatio),
            Text(
              'Reporter: ${report.reporterEmail}',
              style: TextStyle(
                fontSize: 13 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 4 * heightRatio),
            Text(
              'Reported: ${report.reportedUserEmail ?? report.reportedUserId}',
              style: TextStyle(
                fontSize: 13 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 4 * heightRatio),
            Text(
              DateFormat('yyyy.MM.dd HH:mm').format(report.createdAt),
              style: TextStyle(
                fontSize: 12 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFCCCCCC),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        children: [
          _buildReportDetails(report, widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildReportDetails(Report report, double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
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
                    Icons.description_outlined,
                    size: 16 * widthRatio,
                    color: const Color(0xFF7C3AED),
                  ),
                  SizedBox(width: 8 * widthRatio),
                  Text(
                    'Description',
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
                report.description,
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                  height: 1.4,
                ),
              ),
              if (report.contentText != null) ...[
                SizedBox(height: 12 * heightRatio),
                Text(
                  'Reported Content:',
                  style: TextStyle(
                    fontSize: 13 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 4 * heightRatio),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12 * widthRatio),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6 * widthRatio),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    report.contentText!,
                    style: TextStyle(
                      fontSize: 13 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF666666),
                      fontFamily: 'Pretendard',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 16 * heightRatio),

        // Admin notes if any
        if (report.adminNotes != null && report.adminNotes!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * widthRatio),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8 * widthRatio),
              border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 16 * widthRatio,
                      color: const Color(0xFF0EA5E9),
                    ),
                    SizedBox(width: 8 * widthRatio),
                    Text(
                      'Admin Notes',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0EA5E9),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * heightRatio),
                Text(
                  report.adminNotes!,
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1E3A8A),
                    fontFamily: 'Pretendard',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * heightRatio),
        ],

        // Action buttons
        Row(
          children: [
            if (report.status == ReportStatus.pending) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateReportStatus(report.id, ReportStatus.underReview),
                  icon: Icon(Icons.rate_review, size: 16 * widthRatio),
                  label: Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
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
            if (report.status != ReportStatus.resolved && report.status != ReportStatus.dismissed) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStatusDialog(report, widthRatio, heightRatio),
                  icon: Icon(Icons.check_circle, size: 16 * widthRatio),
                  label: Text(
                    'Resolve',
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
                onPressed: () => _showDeleteConfirmation(report),
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

  IconData _getReportIcon(ReportType reportType) {
    switch (reportType) {
      case ReportType.spam:
        return Icons.report_gmailerrorred;
      case ReportType.harassment:
        return Icons.person_remove;
      case ReportType.inappropriateContent:
        return Icons.content_copy;
      case ReportType.fakeProfiling:
        return Icons.person_off;
      case ReportType.violence:
        return Icons.dangerous;
      case ReportType.hateSpeech:
        return Icons.speaker_notes_off;
      case ReportType.copyright:
        return Icons.copyright;
      case ReportType.other:
        return Icons.flag;
    }
  }

  Future<void> _updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _reportService.updateReportStatus(reportId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${status.toString().split('.').last}'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusDialog(Report report, double widthRatio, double heightRatio) {
    final TextEditingController notesController = TextEditingController(text: report.adminNotes ?? '');
    ReportStatus selectedStatus = ReportStatus.resolved;

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
                'Update Report Status',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      children: [ReportStatus.resolved, ReportStatus.dismissed].map((status) {
                        return ChoiceChip(
                          label: Text(
                            status == ReportStatus.resolved ? '처리완료' : '기각',
                            style: TextStyle(
                              fontSize: 12 * widthRatio,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          selected: selectedStatus == status,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedStatus = status);
                          },
                          selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: selectedStatus == status 
                                ? const Color(0xFF7C3AED) 
                                : const Color(0xFF8E8E8E),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16 * heightRatio),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF121212),
                        fontFamily: 'Pretendard',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Admin Notes (Optional)',
                        hintText: 'Add notes about this resolution...',
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
                  ],
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
                    _updateReportStatusWithNotes(
                      report.id,
                      selectedStatus,
                      notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                    );
                    Navigator.of(context).pop();
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
                    'Update',
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

  Future<void> _updateReportStatusWithNotes(String reportId, ReportStatus status, String? notes) async {
    try {
      await _reportService.updateReportStatus(reportId, status, adminNotes: notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report ${status == ReportStatus.resolved ? 'resolved' : 'dismissed'} successfully'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Report report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this report? This action cannot be undone.',
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
                _deleteReport(report);
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

  Future<void> _deleteReport(Report report) async {
    try {
      await _reportService.deleteReport(report.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatisticsDialog(double widthRatio, double heightRatio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, int>>(
          future: _reportService.getReportStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load statistics: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final stats = snapshot.data!;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Report Statistics',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem('Total Reports', stats['total']?.toString() ?? '0', const Color(0xFF7C3AED)),
                    _buildStatItem('Pending', stats['pending']?.toString() ?? '0', const Color(0xFFF59E0B)),
                    _buildStatItem('Under Review', stats['underReview']?.toString() ?? '0', const Color(0xFF0EA5E9)),
                    _buildStatItem('Resolved', stats['resolved']?.toString() ?? '0', const Color(0xFF059669)),
                    _buildStatItem('Dismissed', stats['dismissed']?.toString() ?? '0', const Color(0xFF8E8E8E)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C3AED),
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }
}