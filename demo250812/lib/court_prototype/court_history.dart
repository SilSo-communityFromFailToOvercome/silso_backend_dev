import 'package:flutter/material.dart';
import '../services/court_service.dart';
import 'add_court.dart';

// Court history page - shows previous completed sessions
class CourtHistoryScreen extends StatefulWidget {
  const CourtHistoryScreen({super.key});

  @override
  State<CourtHistoryScreen> createState() => _CourtHistoryScreenState();
}

class _CourtHistoryScreenState extends State<CourtHistoryScreen> {
  final CourtService _courtService = CourtService();
  late Stream<List<CourtSessionData>> _historySessionsStream;

  @override
  void initState() {
    super.initState();
    _historySessionsStream = _courtService.getCompletedCourtSessions();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        title: Text(
          'Court History',
          style: TextStyle(
            fontSize: 20 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF121212)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20 * widthRatio),
              
              // Section title
              Text(
                'Previous Court Sessions',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 16 * widthRatio),
              
              // History sessions list
              Expanded(
                child: StreamBuilder<List<CourtSessionData>>(
                  stream: _historySessionsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64 * widthRatio,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16 * widthRatio),
                            Text(
                              'Error loading court history',
                              style: TextStyle(
                                fontSize: 18 * widthRatio,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            SizedBox(height: 8 * widthRatio),
                            Text(
                              snapshot.error.toString(),
                              style: TextStyle(
                                fontSize: 14 * widthRatio,
                                color: const Color(0xFF8E8E8E),
                                fontFamily: 'Pretendard',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
                        ),
                      );
                    }

                    final historySessions = snapshot.data ?? [];

                    if (historySessions.isEmpty) {
                      return _buildEmptyState(widthRatio);
                    }

                    return ListView.separated(
                      itemCount: historySessions.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12 * widthRatio),
                      itemBuilder: (context, index) {
                        final session = historySessions[index];
                        return _buildHistorySessionCard(session, widthRatio);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build simplified court history session card (title + result only)
  Widget _buildHistorySessionCard(CourtSessionData session, double widthRatio) {
    // Determine result colors and text
    String resultText = 'No Result';
    Color resultColor = const Color(0xFF8E8E8E);
    IconData resultIcon = Icons.help_outline;

    if (session.resultWin == 'guilty') {
      resultText = 'GUILTY';
      resultColor = const Color(0xFFDC2626);
      resultIcon = Icons.gavel;
    } else if (session.resultWin == 'not_guilty') {
      resultText = 'NOT GUILTY';
      resultColor = const Color(0xFF16A34A);
      resultIcon = Icons.shield_outlined;
    } else if (session.resultWin == 'tie') {
      resultText = 'TIE';
      resultColor = const Color(0xFF6B7280);
      resultIcon = Icons.balance;
    }

    return GestureDetector(
      onTap: () => _showSessionDetails(session),
      child: Container(
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Court session title
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  fontSize: 16 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(width: 12 * widthRatio),
            
            // Result indicator
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * widthRatio,
                vertical: 6 * widthRatio,
              ),
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(16 * widthRatio),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    resultIcon,
                    color: Colors.white,
                    size: 14 * widthRatio,
                  ),
                  SizedBox(width: 4 * widthRatio),
                  Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 11 * widthRatio,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow indicator
            SizedBox(width: 8 * widthRatio),
            Icon(
              Icons.arrow_forward_ios,
              size: 16 * widthRatio,
              color: const Color(0xFF8E8E8E),
            ),
          ],
        ),
      ),
    );
  }

  // Show detailed session information in a modal
  void _showSessionDetails(CourtSessionData session) {
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;

    // Calculate vote percentages
    final guiltyVotes = session.guiltyVotes;
    final notGuiltyVotes = session.notGuiltyVotes;
    final totalVotes = guiltyVotes + notGuiltyVotes;
    final guiltyRatio = totalVotes > 0 ? guiltyVotes / totalVotes : 0.5;

    // Determine result colors and text
    String resultText = 'No Result';
    Color resultColor = const Color(0xFF8E8E8E);
    IconData resultIcon = Icons.help_outline;

    if (session.resultWin == 'guilty') {
      resultText = 'GUILTY';
      resultColor = const Color(0xFFDC2626);
      resultIcon = Icons.gavel;
    } else if (session.resultWin == 'not_guilty') {
      resultText = 'NOT GUILTY';
      resultColor = const Color(0xFF16A34A);
      resultIcon = Icons.shield_outlined;
    } else if (session.resultWin == 'tie') {
      resultText = 'TIE';
      resultColor = const Color(0xFF6B7280);
      resultIcon = Icons.balance;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with result
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: resultColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      resultIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Court Session Result',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resultText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: resultColor,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Session title
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121212),
                  fontFamily: 'Pretendard',
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Session description
              Text(
                session.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF424242),
                  fontFamily: 'Pretendard',
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Vote results bar (similar to court main page)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background (not guilty - green)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Guilty section (red)
                    if (totalVotes > 0)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: guiltyRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF44336),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    // Percentage indicator
                    if (totalVotes > 0)
                      Positioned(
                        left: (MediaQuery.of(context).size.width * 0.6) * guiltyRatio - 30,
                        top: -8,
                        child: Container(
                          width: 60,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
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
                              '${(guiltyRatio * 100).round()}%',
                              style: const TextStyle(
                                color: Color(0xFF3F3329),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Vote count labels
                    Positioned.fill(
                      child: Row(
                        children: [
                          // Guilty count
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              '$guiltyVotes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Not guilty count
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '$notGuiltyVotes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Labels for vote bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Guilty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Not Guilty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Session info
              Row(
                children: [
                  Expanded(
                    child: _buildSessionInfoItem(
                      icon: Icons.people_outline,
                      label: 'Participants',
                      value: '${session.participants.length}',
                    ),
                  ),
                  Expanded(
                    child: _buildSessionInfoItem(
                      icon: Icons.schedule,
                      label: 'Completed',
                      value: _formatEndDate(session.dateEnded ?? session.dateCreated),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F37CF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build session info item
  Widget _buildSessionInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF8E8E8E),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // Build empty state when no history available
  Widget _buildEmptyState(double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64 * widthRatio,
            color: const Color(0xFFBDBDBD),
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            'No court history yet',
            style: TextStyle(
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * widthRatio),
          Text(
            'Completed court sessions will appear here',
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFBDBDBD),
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Format end date for display
  String _formatEndDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}