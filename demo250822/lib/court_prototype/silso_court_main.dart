import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/community/community_search_page.dart';
import 'services/court_service.dart';
import 'services/case_service.dart';
import 'models/case_model.dart';
import 'models/court_session_model.dart';
import 'models/ai_conclusion_model.dart';
import 'screens/add_case_screen.dart';
import 'screens/court_main.dart' as court_main;
import 'config/court_config.dart';


// Removed unused _TrialData class since we now use real data

/// Main page widget... (no changes here)
class SilsoCourtPage extends StatefulWidget {
  const SilsoCourtPage({super.key});

  @override
  State<SilsoCourtPage> createState() => _SilsoCourtPageState();
}

// Main page state... (no significant changes here, only in helper widgets)
class _SilsoCourtPageState extends State<SilsoCourtPage>
  with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentPage = 0;

  final CourtService _courtService = CourtService();
  final CaseService _caseService = CaseService();
  
  // Use cached streams to prevent recreation and improve performance
  Stream<List<CourtSessionData>>? _historySessionsStream;
  Stream<List<CourtSessionData>>? _liveSessionsStream;
  Stream<List<CaseModel>>? _queuedCasesStream;
  Stream<List<CaseModel>>? _votingCasesStream;

  // Lazy getters for streams to ensure they're only created once
  Stream<List<CourtSessionData>> get historySessionsStream {
    return _historySessionsStream ??= _courtService.getCompletedCourtSessions();
  }

  Stream<List<CourtSessionData>> get liveSessionsStream {
    return _liveSessionsStream ??= _courtService.getLiveCourtSessions();
  }

  Stream<List<CaseModel>> get queuedCasesStream {
    return _queuedCasesStream ??= _caseService.getQueuedCases();
  }

  Stream<List<CaseModel>> get votingCasesStream {
    return _votingCasesStream ??= _caseService.getActiveVotingCases();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(viewportFraction: 0.65);
    
    // Streams are now lazy-loaded when needed, improving initial load time
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // Added for consistent background
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBannerSection(screenSize),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTabBar(),
                  const SizedBox(height: 24),
                  _buildTabBarView(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddCase(),
        backgroundColor: const Color(0xFF5F37CF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          '사건 제출',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        elevation: 8,
        heroTag: "submit_case_fab",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Column(
              children: [
                Image.asset(
                  "assets/images/community/silso_court.png",
                  width: 70,
                  height: 25,
                ),
                const SizedBox(height: 5),
                const Text(
                  '실시간 재판소',
                  style: TextStyle(
                    color: Color(0xFFC7C7C7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.search, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ExploreSearchPage()),
                );
              },
            ),
          ],
        ),
      ),
      toolbarHeight: 90,
    );
  }

  Widget _buildBannerSection(Size screenSize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSectionHeader(
              title: '실시간 재판소',
              subtitle: 'TOP 3 판결을 확인해 보세요',
            ),
          ),
          const SizedBox(height: 16),
          _buildLiveTrialsList(screenSize),
          const SizedBox(height: 16),
          _buildPageIndicators(),  // Remove hardcoded length
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return StreamBuilder<List<CourtSessionData>>(
      stream: liveSessionsStream,
      builder: (context, snapshot) {
        final sessionCount = snapshot.hasData ? snapshot.data!.length : 0;
        if (sessionCount == 0) return const SizedBox.shrink();
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(sessionCount, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFF6037D0)
                    : const Color(0xFF301D67),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 45,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFFAFAFA),
        unselectedLabelColor: const Color(0xFF6B6B6B),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFFFAFAFA), width: 3.0),
        ),
        labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard'),
        unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard'),
        tabs: const [
          Tab(text: '재판소'),
          Tab(text: '사건'),
          Tab(text: '판결ZIP'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      height: 1200,
      child: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Wrap each tab in KeepAlive to maintain state when switching tabs
          _KeepAliveWrapper(child: _buildCourthouseTab()),
          _KeepAliveWrapper(child: _buildCasesTab()),
          _KeepAliveWrapper(child: _buildVerdictZipTab()),
        ],
      ),
    );
  }

  Widget _buildCourthouseTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // No need to recreate streams - they're already real-time
        // Just provide user feedback that refresh happened
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: const Color(0xFF6037D0),
      backgroundColor: const Color(0xFF1E1E1E),
      child: StreamBuilder<List<CourtSessionData>>(
        stream: liveSessionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6037D0)),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '진행 중인 재판이 없습니다',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '사건이 승급되면 여기에 표시됩니다',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          final liveSessions = snapshot.data!;
          
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: liveSessions.length,
            itemBuilder: (context, index) => _buildCourthouseCard(liveSessions[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          );
        },
      ),
    );
  }

   Widget _buildCasesTab() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              title: '✅ 통과된 사건',
              subtitle: '조금있으면 재판이 시작되는 사건들이에요!',
              isDark: true),
          const SizedBox(height: 16),
          StreamBuilder<List<CaseModel>>(
            stream: queuedCasesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6037D0)),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      '승급된 사건이 없습니다',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                );
              }
              
              final promotedCases = snapshot.data!;
              
              return SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: promotedCases.length,
                  itemBuilder: (context, index) => _buildCaseCarouselCard(promotedCases[index]),
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF6B6B6B), thickness: 2),
          const SizedBox(height: 24),
          _buildSectionHeader(
              title: '배심원 투표',
              subtitle: '재판소에 입장하시기 전에, 판결을 위한 투표에 먼저 참여해 주세요!',
              isDark: true),
          const SizedBox(height: 16),
          StreamBuilder<List<CaseModel>>(
            stream: votingCasesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6037D0)),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.how_to_vote,
                          color: Colors.white.withOpacity(0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '투표 중인 사건이 없습니다',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _navigateToAddCase(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5F37CF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '사건 제출하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final votingCases = snapshot.data!;
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: votingCases.length,
                itemBuilder: (context, index) {
                  final caseModel = votingCases[index];
                  return _buildFolderCard(
                    folderColor: const Color(0xFF4B2CA4),
                    borderColor: const Color(0xFFA38EDC),
                    title: caseModel.title,
                    timeLeft: _formatCaseTimeLeft(caseModel),
                    isCase: true,
                    onTap: () => _showVoteModal(context, caseModel.title, true, caseModel),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 24),
              );
            },
          )
        ],
      ),
    );
  }

   Widget _buildVerdictZipTab() {
    return StreamBuilder<List<CourtSessionData>>(
      stream: historySessionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF6037D0)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '완결된 판결이 없습니다.',
              style: TextStyle(color: Color(0xFFC7C7C7), fontSize: 16),
            ),
          );
        }

        final completedSessions = snapshot.data!;

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  title: '완결된 판결',
                  subtitle: '사람들은 어떤 판결을 내렸을까요?',
                  isDark: true),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedSessions.length,
                itemBuilder: (context, index) {
                  final session = completedSessions[index];

                  String verdictText;
                  switch (session.resultWin) {
                    case 'guilty':
                      verdictText = '반대';
                      break;
                    case 'not_guilty':
                      verdictText = '찬성';
                      break;
                    case 'tie':
                      verdictText = '무승부';
                      break;
                    default:
                      verdictText = '결과 없음';
                  }

                  return _buildFolderCard(
                    folderColor: const Color(0xFF6B6B6B),
                    borderColor: const Color(0xFFFAFAFA),
                    title: session.title,
                    verdict: verdictText,
                    isCase: false,
                    // [#MODIFIED] Pass the correct onTap callback for showing results
                    onTap: () => _showResultModal(context, session, false),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
      {required String title, String? subtitle, bool isDark = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFAFAFA),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFC7C7C7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveTrialsList(Size screenSize) {
    return StreamBuilder<List<CourtSessionData>>(
      stream: liveSessionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 155,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF6037D0)),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 155,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gavel,
                    color: Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '진행 중인 재판이 없습니다',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final liveSessions = snapshot.data!;
        
        return SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _pageController,
            itemCount: liveSessions.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final session = liveSessions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () => _navigateToCourtSession(session),
                  child: _buildTrialCard(
                    imageUrl: "assets/images/community/judge_${(index % 2) + 1}.png",
                    title: session.title,
                    timeLeft: _formatTimeLeft(session.timeLeft),
                    participants: '현재 참여수 ${session.currentLiveMembers}명',
                    isLive: session.isLive,
                    width: screenSize.width,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrialCard({
    required String imageUrl,
    required String title,
    required String timeLeft,
    required String participants,
    required bool isLive,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 121,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 11,
                  top: 12,
                  child: Text(
                    timeLeft,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    right: 11,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC31A1A),
                        borderRadius: BorderRadius.circular(400),
                      ),
                      child: const Text('Live',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                Positioned(
                  right: 11,
                  bottom: 12,
                  child: Text(
                    participants,
                    style: const TextStyle(
                      color: Color(0xFFBBBBBB),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFAFAFA),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourthouseCard(CourtSessionData session) {
    return GestureDetector(
      onTap: () => _navigateToCourtSession(session),
      child: Container(
        height: 101,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.asset(
                      "assets/images/community/judge_1.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (session.isLive)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC31A1A),
                          borderRadius: BorderRadius.circular(400),
                        ),
                        child: const Text('Live',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFFAFAFA),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25)),
                    Text('참여자 ${session.currentLiveMembers}명',
                        style: const TextStyle(
                            color: Color(0xFFC7C7C7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.25)),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF5F37CF)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_formatTimeLeft(session.timeLeft),
                          style: const TextStyle(
                              color: Color(0xFF5F37CF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCarouselCard(CaseModel caseModel) {
    return GestureDetector(
      onTap: () => _navigateToCourtSessionFromCase(caseModel),
      child: SizedBox(
        width: 157,
        height: 159,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 148,
              height: 155,
              decoration: BoxDecoration(
                color: const Color(0xFF6037D0).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(
              width: 145,
              height: 145,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 135,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6037D0),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 8,
                    child: Container(
                      width: 129,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: 25,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      //child: Center(
                        child: Text(
                          caseModel.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFAFAFA),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                 // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [#MODIFIED] This modal is for active cases (the '사건' tab)
  void _showVoteModal(BuildContext context, String title, bool isCase, [CaseModel? caseModel]) {
    if (!isCase || caseModel == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return VoteModal(caseModel: caseModel, caseService: _caseService);
      },
    );
  }
  
  // [#NEW] This modal is for completed cases (the '판결ZIP' tab)
  void _showResultModal(BuildContext context, CourtSessionData courtResult, bool isCase) {
    if (isCase) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        // Show the new VoteResultModal
        return VoteResultModal(courtResult: courtResult);
      },
    );
  }



  Color _getVerdictColor(String? verdict) {
    switch (verdict) {
      case '반대':
        return const Color(0xFFFF3838); // Red for "Cons"
      case '찬성':
        return const Color(0xFF3146E6); // Blue for "Pros"
      default:
        return const Color(0xFFC7C7C7); // Gray for "Tie" or other cases
    }
  }

  Widget _buildFolderCard({
    required Color folderColor,
    required Color borderColor,
    required String title,
    String? timeLeft,
    String? verdict,
    required bool isCase,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, // Use the passed onTap callback
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 8,
              child: Container(
                width: MediaQuery.of(context).size.width - 245,
                height: 115,
                decoration: BoxDecoration(
                  color: isCase
                      ? const Color(0xFF6037D0).withOpacity(0.6)
                      : const Color.fromARGB(255, 107, 107, 107).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              bottom: 5,
              child: Container(
                width: MediaQuery.of(context).size.width - 48,
                height: 122,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width - 32,
                height: 122,
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),
                decoration: BoxDecoration(
                  color: folderColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (isCase && timeLeft != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(timeLeft,
                            style: TextStyle(
                                color: borderColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    if (!isCase && verdict != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: _getVerdictColor(verdict),
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          verdict,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: borderColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

 enum VoteChoice { none, pros, cons }

// This modal is for voting on active cases.
class VoteModal extends StatefulWidget {
  final CaseModel caseModel;
  final CaseService caseService;
  const VoteModal({super.key, required this.caseModel, required this.caseService});

  @override
  State<VoteModal> createState() => _VoteModalState();
}

class _VoteModalState extends State<VoteModal> {
  VoteChoice _voteChoice = VoteChoice.none;
  bool _isVoting = false;
  bool _animationCompleted = false;

  void _handleVote(VoteChoice choice) {
    if (_isVoting) return;
    
    setState(() {
      _isVoting = true;
      _voteChoice = choice; // Set choice immediately for animation
    });

    // Start animation and close modal after animation completes
    _startVotingAnimation(choice);
  }

  void _startVotingAnimation(VoteChoice choice) async {
    // Wait for sliding folder animation to complete
    // AnimatedPositioned: 1000ms + AnimatedOpacity: 600ms + buffer: 200ms
    await Future.delayed(const Duration(milliseconds: 1800));
    
    // Mark animation as complete and show final state briefly
    if (mounted) {
      setState(() {
        _animationCompleted = true;
        _isVoting = false; // Animation completed
      });
      
      // Small delay to show final animation state before closing
      await Future.delayed(const Duration(milliseconds: 400));
      
      if (mounted) {
        Navigator.of(context).pop();
        // Perform vote in background after modal closes
        _performVoteWithErrorHandling(choice);
      }
    }
  }

  Future<void> _performVoteWithErrorHandling(VoteChoice choice) async {
    try {
      await _performVote(choice);
      if (mounted) {
        _handleVoteSuccess(choice);
      }
    } catch (e) {
      if (mounted) {
        _handleVoteError(e);
      }
    }
  }

  Future<void> _performVote(VoteChoice choice) async {
    // Check authentication first, sign in anonymously if needed
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      } catch (authError) {
        throw Exception('AUTH_REQUIRED');
      }
    }
    
    if (user == null) {
      throw Exception('AUTH_REQUIRED');
    }
    
    // Cast the actual vote using CaseService
    final voteType = choice == VoteChoice.pros ? CaseVoteType.notGuilty : CaseVoteType.guilty;
    
    await widget.caseService.voteOnCase(
      caseId: widget.caseModel.id,
      voteType: voteType,
    );

    // Vote succeeded, success will be handled in _performVoteWithErrorHandling
  }

  void _handleVoteSuccess(VoteChoice choice) async {
    // Check if case was promoted after voting
    try {
      final updatedCase = await widget.caseService.getCase(widget.caseModel.id);
      final wasPromoted = updatedCase?.status == CaseStatus.promoted || updatedCase?.status == CaseStatus.qualified;
      
      if (mounted) {
        _showSuccessMessage(choice, wasPromoted);
      }
    } catch (e) {
      // Even if we can't check promotion status, still show success
      if (mounted) {
        _showSuccessMessage(choice, false);
      }
    }
  }

  void _handleVoteError(dynamic error) {
    final errorMessage = _translateError(error);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
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


  // Build button animation for voting process - matches main sliding folder animation
  Widget _buildButtonAnimation(VoteChoice choice) {
    const double buttonWidth = 50.0;
    const double buttonHeight = 35.0;
    const double fileWidth = 42.0;
    const double fileHeight = 28.0;
    
    // Determine if this button's choice matches the selected vote
    final bool isThisChoiceSelected = _voteChoice == choice;
    
    Color fileColor;
    if (isThisChoiceSelected && choice == VoteChoice.pros) {
      fileColor = const Color(0xFF3146E6);
    } else if (isThisChoiceSelected && choice == VoteChoice.cons) {
      fileColor = const Color(0xFFFF3838);
    } else {
      fileColor = Colors.transparent;
    }
    
    final double fileTopPosition = (buttonHeight / 2 - fileHeight / 1.5);
    
    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated file sliding down (similar to main animation)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            top: ((_isVoting || _animationCompleted) && isThisChoiceSelected) ? fileTopPosition : -fileHeight,
            child: Container(
              width: fileWidth * 0.85,
              height: fileHeight * 0.8,
              decoration: ShapeDecoration(
                color: fileColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Folder container (similar to main animation)
          if ((_isVoting || _animationCompleted) && isThisChoiceSelected)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              top: fileTopPosition + 2,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: ((_isVoting || _animationCompleted) && isThisChoiceSelected) ? 0.8 : 0.0,
                child: Container(
                  width: buttonWidth,
                  height: buttonHeight * 0.75,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF4B2CA4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _translateError(dynamic error) {
    String errorMsg = error.toString();
    
    // Remove common error prefixes to get clean error message
    errorMsg = errorMsg
        .replaceFirst('Exception: ', '')
        .replaceFirst('Failed to vote: ', '')
        .replaceFirst(RegExp(r'^Error: .*Use the properties.*'), '투표 처리 중 오류가 발생했습니다');
    
    // Map common error patterns to user-friendly Korean messages
    final errorTranslations = {
      'AUTH_REQUIRED': '로그인이 필요합니다',
      'User not authenticated': '로그인이 필요합니다',
      'already voted': '이미 투표하셨습니다',
      'You have already voted': '이미 투표하셨습니다',
      'Daily voting limit': '일일 투표 제한에 도달했습니다',
      'voting limit reached': '일일 투표 제한에 도달했습니다',
      'not in voting phase': '투표 기간이 아닙니다',
      'Case is not in voting phase': '투표 기간이 아닙니다',
      'expired': '투표 기간이 만료되었습니다',
      'voting period has expired': '투표 기간이 만료되었습니다',
      'permission-denied': '권한이 없습니다',
      'Permission denied': '권한이 없습니다',
      'network': '네트워크 연결을 확인해주세요',
      'timeout': '네트워크 연결을 확인해주세요',
      'Case not found': '사건을 찾을 수 없습니다',
      'Voting is temporarily disabled': '투표가 일시적으로 비활성화되었습니다',
    };
    
    // Find matching error pattern and return translated message
    for (final entry in errorTranslations.entries) {
      if (errorMsg.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Fallback for unknown errors or very long error messages
    if (errorMsg.trim().isEmpty || errorMsg.length > 150) {
      return '투표 처리 중 오류가 발생했습니다';
    }
    
    return errorMsg;
  }


  void _showSuccessMessage(VoteChoice choice, bool wasPromoted) {
    if (wasPromoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '사건이 재판소로 승급되었습니다! 재판소 탭을 확인해보세요.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF6037D0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice == VoteChoice.pros ? '찬성 투표가 완료되었습니다!' : '반대 투표가 완료되었습니다!',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: choice == VoteChoice.pros ? const Color(0xFF3146E6) : const Color(0xFFFF3838),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = screenSize.width * 0.9;
    final modalHeight = screenSize.height * 0.6;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SizedBox(
              width: modalWidth,
              height: modalHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildAnimatedFile(modalHeight, modalWidth,
                      const Color(0xFFFF3838), VoteChoice.cons),
                  _buildAnimatedFile(modalHeight, modalWidth,
                      const Color(0xFF3146E6), VoteChoice.pros),
                  _buildDocumentUi(
                    width: modalWidth, 
                    height: modalHeight,
                    title: widget.caseModel.title,
                    content: Text(
                      widget.caseModel.description.isNotEmpty 
                        ? widget.caseModel.description
                        : '이 사건에 대한 상세 내용이 없습니다.',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                    pageInfo: '1/1'
                  ),
                  _buildSlidingFolderAnimation(modalWidth, modalHeight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: modalWidth * 0.05),
            child: _buildVoteButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFile(
      double mHeight, double mWidth, Color color, VoteChoice choice) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      top: _voteChoice == choice ? 0 : mHeight,
      child: Container(
        width: mWidth,
        height: mHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
  
  Widget _buildVoteButtons() {
    return _buildButtons();
  }

  Widget _buildButtons() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isVoting ? null : () => _handleVote(VoteChoice.cons),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3838).withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: _isVoting
                  ? _buildButtonAnimation(VoteChoice.cons)
                  : const Text('반대', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isVoting ? null : () => _handleVote(VoteChoice.pros),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3146E6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: _isVoting
                  ? _buildButtonAnimation(VoteChoice.pros)
                  : const Text('찬성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingFolderAnimation(double modalWidth, double modalHeight) {
    const double folderWidth = 214.0;
    const double folderHeight = 166.0;

    // Determine file color based on vote choice
    Color fileColor;
    if (_voteChoice == VoteChoice.pros) {
      fileColor = const Color(0xFF3146E6);
    } else if (_voteChoice == VoteChoice.cons) {
      fileColor = const Color(0xFFFF3838);
    } else {
      fileColor = Colors.transparent;
    }

    final double folderTopPosition = (modalHeight / 2 - folderHeight / 1.5);
    
    // Show animation when voting is in progress or just completed
    final bool shouldShowAnimation = (_isVoting || _animationCompleted) && _voteChoice != VoteChoice.none;

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated colored file sliding down
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            top: shouldShowAnimation ? folderTopPosition : -folderHeight,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: shouldShowAnimation ? 1.0 : 0.0,
              child: SizedBox(
                width: folderWidth,
                height: folderHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 23.46,
                      child: Container(
                        width: 190.57,
                        height: 129.73,
                        decoration: ShapeDecoration(
                          color: fileColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.93)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Folder container that appears when vote is in progress
          if (shouldShowAnimation)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              top: folderTopPosition,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: shouldShowAnimation ? 1.0 : 0.0,
                child: SizedBox(
                  width: folderWidth,
                  height: folderHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        top: 32.98,
                        child: Container(
                          width: 214.02,
                          height: 145.13,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF4B2CA4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.86)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// [#NEW] This is the new modal for showing results from the '판결ZIP' tab
class VoteResultModal extends StatefulWidget {
  final CourtSessionData courtResult;
  const VoteResultModal({super.key, required this.courtResult});

  @override
  State<VoteResultModal> createState() => _VoteResultModalState();
}

class _VoteResultModalState extends State<VoteResultModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = screenSize.width * 0.9;
    final modalHeight = screenSize.height * 0.65;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: modalWidth,
            height: modalHeight,
            child: PageView(
              controller: _pageController,
              children: [
                _buildResultDocumentPage(modalWidth, modalHeight),
                _buildAiVerdictPage(modalWidth, modalHeight),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPageIndicators(),
        ],
      ),
    );
  }

  // First page: Shows the case description and vote results
  Widget _buildResultDocumentPage(double modalWidth, double modalHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _buildDocumentUi(
            width: modalWidth,
            height: modalHeight,
            title: widget.courtResult.title,
            content: Text(
              widget.courtResult.description.isNotEmpty 
                ? widget.courtResult.description
                : "이 사건에 대한 상세 내용이 없습니다.",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
            pageInfo: '1/2'
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: modalWidth * 0.05),
          child: _buildVoteResultBar(widget.courtResult),
        ),
      ],
    );
  }

  // Second page: AI-generated final verdict using Gemini
  Widget _buildAiVerdictPage(double modalWidth, double modalHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _buildDocumentUi(
            width: modalWidth,
            height: modalHeight,
            title: '🤖 AI 최종 판결문',
            content: FutureBuilder<AiConclusionModel?>(
              future: CaseService().getAiConclusion(widget.courtResult.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF6037D0)),
                      SizedBox(height: 16),
                      Text(
                        "AI가 판결문을 생성하고 있습니다...",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }
                
                if (snapshot.hasError) {
                  return Text(
                    "판결문 생성 중 오류가 발생했습니다: ${snapshot.error}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                
                final aiConclusion = snapshot.data;
                if (aiConclusion == null) {
                  return const Text(
                    "아직 AI 판결문이 생성되지 않았습니다.\n\n법정이 종료된 후 잠시 후에 다시 확인해주세요.",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  );
                }
                
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Verdict Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: aiConclusion.finalVerdict == 'GUILTY' 
                              ? const Color(0xFFFF3838) 
                              : const Color(0xFF3146E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${aiConclusion.finalVerdict} (신뢰도: ${aiConclusion.metadata['confidence_score']}%)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // AI Generated Summary
                      Text(
                        aiConclusion.summary,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // AI Model Info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology, size: 16, color: Color(0xFF6037D0)),
                            const SizedBox(width: 8),
                            Text(
                              '${aiConclusion.metadata['ai_model']} • ${aiConclusion.metadata['processing_time_ms']}ms',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            pageInfo: '2/2'
          ),
        ),
        const SizedBox(height: 64), // Match height of result bar area
      ],
    );
  }

  // Page indicator dots
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        );
      }),
    );
  }

  // Vote result bar inspired by court_history.dart
  Widget _buildVoteResultBar(CourtSessionData session) {
    final guiltyVotes = session.guiltyVotes;
    final notGuiltyVotes = session.notGuiltyVotes;
    final totalVotes = guiltyVotes + notGuiltyVotes;
    final guiltyRatio = totalVotes > 0 ? guiltyVotes / totalVotes : 0.5;

    return Column(
      children: [
        Container(
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Background (not guilty - blue)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3146E6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              // Guilty section (red)
              if (totalVotes > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: guiltyRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3838),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              // Vote count labels
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$guiltyVotes',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
                      Text(
                        '$notGuiltyVotes',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text('반대', style: TextStyle(color: Color(0xFFFF3838), fontWeight: FontWeight.bold)),
               Text('찬성', style: TextStyle(color: Color(0xFF3146E6), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}


// --- GENERIC WIDGETS AND PAINTERS (SHARED) ---

// [#MODIFIED] The document UI is now a shared helper widget
Widget _buildDocumentUi({
  required double width,
  required double height,
  required String title,
  required Widget content,
  String pageInfo = '1/1',
}) {
    const double borderWidth = 12.0;
    const double foldSize = 50.0;

    Widget buildBorder(Widget child) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF79673F)),
          CustomPaint(
            painter: _PixelPatternPainter(
              dotColor: Colors.black.withOpacity(0.1),
              step: 3.0,
            ),
            child: Container(),
          ),
          child,
        ],
      );
    }

    return Stack(
      children: [
        Container(color: const Color(0xFFF2E3BC)),
        CustomPaint(
          size: Size(width, height),
          painter: _PixelPatternPainter(
            dotColor: Colors.black.withOpacity(0.05),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          width: foldSize,
          height: foldSize,
          child: ClipPath(
            clipper: _FoldedCornerClipper(),
            child: Container(color: const Color(0xFFD4C0A1)),
          ),
        ),
        Positioned(
          left: 0, top: 0, bottom: 0,
          child: SizedBox(width: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Positioned(
          right: 0, top: 0, bottom: 0,
          child: SizedBox(width: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Positioned(
          left: 0, top: 0, right: 0,
          child: SizedBox(height: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Positioned(
          left:  0, bottom: 0, right: 0,
          child: SizedBox(height: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Padding(
          padding: const EdgeInsets.all(borderWidth + 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(title, pageInfo),
              const SizedBox(height: 15),
              Container(width: double.infinity, height: 1, color: const Color(0xFFE0C898)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
Widget _buildHeader(String title, String pageInfo) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40), // Spacer for centering title
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF5E4E2C), fontSize: 24, fontFamily: 'Pretendard', fontWeight: FontWeight.w700)
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(pageInfo, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFFA68A54), fontSize: 16, fontFamily: 'Pretendard', fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _PixelPatternPainter extends CustomPainter {
  final Color dotColor;
  final double step;
  _PixelPatternPainter({required this.dotColor, this.step = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FoldedCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// === NAVIGATION HELPERS ===
extension on _SilsoCourtPageState {
  // Navigate to court session screen
  void _navigateToCourtSession(CourtSessionData session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => court_main.CourtPrototypeScreen(courtSession: session),
      ),
    );
  }

  // Navigate to court session from case model
  void _navigateToCourtSessionFromCase(CaseModel caseModel) {
    if (caseModel.courtSessionId != null) {
      // Find the court session and navigate
      _courtService.getCourtSession(caseModel.courtSessionId!).then((session) {
        if (session != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => court_main.CourtPrototypeScreen(courtSession: session),
            ),
          );
        }
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('법정 세션을 찾을 수 없습니다: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  // Navigate to add case screen
  void _navigateToAddCase() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCaseScreen(),
      ),
    );
  }

  // Format time left for display
  String _formatTimeLeft(Duration duration) {
    if (duration.inHours > 0) {
      return '판결까지 ${duration.inHours}시간 남음';
    } else if (duration.inMinutes > 0) {
      return '판결까지 ${duration.inMinutes}분 남음';
    } else {
      return '곧 종료';
    }
  }

  // Format case time left
  String _formatCaseTimeLeft(CaseModel caseModel) {
    final now = DateTime.now();
    final expiresAt = caseModel.expiresAt;
    if (expiresAt == null) {
      return '시간 정보 없음';
    }
    
    final timeLeft = expiresAt.difference(now);
    
    if (timeLeft.inHours > 0) {
      return '투표 종료까지 ${timeLeft.inHours}시간 남음';
    } else if (timeLeft.inMinutes > 0) {
      return '투표 종료까지 ${timeLeft.inMinutes}분 남음';
    } else {
      return '투표 곧 종료';
    }
  }
}

// Wrapper to keep TabBarView children alive for better performance
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const _KeepAliveWrapper({required this.child});
  
  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}