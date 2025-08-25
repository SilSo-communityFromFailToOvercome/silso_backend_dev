import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../config/court_config.dart';

// Widget for displaying queue status and system capacity
class QueueStatusWidget extends StatelessWidget {
  const QueueStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthRatio = screenWidth / 393.0;

    return Container(
      margin: EdgeInsets.all(16 * widthRatio),
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * widthRatio),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: CaseService().getSystemStatus(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorView(widthRatio);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingView(widthRatio);
          }

          final status = snapshot.data ?? {};
          return _buildStatusView(status, widthRatio);
        },
      ),
    );
  }

  // Build loading view
  Widget _buildLoadingView(double widthRatio) {
    return Row(
      children: [
        SizedBox(
          width: 16 * widthRatio,
          height: 16 * widthRatio,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
          ),
        ),
        SizedBox(width: 12 * widthRatio),
        Text(
          '대기열 상태를 확인하는 중...',
          style: TextStyle(
            fontSize: 14 * widthRatio,
            color: const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // Build error view
  Widget _buildErrorView(double widthRatio) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: const Color(0xFFE57373),
          size: 16 * widthRatio,
        ),
        SizedBox(width: 8 * widthRatio),
        Text(
          '상태 정보를 불러올 수 없습니다',
          style: TextStyle(
            fontSize: 14 * widthRatio,
            color: const Color(0xFFE57373),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // Build status view
  Widget _buildStatusView(Map<String, dynamic> status, double widthRatio) {
    final queuedCases = status['queuedCases'] ?? 0;
    final activeSessions = status['activeCourtSessions'] ?? 0;
    final maxSessions = status['maxConcurrentSessions'] ?? 0;
    final queueCapacity = CourtSystemConfig.maxQueueSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.queue,
              color: const Color(0xFF5F37CF),
              size: 20 * widthRatio,
            ),
            SizedBox(width: 8 * widthRatio),
            Text(
              '법정 승급 대기열',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16 * widthRatio),
        
        // Status indicators
        Row(
          children: [
            // Queue status
            Expanded(
              child: _buildStatusItem(
                '대기 중',
                '$queuedCases',
                '$queueCapacity',
                queuedCases / queueCapacity,
                const Color(0xFFFF9800),
                widthRatio,
              ),
            ),
            
            SizedBox(width: 16 * widthRatio),
            
            // Court sessions status
            Expanded(
              child: _buildStatusItem(
                '법정 진행',
                '$activeSessions',
                '$maxSessions',
                activeSessions / maxSessions,
                const Color(0xFF9C27B0),
                widthRatio,
              ),
            ),
          ],
        ),
        
        if (queuedCases > 0) ...[
          SizedBox(height: 16 * widthRatio),
          _buildQueueInfo(queuedCases, activeSessions, maxSessions, widthRatio),
        ],
      ],
    );
  }

  // Build individual status item
  Widget _buildStatusItem(
    String label,
    String current,
    String max,
    double ratio,
    Color color,
    double widthRatio,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12 * widthRatio,
            color: const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
        
        SizedBox(height: 4 * widthRatio),
        
        Row(
          children: [
            Text(
              current,
              style: TextStyle(
                fontSize: 18 * widthRatio,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Pretendard',
              ),
            ),
            Text(
              '/$max',
              style: TextStyle(
                fontSize: 14 * widthRatio,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        
        SizedBox(height: 6 * widthRatio),
        
        // Progress bar
        Container(
          height: 4 * widthRatio,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2 * widthRatio),
            color: color.withValues(alpha: 0.2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2 * widthRatio),
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build queue information
  Widget _buildQueueInfo(int queuedCases, int activeSessions, int maxSessions, double widthRatio) {
    final availableSlots = maxSessions - activeSessions;
    final estimatedWaitTime = queuedCases > 0 && availableSlots <= 0 
        ? CourtSystemConfig.getSessionDuration() 
        : Duration.zero;

    return Container(
      padding: EdgeInsets.all(12 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8 * widthRatio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF5F37CF),
                size: 14 * widthRatio,
              ),
              SizedBox(width: 6 * widthRatio),
              Text(
                '대기열 정보',
                style: TextStyle(
                  fontSize: 12 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F37CF),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8 * widthRatio),
          
          if (availableSlots > 0)
            Text(
              '• 현재 $availableSlots개의 법정 슬롯이 비어있어 곧 승급될 예정입니다',
              style: TextStyle(
                fontSize: 11 * widthRatio,
                color: const Color(0xFF4CAF50),
                fontFamily: 'Pretendard',
              ),
            )
          else
            Text(
              '• 모든 법정이 사용 중입니다. 예상 대기시간: ${_formatDuration(estimatedWaitTime)}',
              style: TextStyle(
                fontSize: 11 * widthRatio,
                color: const Color(0xFF424242),
                fontFamily: 'Pretendard',
              ),
            ),
          
          SizedBox(height: 4 * widthRatio),
          
          Text(
            '• 승급 순서는 논쟁성과 투표 수를 기준으로 결정됩니다',
            style: TextStyle(
              fontSize: 11 * widthRatio,
              color: const Color(0xFF424242),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  // Format duration
  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '대기 없음';
    
    if (duration.inHours > 0) {
      return '약 ${duration.inHours}시간';
    } else if (duration.inMinutes > 0) {
      return '약 ${duration.inMinutes}분';
    } else {
      return '곧';
    }
  }
}