import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../config/court_config.dart';

// Widget for displaying a case card with voting buttons and status
class CaseCardWidget extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback? onTap;
  final Function(CaseVoteType)? onVote;
  final bool showVotingButtons;
  final bool showQueuePosition;
  final bool showCourtSessionButton;
  final bool showCompletedInfo;

  const CaseCardWidget({
    super.key,
    required this.caseModel,
    this.onTap,
    this.onVote,
    this.showVotingButtons = false,
    this.showQueuePosition = false,
    this.showCourtSessionButton = false,
    this.showCompletedInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 393.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12 * widthRatio),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * widthRatio),
        child: Padding(
          padding: EdgeInsets.all(16 * widthRatio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and status
              _buildHeader(widthRatio),
              
              SizedBox(height: 12 * widthRatio),
              
              // Title
              _buildTitle(widthRatio),
              
              SizedBox(height: 8 * widthRatio),
              
              // Description
              _buildDescription(widthRatio),
              
              SizedBox(height: 12 * widthRatio),
              
              // Vote progress bar
              _buildVoteProgress(widthRatio),
              
              SizedBox(height: 12 * widthRatio),
              
              // Bottom section (voting buttons or other actions)
              _buildBottomSection(widthRatio),
            ],
          ),
        ),
      ),
    );
  }

  // Build header with category and status
  Widget _buildHeader(double widthRatio) {
    return Row(
      children: [
        // Category chip
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * widthRatio,
            vertical: 4 * widthRatio,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF5F37CF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12 * widthRatio),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getCategoryIcon(),
                style: TextStyle(fontSize: 12 * widthRatio),
              ),
              SizedBox(width: 4 * widthRatio),
              Text(
                _getCategoryName(),
                style: TextStyle(
                  fontSize: 11 * widthRatio,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5F37CF),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Status chip
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * widthRatio,
            vertical: 4 * widthRatio,
          ),
          decoration: BoxDecoration(
            color: Color(caseModel.statusColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12 * widthRatio),
          ),
          child: Text(
            caseModel.statusDisplayText,
            style: TextStyle(
              fontSize: 11 * widthRatio,
              fontWeight: FontWeight.w500,
              color: Color(caseModel.statusColor),
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        
        // Queue position indicator
        if (showQueuePosition && caseModel.queuePosition > 0) ...[
          SizedBox(width: 8 * widthRatio),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * widthRatio,
              vertical: 2 * widthRatio,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(8 * widthRatio),
            ),
            child: Text(
              '#${caseModel.queuePosition}',
              style: TextStyle(
                fontSize: 10 * widthRatio,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Build title
  Widget _buildTitle(double widthRatio) {
    return Text(
      caseModel.title,
      style: TextStyle(
        fontSize: 16 * widthRatio,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF121212),
        fontFamily: 'Pretendard',
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Build description
  Widget _buildDescription(double widthRatio) {
    return Text(
      caseModel.description,
      style: TextStyle(
        fontSize: 14 * widthRatio,
        color: const Color(0xFF424242),
        fontFamily: 'Pretendard',
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Build vote progress bar
  Widget _buildVoteProgress(double widthRatio) {
    return Builder(
      builder: (context) => Column(
        children: [
          // Progress bar
          Container(
            height: 6 * widthRatio,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3 * widthRatio),
              color: const Color(0xFFE0E0E0),
            ),
            child: Stack(
              children: [
                // Guilty (left side) - Red
                if (caseModel.guiltyPercentage > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: (caseModel.guiltyPercentage / 100) * 
                             (MediaQuery.of(context).size.width - 64 * widthRatio),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3 * widthRatio),
                        color: const Color(0xFFFF4444),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        
        SizedBox(height: 8 * widthRatio),
        
        // Vote counts and percentages
        Row(
          children: [
            // Guilty side
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8 * widthRatio,
                    height: 8 * widthRatio,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6 * widthRatio),
                  Text(
                    '유죄',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${caseModel.guiltyVotes}표 (${caseModel.guiltyPercentage.toInt()}%)',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 16 * widthRatio),
            
            // Not guilty side
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${caseModel.notGuiltyVotes}표 (${(100 - caseModel.guiltyPercentage).toInt()}%)',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '무죄',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(width: 6 * widthRatio),
                  Container(
                    width: 8 * widthRatio,
                    height: 8 * widthRatio,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  // Build bottom section with voting buttons or other actions
  Widget _buildBottomSection(double widthRatio) {
    if (showVotingButtons && onVote != null) {
      return _buildVotingButtons(widthRatio);
    } else if (showCourtSessionButton) {
      return _buildCourtSessionButton(widthRatio);
    } else if (showCompletedInfo) {
      return _buildCompletedInfo(widthRatio);
    } else {
      return _buildInfoRow(widthRatio);
    }
  }

  // Build voting buttons
  Widget _buildVotingButtons(double widthRatio) {
    return Row(
      children: [
        // Total votes info
        Expanded(
          child: Text(
            '총 ${caseModel.totalVotes}표 • ${_getTimeRemainingText()}',
            style: TextStyle(
              fontSize: 12 * widthRatio,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        
        SizedBox(width: 12 * widthRatio),
        
        // Voting buttons
        Row(
          children: [
            // Guilty button
            ElevatedButton(
              onPressed: () => onVote!(CaseVoteType.guilty),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4444),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * widthRatio,
                  vertical: 8 * widthRatio,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6 * widthRatio),
                ),
                elevation: 1,
                minimumSize: Size.zero,
              ),
              child: Text(
                '유죄',
                style: TextStyle(
                  fontSize: 12 * widthRatio,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            
            SizedBox(width: 8 * widthRatio),
            
            // Not guilty button
            ElevatedButton(
              onPressed: () => onVote!(CaseVoteType.notGuilty),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * widthRatio,
                  vertical: 8 * widthRatio,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6 * widthRatio),
                ),
                elevation: 1,
                minimumSize: Size.zero,
              ),
              child: Text(
                '무죄',
                style: TextStyle(
                  fontSize: 12 * widthRatio,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build court session button
  Widget _buildCourtSessionButton(double widthRatio) {
    return Row(
      children: [
        // Session info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '법정 토론 진행 중',
                style: TextStyle(
                  fontSize: 12 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9C27B0),
                  fontFamily: 'Pretendard',
                ),
              ),
              if (caseModel.promotedAt != null)
                Text(
                  '시작: ${_formatDateTime(caseModel.promotedAt!)}',
                  style: TextStyle(
                    fontSize: 11 * widthRatio,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
            ],
          ),
        ),
        
        // Join button
        ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: 12 * widthRatio,
              vertical: 8 * widthRatio,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6 * widthRatio),
            ),
            elevation: 1,
            minimumSize: Size.zero,
          ),
          icon: Icon(Icons.gavel, size: 14 * widthRatio),
          label: Text(
            '참여',
            style: TextStyle(
              fontSize: 12 * widthRatio,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }

  // Build completed info
  Widget _buildCompletedInfo(double widthRatio) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '토론 완료',
                style: TextStyle(
                  fontSize: 12 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF607D8B),
                  fontFamily: 'Pretendard',
                ),
              ),
              if (caseModel.promotedAt != null)
                Text(
                  '완료: ${_formatDateTime(caseModel.promotedAt!)}',
                  style: TextStyle(
                    fontSize: 11 * widthRatio,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                ),
            ],
          ),
        ),
        
        // View results button
        OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF607D8B),
            side: const BorderSide(color: Color(0xFF607D8B)),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * widthRatio,
              vertical: 8 * widthRatio,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6 * widthRatio),
            ),
            minimumSize: Size.zero,
          ),
          icon: Icon(Icons.visibility, size: 14 * widthRatio),
          label: Text(
            '결과 보기',
            style: TextStyle(
              fontSize: 12 * widthRatio,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }

  // Build basic info row
  Widget _buildInfoRow(double widthRatio) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14 * widthRatio,
          color: const Color(0xFF8E8E8E),
        ),
        SizedBox(width: 4 * widthRatio),
        Text(
          _getTimeRemainingText(),
          style: TextStyle(
            fontSize: 12 * widthRatio,
            color: const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
        
        const Spacer(),
        
        Text(
          '총 ${caseModel.totalVotes}표',
          style: TextStyle(
            fontSize: 12 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF424242),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getCategoryIcon() {
    try {
      final category = CaseCategory.values.firstWhere(
        (cat) => cat.name == caseModel.category.toLowerCase(),
      );
      return category.iconData;
    } catch (e) {
      return '📋'; // Default icon
    }
  }

  String _getCategoryName() {
    try {
      final category = CaseCategory.values.firstWhere(
        (cat) => cat.name == caseModel.category.toLowerCase(),
      );
      return category.displayName;
    } catch (e) {
      return caseModel.category; // Fallback to original category
    }
  }

  String _getTimeRemainingText() {
    if (caseModel.status == CaseStatus.voting) {
      final remaining = caseModel.timeRemaining;
      if (remaining == null) return '만료 없음';
      
      if (remaining.inDays > 0) {
        return '${remaining.inDays}일 남음';
      } else if (remaining.inHours > 0) {
        return '${remaining.inHours}시간 남음';
      } else if (remaining.inMinutes > 0) {
        return '${remaining.inMinutes}분 남음';
      } else {
        return '곧 만료';
      }
    } else {
      return _formatDateTime(caseModel.createdAt);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}