import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportDialog {
  static void show({
    required BuildContext context,
    required String reportedUserId,
    String? reportedUserEmail,
    ReportedContentType contentType = ReportedContentType.user,
    String? contentId,
    String? contentText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ReportDialogContent(
          reportedUserId: reportedUserId,
          reportedUserEmail: reportedUserEmail,
          contentType: contentType,
          contentId: contentId,
          contentText: contentText,
        );
      },
    );
  }
}

class _ReportDialogContent extends StatefulWidget {
  final String reportedUserId;
  final String? reportedUserEmail;
  final ReportedContentType contentType;
  final String? contentId;
  final String? contentText;

  const _ReportDialogContent({
    required this.reportedUserId,
    this.reportedUserEmail,
    required this.contentType,
    this.contentId,
    this.contentText,
  });

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();
  
  ReportType _selectedReportType = ReportType.spam;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.flag,
            color: const Color(0xFFDC2626),
            size: 24 * widthRatio,
          ),
          SizedBox(width: 8 * widthRatio),
          Expanded(
            child: Text(
              '신고하기',
              style: TextStyle(
                fontSize: 18 * widthRatio,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '신고 사유를 선택해 주세요',
                style: TextStyle(
                  fontSize: 16 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 16 * widthRatio),
              
              // Report type selection
              ...ReportType.values.map((reportType) {
                return RadioListTile<ReportType>(
                  title: Text(
                    _getReportTypeDisplayText(reportType),
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  subtitle: Text(
                    _getReportTypeDescription(reportType),
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  value: reportType,
                  groupValue: _selectedReportType,
                  onChanged: (ReportType? value) {
                    if (value != null) {
                      setState(() {
                        _selectedReportType = value;
                      });
                    }
                  },
                  activeColor: const Color(0xFF7C3AED),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              
              SizedBox(height: 16 * widthRatio),
              
              // Description field
              Text(
                '상세 내용 (선택사항)',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 8 * widthRatio),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
                decoration: InputDecoration(
                  hintText: '신고 사유에 대해 자세히 설명해 주세요...',
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
                  contentPadding: EdgeInsets.all(12 * widthRatio),
                ),
              ),
              
              SizedBox(height: 16 * widthRatio),
              
              // Warning message
              Container(
                padding: EdgeInsets.all(12 * widthRatio),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: const Color(0xFFD97706),
                      size: 16 * widthRatio,
                    ),
                    SizedBox(width: 8 * widthRatio),
                    Expanded(
                      child: Text(
                        '허위 신고나 악의적인 신고는 제재를 받을 수 있습니다. 신중하게 신고해 주세요.',
                        style: TextStyle(
                          fontSize: 12 * widthRatio,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD97706),
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
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () {
            Navigator.of(context).pop();
          },
          child: Text(
            '취소',
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 16 * widthRatio,
                  height: 16 * widthRatio,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '신고하기',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
        ),
      ],
    );
  }

  String _getReportTypeDisplayText(ReportType reportType) {
    switch (reportType) {
      case ReportType.spam:
        return '스팸';
      case ReportType.harassment:
        return '괴롭힘';
      case ReportType.inappropriateContent:
        return '부적절한 콘텐츠';
      case ReportType.fakeProfiling:
        return '허위 프로필';
      case ReportType.violence:
        return '폭력적 콘텐츠';
      case ReportType.hateSpeech:
        return '혐오 발언';
      case ReportType.copyright:
        return '저작권 침해';
      case ReportType.other:
        return '기타';
    }
  }

  String _getReportTypeDescription(ReportType reportType) {
    switch (reportType) {
      case ReportType.spam:
        return '광고, 홍보글, 반복적인 게시물';
      case ReportType.harassment:
        return '따돌림, 협박, 지속적인 괴롭힘';
      case ReportType.inappropriateContent:
        return '선정적이거나 부적절한 내용';
      case ReportType.fakeProfiling:
        return '가짜 계정이나 사칭';
      case ReportType.violence:
        return '폭력적인 내용이나 위협';
      case ReportType.hateSpeech:
        return '혐오 표현이나 차별적 발언';
      case ReportType.copyright:
        return '저작권을 침해하는 콘텐츠';
      case ReportType.other:
        return '기타 부적절한 행위';
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submission = ReportSubmission(
        reportedUserId: widget.reportedUserId,
        reportedUserEmail: widget.reportedUserEmail,
        contentType: widget.contentType,
        contentId: widget.contentId,
        contentText: widget.contentText,
        reportType: _selectedReportType,
        description: _descriptionController.text.trim().isEmpty 
            ? _getReportTypeDisplayText(_selectedReportType)
            : _descriptionController.text.trim(),
      );

      await _reportService.submitReport(submission);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}