import 'package:flutter/material.dart';
import '../services/court_service.dart';
import 'add_court.dart';

// Voting case list page - 사건 list for voting on court cases
class VotingCaseListScreen extends StatefulWidget {
  const VotingCaseListScreen({super.key});

  @override
  State<VotingCaseListScreen> createState() => _VotingCaseListScreenState();
}

class _VotingCaseListScreenState extends State<VotingCaseListScreen> {
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
          '사건 투표',
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
                '진행 중인 사건',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 16 * widthRatio),
              
              // Ongoing cases list
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
                              'Error loading cases',
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

                    final cases = snapshot.data ?? [];

                    if (cases.isEmpty) {
                      return _buildEmptyState(widthRatio);
                    }

                    return ListView.separated(
                      itemCount: cases.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12 * widthRatio),
                      itemBuilder: (context, index) {
                        final caseData = cases[index];
                        return _buildCaseCard(caseData, widthRatio);
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

  // Build individual case card for voting
  Widget _buildCaseCard(CourtSessionData caseData, double widthRatio) {
    return GestureDetector(
      onTap: () => _showVotingPopup(caseData),
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
        child: Row(
          children: [
            // Case icon
            Container(
              padding: EdgeInsets.all(12 * widthRatio),
              decoration: const BoxDecoration(
                color: Color(0xFF5F37CF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gavel,
                color: Colors.white,
                size: 24 * widthRatio,
              ),
            ),
            
            SizedBox(width: 16 * widthRatio),
            
            // Case title
            Expanded(
              child: Text(
                caseData.title,
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
            
            // Arrow indicator
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

  // Show voting popup for a case
  void _showVotingPopup(CourtSessionData caseData) {
    showDialog(
      context: context,
      builder: (context) => VotingPopup(
        caseData: caseData,
        courtService: _courtService,
      ),
    );
  }

  // Build empty state when no cases available
  Widget _buildEmptyState(double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64 * widthRatio,
            color: const Color(0xFFBDBDBD),
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            '진행 중인 사건이 없습니다',
            style: TextStyle(
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * widthRatio),
          Text(
            '새로운 법정 세션이 생성되면 여기에 표시됩니다',
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
}

// Voting popup widget for individual cases
class VotingPopup extends StatefulWidget {
  final CourtSessionData caseData;
  final CourtService courtService;

  const VotingPopup({
    super.key,
    required this.caseData,
    required this.courtService,
  });

  @override
  State<VotingPopup> createState() => _VotingPopupState();
}

class _VotingPopupState extends State<VotingPopup> {
  bool _hasVoted = false;
  bool _votedGuilty = false;
  bool _isVoting = false;
  late Stream<CourtSessionData?> _caseStream;

  @override
  void initState() {
    super.initState();
    _caseStream = widget.courtService.getCourtSessionStream(widget.caseData.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CourtSessionData?>(
      stream: _caseStream,
      initialData: widget.caseData,
      builder: (context, snapshot) {
        final currentCaseData = snapshot.data ?? widget.caseData;
        
        // Calculate vote percentages from current data
        final guiltyVotes = currentCaseData.guiltyVotes;
        final notGuiltyVotes = currentCaseData.notGuiltyVotes;
        final totalVotes = guiltyVotes + notGuiltyVotes;
        final guiltyRatio = totalVotes > 0 ? guiltyVotes / totalVotes : 0.5;

        return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '사건 투표',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF121212),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8E8E8E),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case title
                    Text(
                      currentCaseData.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF121212),
                        fontFamily: 'Pretendard',
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Case description
                    Text(
                      currentCaseData.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF424242),
                        fontFamily: 'Pretendard',
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Vote buttons or results
                    if (!_hasVoted) ...[
                      // Voting instructions
                      const Text(
                        '이 사건에 대한 귀하의 판단을 투표해 주세요:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Vote buttons
                      Row(
                        children: [
                          // Guilty button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isVoting ? null : () => _submitVote(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isVoting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.gavel, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Guilty',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Pretendard',
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Not Guilty button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isVoting ? null : () => _submitVote(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isVoting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shield_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Not Guilty',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Pretendard',
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Vote confirmation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _votedGuilty ? const Color(0xFFDC2626).withOpacity(0.1) : const Color(0xFF16A34A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _votedGuilty ? const Color(0xFFDC2626).withOpacity(0.3) : const Color(0xFF16A34A).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _votedGuilty ? Icons.gavel : Icons.shield_outlined,
                              color: _votedGuilty ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '투표 완료: ${_votedGuilty ? "Guilty" : "Not Guilty"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _votedGuilty ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              color: _votedGuilty ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Vote results title
                      const Text(
                        '현재 투표 현황:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Vote results bar
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
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
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
                              color: const Color(0xFFF44336).withOpacity(0.8),
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
                              color: const Color(0xFF4CAF50).withOpacity(0.8),
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
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  // Submit vote for the case
  Future<void> _submitVote(bool isGuilty) async {
    if (_isVoting) return;

    setState(() {
      _isVoting = true;
    });

    try {
      await widget.courtService.castVote(
        courtId: widget.caseData.id,
        isGuilty: isGuilty,
      );

      if (mounted) {
        setState(() {
          _hasVoted = true;
          _votedGuilty = isGuilty;
          _isVoting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '투표가 완료되었습니다: ${isGuilty ? "Guilty" : "Not Guilty"}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: isGuilty ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '투표 실패: ${e.toString()}',
              style: const TextStyle(
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