import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';
import '../services/court_service.dart';
import '../config/court_config.dart';
import 'add_case_screen.dart';
import 'case_detail_screen.dart';
import 'court_main.dart';
import '../widgets/case_card_widget.dart';
import '../widgets/queue_status_widget.dart';

// 사건 (Case) voting page - main voting interface before court sessions
class CaseVotingScreen extends StatefulWidget {
  const CaseVotingScreen({super.key});

  @override
  State<CaseVotingScreen> createState() => _CaseVotingScreenState();
}

class _CaseVotingScreenState extends State<CaseVotingScreen> with TickerProviderStateMixin {
  final CaseService _caseService = CaseService();
  final CourtService _courtService = CourtService();
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          '사건 투표',
          style: TextStyle(
            fontSize: 24 * widthRatio,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: const Color(0xFF5F37CF),
              size: 28 * widthRatio,
            ),
            onPressed: () => _navigateToAddCase(),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: const Color(0xFF8E8E8E),
              size: 24 * widthRatio,
            ),
            onPressed: () => _showSystemInfoDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5F37CF),
          unselectedLabelColor: const Color(0xFF8E8E8E),
          indicatorColor: const Color(0xFF5F37CF),
          labelStyle: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w400,
            fontFamily: 'Pretendard',
          ),
          tabs: const [
            Tab(text: '투표 중'),
            Tab(text: '대기열'),
            Tab(text: '법정 진행'),
            Tab(text: '완료됨'),
          ],
        ),
      ),
      body: Column(
        children: [
          // System status indicator
          _buildSystemStatusBar(widthRatio),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVotingTab(widthRatio),
                _buildQueueTab(widthRatio),
                _buildActiveCourtTab(widthRatio),
                _buildCompletedTab(widthRatio),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddCase(),
              backgroundColor: const Color(0xFF5F37CF),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                '사건 제출',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          : null,
    );
  }

  // Build system status bar
  Widget _buildSystemStatusBar(double widthRatio) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio, vertical: 8 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE0E0E0),
            width: 1 * widthRatio,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF5F37CF),
            size: 16 * widthRatio,
          ),
          SizedBox(width: 8 * widthRatio),
          Expanded(
            child: Text(
              '투표로 ${CourtSystemConfig.controversyRatioMin.toInt()}-${CourtSystemConfig.controversyRatioMax.toInt()}% 범위에 도달하면 법정으로 승급됩니다',
              style: TextStyle(
                fontSize: 12 * widthRatio,
                color: const Color(0xFF5F37CF),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _caseService.getSystemStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final status = snapshot.data!;
                final activeSessions = status['activeCourtSessions'] ?? 0;
                final maxSessions = status['maxConcurrentSessions'] ?? 0;
                return Text(
                  '법정: $activeSessions/$maxSessions',
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    color: const Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Build voting tab (active cases)
  Widget _buildVotingTab(double widthRatio) {
    return StreamBuilder<List<CaseModel>>(
      stream: _caseService.getActiveVotingCases(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString(), widthRatio);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(widthRatio);
        }

        final cases = snapshot.data ?? [];

        if (cases.isEmpty) {
          return _buildEmptyView(
            '진행 중인 사건이 없습니다',
            '새로운 사건을 제출해보세요!',
            Icons.how_to_vote,
            widthRatio,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh stream
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16 * widthRatio),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final caseModel = cases[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12 * widthRatio),
                child: CaseCardWidget(
                  caseModel: caseModel,
                  onTap: () => _navigateToCaseDetail(caseModel),
                  onVote: (voteType) => _voteOnCase(caseModel.id, voteType),
                  showVotingButtons: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build queue tab (queued cases)
  Widget _buildQueueTab(double widthRatio) {
    return StreamBuilder<List<CaseModel>>(
      stream: _caseService.getQueuedCases(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString(), widthRatio);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(widthRatio);
        }

        final cases = snapshot.data ?? [];

        if (cases.isEmpty) {
          return _buildEmptyView(
            '대기 중인 사건이 없습니다',
            '법정 승급을 기다리는 사건이 여기에 표시됩니다',
            Icons.queue,
            widthRatio,
          );
        }

        return Column(
          children: [
            // Queue status header
            QueueStatusWidget(),
            
            // Queue list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16 * widthRatio),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final caseModel = cases[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12 * widthRatio),
                    child: CaseCardWidget(
                      caseModel: caseModel,
                      onTap: () => _navigateToCaseDetail(caseModel),
                      showVotingButtons: false,
                      showQueuePosition: true,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Build active court tab (promoted cases)
  Widget _buildActiveCourtTab(double widthRatio) {
    return StreamBuilder<List<CaseModel>>(
      stream: _caseService.getPromotedCases(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString(), widthRatio);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(widthRatio);
        }

        final cases = snapshot.data ?? [];

        if (cases.isEmpty) {
          return _buildEmptyView(
            '진행 중인 법정이 없습니다',
            '사건이 승급되면 여기에 표시됩니다',
            Icons.gavel,
            widthRatio,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16 * widthRatio),
          itemCount: cases.length,
          itemBuilder: (context, index) {
            final caseModel = cases[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12 * widthRatio),
              child: CaseCardWidget(
                caseModel: caseModel,
                onTap: () => _navigateToCourtSession(caseModel),
                showVotingButtons: false,
                showCourtSessionButton: true,
              ),
            );
          },
        );
      },
    );
  }

  // Build completed tab
  Widget _buildCompletedTab(double widthRatio) {
    return StreamBuilder<List<CaseModel>>(
      stream: _caseService.getCompletedCases(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString(), widthRatio);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(widthRatio);
        }

        final cases = snapshot.data ?? [];

        if (cases.isEmpty) {
          return _buildEmptyView(
            '완료된 사건이 없습니다',
            '완료된 법정 세션이 여기에 표시됩니다',
            Icons.history,
            widthRatio,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16 * widthRatio),
          itemCount: cases.length,
          itemBuilder: (context, index) {
            final caseModel = cases[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12 * widthRatio),
              child: CaseCardWidget(
                caseModel: caseModel,
                onTap: () => _navigateToCaseDetail(caseModel),
                showVotingButtons: false,
                showCompletedInfo: true,
              ),
            );
          },
        );
      },
    );
  }

  // Build loading view
  Widget _buildLoadingView(double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
            strokeWidth: 3 * widthRatio,
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            '사건을 불러오는 중...',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              color: const Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  // Build error view
  Widget _buildErrorView(String error, double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: const Color(0xFFE57373),
            size: 64 * widthRatio,
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF424242),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * widthRatio),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32 * widthRatio),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * widthRatio,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          SizedBox(height: 24 * widthRatio),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F37CF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24 * widthRatio,
                vertical: 12 * widthRatio,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
            ),
            child: Text(
              '다시 시도',
              style: TextStyle(
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build empty view
  Widget _buildEmptyView(String title, String subtitle, IconData icon, double widthRatio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFFBDBDBD),
            size: 64 * widthRatio,
          ),
          SizedBox(height: 16 * widthRatio),
          Text(
            title,
            style: TextStyle(
              fontSize: 18 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF424242),
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8 * widthRatio),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32 * widthRatio),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * widthRatio,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToAddCase() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCaseScreen(),
      ),
    );
  }

  void _navigateToCaseDetail(CaseModel caseModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CaseDetailScreen(caseModel: caseModel),
      ),
    );
  }

  void _navigateToCourtSession(CaseModel caseModel) async {
    // Find the court session for this case
    if (caseModel.courtSessionId != null) {
      try {
        final courtSession = await _courtService.getCourtSession(caseModel.courtSessionId!);
        if (mounted && courtSession != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CourtPrototypeScreen(courtSession: courtSession),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load court session: $e')),
          );
        }
      }
    }
  }

  // Vote on case
  Future<void> _voteOnCase(String caseId, CaseVoteType voteType) async {
    try {
      await _caseService.voteOnCase(
        caseId: caseId,
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

  // Show system info dialog
  void _showSystemInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '시스템 정보',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        content: FutureBuilder<Map<String, dynamic>>(
          future: _caseService.getSystemStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final status = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('활성 사건', '${status['activeCases']}개'),
                  _buildInfoRow('대기열', '${status['queuedCases']}개'),
                  _buildInfoRow('활성 법정', '${status['activeCourtSessions']}/${status['maxConcurrentSessions']}개'),
                  _buildInfoRow('완료된 사건', '${status['completedCases']}개'),
                  const SizedBox(height: 16),
                  Text(
                    '• 최소 투표 수: ${CourtSystemConfig.minVotesForPromotion}표\n'
                    '• 승급 조건: ${CourtSystemConfig.controversyRatioMin.toInt()}-${CourtSystemConfig.controversyRatioMax.toInt()}% 범위\n'
                    '• 법정 세션 시간: ${CourtSystemConfig.sessionDurationHours}시간',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              );
            }
            return const CircularProgressIndicator();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFF5F37CF),
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5F37CF),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}