import 'dart:async';
import 'package:flutter/material.dart';
import 'court_main.dart';
import 'add_court.dart';
import 'court_history.dart';
import 'voting_case_list.dart';
import '../services/court_service.dart';

// Court list page - choose live sessions or create new court
class CourtListScreen extends StatefulWidget {
  const CourtListScreen({super.key});

  @override
  State<CourtListScreen> createState() => _CourtListScreenState();
}

class _CourtListScreenState extends State<CourtListScreen> {
  final CourtService _courtService = CourtService();
  late Stream<List<CourtSessionData>> _liveSessionsStream;

  @override
  void initState() {
    super.initState();
    _liveSessionsStream = _courtService.getLiveCourtSessions();
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
          'Court Sessions',
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
        actions: [
          // Voting case list button
          Padding(
            padding: EdgeInsets.only(right: 8 * widthRatio),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VotingCaseListScreen(),
                  ),
                );
              },
              icon: Container(
                padding: EdgeInsets.all(8 * widthRatio),
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.how_to_vote,
                  color: Colors.white,
                  size: 20 * widthRatio,
                ),
              ),
            ),
          ),
          // History button to view previous sessions
          Padding(
            padding: EdgeInsets.only(right: 8 * widthRatio),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CourtHistoryScreen(),
                  ),
                );
              },
              icon: Container(
                padding: EdgeInsets.all(8 * widthRatio),
                decoration: const BoxDecoration(
                  color: Color(0xFF6B7280),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 20 * widthRatio,
                ),
              ),
            ),
          ),
          // Plus button to create new court session
          Padding(
            padding: EdgeInsets.only(right: 16 * widthRatio),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddCourtScreen(),
                  ),
                );
              },
              icon: Container(
                padding: EdgeInsets.all(8 * widthRatio),
                decoration: const BoxDecoration(
                  color: Color(0xFF5F37CF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20 * widthRatio,
                ),
              ),
            ),
          ),
        ],
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
                'Live Court Sessions',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 16 * widthRatio),
              
              // Live sessions list
              Expanded(
                child: StreamBuilder<List<CourtSessionData>>(
                  stream: _liveSessionsStream,
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
                              'Error loading court sessions',
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

                    final liveSessions = snapshot.data ?? [];

                    if (liveSessions.isEmpty) {
                      return _buildEmptyState(widthRatio);
                    }

                    return ListView.separated(
                      itemCount: liveSessions.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12 * widthRatio),
                      itemBuilder: (context, index) {
                        final session = liveSessions[index];
                        return _buildCourtSessionCard(session, widthRatio);
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

  // Build individual court session card
  Widget _buildCourtSessionCard(CourtSessionData session, double widthRatio) {
    return GestureDetector(
      onTap: () => _joinCourtSession(session),
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with live indicator and category
            Row(
              children: [
                // Live indicator
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * widthRatio,
                    vertical: 4 * widthRatio,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444),
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6 * widthRatio,
                        height: 6 * widthRatio,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4 * widthRatio),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Category
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * widthRatio,
                    vertical: 4 * widthRatio,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F37CF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                  ),
                  child: Text(
                    session.category,
                    style: TextStyle(
                      fontSize: 10 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F37CF),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12 * widthRatio),
            
            // Court session title
            Text(
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
            
            SizedBox(height: 12 * widthRatio),
            
            // Footer with participants and time
            Row(
              children: [
                // Participant count
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16 * widthRatio,
                      color: const Color(0xFF8E8E8E),
                    ),
                    SizedBox(width: 4 * widthRatio),
                    Text(
                      '${session.currentLiveMembers} participants',
                      style: TextStyle(
                        fontSize: 12 * widthRatio,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E8E),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Time remaining with live countdown
                LiveCountdownTimer(session: session, widthRatio: widthRatio),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build empty state when no sessions available
  Widget _buildEmptyState(double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel_outlined,
            size: 64 * widthRatio,
            color: const Color(0xFFBDBDBD),
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            'No live court sessions',
            style: TextStyle(
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * widthRatio),
          Text(
            'Create your own court session to get started',
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

  // Format time remaining for display
  String _formatTimeRemaining(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m left';
    } else {
      return '${duration.inMinutes}m left';
    }
  }

  // Join a court session
  void _joinCourtSession(CourtSessionData session) async {
    try {
      // Join the session in Firestore
      await _courtService.joinCourtSession(session.id);
      
      if (mounted) {
        // Navigate to court prototype with session data
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CourtPrototypeScreen(courtSession: session),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to join session: ${e.toString()}',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

}

// Live countdown timer widget that updates every second
class LiveCountdownTimer extends StatefulWidget {
  final CourtSessionData session;
  final double widthRatio;

  const LiveCountdownTimer({
    super.key,
    required this.session,
    required this.widthRatio,
  });

  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  late Timer _timer;
  Duration _currentTimeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
      
      // If time is up, cancel timer and trigger session expiry check
      if (_currentTimeLeft <= Duration.zero) {
        timer.cancel();
        _handleSessionExpiry();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    if (mounted) {
      setState(() {
        _currentTimeLeft = widget.session.timeLeft;
      });
    }
  }

  void _handleSessionExpiry() {
    // The session will automatically be moved to history by the stream update
    // when the CourtService detects the expired session
    if (mounted) {
      final courtService = CourtService();
      courtService.checkAndEndExpiredSession(widget.session.id);
    }
  }

  String _formatCountdown(Duration duration) {
    if (duration <= Duration.zero) {
      return '0:00';
    }
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpiring = _currentTimeLeft.inSeconds <= 30; // Red when < 30 seconds
    final isExpired = _currentTimeLeft <= Duration.zero;
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16 * widget.widthRatio,
          color: isExpired 
              ? Colors.red 
              : isExpiring 
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFF8E8E8E),
        ),
        SizedBox(width: 4 * widget.widthRatio),
        Text(
          isExpired ? 'Ended' : _formatCountdown(_currentTimeLeft),
          style: TextStyle(
            fontSize: 12 * widget.widthRatio,
            fontWeight: isExpiring || isExpired ? FontWeight.w600 : FontWeight.w400,
            color: isExpired 
                ? Colors.red 
                : isExpiring 
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }
}