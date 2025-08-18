import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';

// Detailed view of a case with voting history and information
class CaseDetailScreen extends StatefulWidget {
  final CaseModel caseModel;

  const CaseDetailScreen({
    super.key,
    required this.caseModel,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final CaseService _caseService = CaseService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 393.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: Text(
          '사건 상세',
          style: TextStyle(
            fontSize: 20 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121212)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // Case information
            _buildCaseInfoCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // Voting results
            _buildVotingResultsCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // Timeline
            _buildTimelineCard(widthRatio),
            
            if (widget.caseModel.status == CaseStatus.voting) ...[
              SizedBox(height: 24 * widthRatio),
              _buildVotingButtons(widthRatio),
            ],
          ],
        ),
      ),
    );
  }

  // Build status card
  Widget _buildStatusCard(double widthRatio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * widthRatio),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * widthRatio),
                  decoration: BoxDecoration(
                    color: Color(widget.caseModel.statusColor).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Color(widget.caseModel.statusColor),
                    size: 20 * widthRatio,
                  ),
                ),
                SizedBox(width: 12 * widthRatio),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.caseModel.statusDisplayText,
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: Color(widget.caseModel.statusColor),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 4 * widthRatio),
                      Text(
                        _getStatusDescription(),
                        style: TextStyle(
                          fontSize: 12 * widthRatio,
                          color: const Color(0xFF8E8E8E),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (widget.caseModel.queuePosition > 0) ...[
              SizedBox(height: 12 * widthRatio),
              Container(
                padding: EdgeInsets.all(12 * widthRatio),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8 * widthRatio),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.queue,
                      color: const Color(0xFFFF9800),
                      size: 16 * widthRatio,
                    ),
                    SizedBox(width: 8 * widthRatio),
                    Text(
                      '대기열 ${widget.caseModel.queuePosition}번째',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF9800),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build case information card
  Widget _buildCaseInfoCard(double widthRatio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * widthRatio),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category and creator
            Row(
              children: [
                Text(
                  _getCategoryIcon(),
                  style: TextStyle(fontSize: 16 * widthRatio),
                ),
                SizedBox(width: 6 * widthRatio),
                Text(
                  _getCategoryName(),
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5F37CF),
                    fontFamily: 'Pretendard',
                  ),
                ),
                const Spacer(),
                Text(
                  widget.caseModel.creatorName,
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            // Title
            Text(
              widget.caseModel.title,
              style: TextStyle(
                fontSize: 18 * widthRatio,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
                height: 1.3,
              ),
            ),
            
            SizedBox(height: 12 * widthRatio),
            
            // Description
            Text(
              widget.caseModel.description,
              style: TextStyle(
                fontSize: 14 * widthRatio,
                color: const Color(0xFF424242),
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            // Creation date and expiry
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: const Color(0xFF8E8E8E),
                  size: 14 * widthRatio,
                ),
                SizedBox(width: 4 * widthRatio),
                Text(
                  '생성: ${_formatDateTime(widget.caseModel.createdAt)}',
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
                
                if (widget.caseModel.expiresAt != null) ...[
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    color: const Color(0xFF8E8E8E),
                    size: 14 * widthRatio,
                  ),
                  SizedBox(width: 4 * widthRatio),
                  Text(
                    '만료: ${_formatDateTime(widget.caseModel.expiresAt!)}',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build voting results card
  Widget _buildVotingResultsCard(double widthRatio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * widthRatio),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '투표 결과',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            // Progress bar
            Container(
              height: 8 * widthRatio,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * widthRatio),
                color: const Color(0xFFE0E0E0),
              ),
              child: Stack(
                children: [
                  // Guilty (red) side
                  if (widget.caseModel.guiltyPercentage > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: (widget.caseModel.guiltyPercentage / 100) * 
                               (MediaQuery.of(context).size.width - 64 * widthRatio),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4 * widthRatio),
                          color: const Color(0xFFFF4444),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            // Vote details
            Row(
              children: [
                // Guilty side
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12 * widthRatio,
                            height: 12 * widthRatio,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8 * widthRatio),
                          Text(
                            '유죄',
                            style: TextStyle(
                              fontSize: 14 * widthRatio,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF424242),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * widthRatio),
                      Text(
                        '${widget.caseModel.guiltyVotes}표',
                        style: TextStyle(
                          fontSize: 24 * widthRatio,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF4444),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      Text(
                        '${widget.caseModel.guiltyPercentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          color: const Color(0xFF8E8E8E),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Container(
                  width: 1,
                  height: 60 * widthRatio,
                  color: const Color(0xFFE0E0E0),
                ),
                
                // Not guilty side
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '무죄',
                            style: TextStyle(
                              fontSize: 14 * widthRatio,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF424242),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          SizedBox(width: 8 * widthRatio),
                          Container(
                            width: 12 * widthRatio,
                            height: 12 * widthRatio,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * widthRatio),
                      Text(
                        '${widget.caseModel.notGuiltyVotes}표',
                        style: TextStyle(
                          fontSize: 24 * widthRatio,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4CAF50),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      Text(
                        '${(100 - widget.caseModel.guiltyPercentage).toInt()}%',
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          color: const Color(0xFF8E8E8E),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            // Summary
            Container(
              padding: EdgeInsets.all(12 * widthRatio),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.poll,
                    color: const Color(0xFF5F37CF),
                    size: 16 * widthRatio,
                  ),
                  SizedBox(width: 8 * widthRatio),
                  Text(
                    '총 ${widget.caseModel.totalVotes}표 • 논쟁성 ${widget.caseModel.controversyScore.toInt()}점',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build timeline card
  Widget _buildTimelineCard(double widthRatio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * widthRatio),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '진행 상황',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            _buildTimelineItem(
              '사건 제출',
              _formatDateTime(widget.caseModel.createdAt),
              true,
              Icons.add_circle,
              const Color(0xFF4CAF50),
              widthRatio,
            ),
            
            if (widget.caseModel.status.index >= CaseStatus.qualified.index)
              _buildTimelineItem(
                '승급 조건 달성',
                '투표 ${widget.caseModel.totalVotes}표 달성',
                true,
                Icons.check_circle,
                const Color(0xFF4CAF50),
                widthRatio,
              ),
            
            if (widget.caseModel.status == CaseStatus.queued)
              _buildTimelineItem(
                '대기열 진입',
                '법정 슬롯 대기 중',
                true,
                Icons.queue,
                const Color(0xFFFF9800),
                widthRatio,
              ),
            
            if (widget.caseModel.status.index >= CaseStatus.promoted.index)
              _buildTimelineItem(
                '법정 승급',
                widget.caseModel.promotedAt != null 
                    ? _formatDateTime(widget.caseModel.promotedAt!)
                    : '승급됨',
                true,
                Icons.gavel,
                const Color(0xFF9C27B0),
                widthRatio,
              ),
            
            if (widget.caseModel.status == CaseStatus.completed)
              _buildTimelineItem(
                '토론 완료',
                '법정 세션 종료',
                true,
                Icons.done_all,
                const Color(0xFF607D8B),
                widthRatio,
              )
            else if (widget.caseModel.status == CaseStatus.voting)
              _buildTimelineItem(
                '법정 승급 대기',
                '더 많은 투표가 필요합니다',
                false,
                Icons.how_to_vote,
                const Color(0xFF8E8E8E),
                widthRatio,
              ),
          ],
        ),
      ),
    );
  }

  // Build timeline item
  Widget _buildTimelineItem(
    String title,
    String subtitle,
    bool completed,
    IconData icon,
    Color color,
    double widthRatio,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * widthRatio),
      child: Row(
        children: [
          Container(
            width: 32 * widthRatio,
            height: 32 * widthRatio,
            decoration: BoxDecoration(
              color: completed ? color : color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: completed ? Colors.white : color,
              size: 16 * widthRatio,
            ),
          ),
          
          SizedBox(width: 12 * widthRatio),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: completed ? const Color(0xFF121212) : const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 2 * widthRatio),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build voting buttons for active cases
  Widget _buildVotingButtons(double widthRatio) {
    return Row(
      children: [
        // Guilty button
        Expanded(
          child: ElevatedButton(
            onPressed: () => _voteOnCase(CaseVoteType.guilty),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * widthRatio),
              ),
              elevation: 2,
            ),
            child: Text(
              '유죄 투표',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ),
        
        SizedBox(width: 12 * widthRatio),
        
        // Not guilty button
        Expanded(
          child: ElevatedButton(
            onPressed: () => _voteOnCase(CaseVoteType.notGuilty),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * widthRatio),
              ),
              elevation: 2,
            ),
            child: Text(
              '무죄 투표',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Vote on case
  Future<void> _voteOnCase(CaseVoteType voteType) async {
    try {
      await _caseService.voteOnCase(
        caseId: widget.caseModel.id,
        voteType: voteType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '투표가 완료되었습니다 (${voteType.displayName})',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to refresh the list
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '투표 실패: ${e.toString()}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFE57373),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper methods
  IconData _getStatusIcon() {
    switch (widget.caseModel.status) {
      case CaseStatus.voting:
        return Icons.how_to_vote;
      case CaseStatus.qualified:
        return Icons.check_circle;
      case CaseStatus.queued:
        return Icons.queue;
      case CaseStatus.promoted:
        return Icons.gavel;
      case CaseStatus.completed:
        return Icons.done_all;
      case CaseStatus.expired:
        return Icons.schedule;
      case CaseStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusDescription() {
    switch (widget.caseModel.status) {
      case CaseStatus.voting:
        return '투표를 통해 법정 승급을 기다리는 중입니다';
      case CaseStatus.qualified:
        return '승급 조건을 달성했습니다';
      case CaseStatus.queued:
        return '법정 슬롯을 기다리는 중입니다';
      case CaseStatus.promoted:
        return '법정에서 토론이 진행 중입니다';
      case CaseStatus.completed:
        return '법정 토론이 완료되었습니다';
      case CaseStatus.expired:
        return '투표 기간이 만료되었습니다';
      case CaseStatus.rejected:
        return '관리자에 의해 거부되었습니다';
    }
  }

  String _getCategoryIcon() {
    try {
      final category = CaseCategory.values.firstWhere(
        (cat) => cat.name == widget.caseModel.category.toLowerCase(),
      );
      return category.iconData;
    } catch (e) {
      return '📋';
    }
  }

  String _getCategoryName() {
    try {
      final category = CaseCategory.values.firstWhere(
        (cat) => cat.name == widget.caseModel.category.toLowerCase(),
      );
      return category.displayName;
    } catch (e) {
      return widget.caseModel.category;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}