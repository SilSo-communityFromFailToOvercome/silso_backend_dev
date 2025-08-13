import 'package:flutter/material.dart';
import '../services/test_data_service.dart';
import '../config/court_config.dart';

// Admin controls screen for testing and system management
class AdminControlsScreen extends StatefulWidget {
  const AdminControlsScreen({super.key});

  @override
  State<AdminControlsScreen> createState() => _AdminControlsScreenState();
}

class _AdminControlsScreenState extends State<AdminControlsScreen> {
  final TestDataService _testDataService = TestDataService();
  final TextEditingController _caseIdController = TextEditingController();
  final TextEditingController _guiltyVotesController = TextEditingController();
  final TextEditingController _notGuiltyVotesController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _systemStats;
  Map<String, dynamic>? _testStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    _guiltyVotesController.dispose();
    _notGuiltyVotesController.dispose();
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
          '관리자 도구',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: const Color(0xFF5F37CF),
              size: 24 * widthRatio,
            ),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            _buildWarningBanner(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // System status
            _buildSystemStatusCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // Test data generation
            _buildTestDataCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // Vote manipulation
            _buildVoteManipulationCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // System controls
            _buildSystemControlsCard(widthRatio),
            
            SizedBox(height: 16 * widthRatio),
            
            // Configuration info
            _buildConfigurationCard(widthRatio),
          ],
        ),
      ),
    );
  }

  // Build warning banner
  Widget _buildWarningBanner(double widthRatio) {
    return Container(
      padding: EdgeInsets.all(16 * widthRatio),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12 * widthRatio),
        border: Border.all(
          color: const Color(0xFFFF9800),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: const Color(0xFFFF9800),
            size: 24 * widthRatio,
          ),
          SizedBox(width: 12 * widthRatio),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ 관리자 도구',
                  style: TextStyle(
                    fontSize: 16 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9800),
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 4 * widthRatio),
                Text(
                  '이 도구는 테스트 목적으로만 사용하세요. 프로덕션 환경에서는 사용하지 마세요.',
                  style: TextStyle(
                    fontSize: 12 * widthRatio,
                    color: const Color(0xFFFF9800),
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

  // Build system status card
  Widget _buildSystemStatusCard(double widthRatio) {
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
                Icon(
                  Icons.dashboard,
                  color: const Color(0xFF5F37CF),
                  size: 20 * widthRatio,
                ),
                SizedBox(width: 8 * widthRatio),
                Text(
                  '시스템 상태',
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
            
            if (_systemStats != null) ...[
              _buildStatRow('활성 사건', '${_systemStats!['activeCases']}개', widthRatio),
              _buildStatRow('대기열', '${_systemStats!['queuedCases']}개', widthRatio),
              _buildStatRow('활성 법정', '${_systemStats!['activeCourtSessions']}/${_systemStats!['maxConcurrentSessions']}개', widthRatio),
              _buildStatRow('완료된 사건', '${_systemStats!['completedCases']}개', widthRatio),
            ] else
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
                ),
              ),
            
            SizedBox(height: 12 * widthRatio),
            
            if (_testStats != null) ...[
              Container(
                padding: EdgeInsets.all(12 * widthRatio),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8 * widthRatio),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테스트 데이터',
                      style: TextStyle(
                        fontSize: 12 * widthRatio,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 4 * widthRatio),
                    Text(
                      '사건: ${_testStats!['testCases']}개 • 투표: ${_testStats!['testVotes']}개 • 법정: ${_testStats!['testCourtSessions']}개',
                      style: TextStyle(
                        fontSize: 11 * widthRatio,
                        color: const Color(0xFF8E8E8E),
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

  // Build test data generation card
  Widget _buildTestDataCard(double widthRatio) {
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
                Icon(
                  Icons.data_usage,
                  color: const Color(0xFF4CAF50),
                  size: 20 * widthRatio,
                ),
                SizedBox(width: 8 * widthRatio),
                Text(
                  '테스트 데이터',
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
            
            Text(
              '다양한 상태의 테스트 사건들을 생성하여 시스템을 테스트할 수 있습니다.',
              style: TextStyle(
                fontSize: 14 * widthRatio,
                color: const Color(0xFF424242),
                fontFamily: 'Pretendard',
              ),
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateTestData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12 * widthRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * widthRatio),
                      ),
                    ),
                    icon: Icon(Icons.add_box, size: 16 * widthRatio),
                    label: Text(
                      '테스트 데이터 생성',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 8 * widthRatio),
                
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _clearTestData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE57373),
                      side: const BorderSide(color: Color(0xFFE57373)),
                      padding: EdgeInsets.symmetric(vertical: 12 * widthRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * widthRatio),
                      ),
                    ),
                    icon: Icon(Icons.delete_sweep, size: 16 * widthRatio),
                    label: Text(
                      '테스트 데이터 삭제',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build vote manipulation card
  Widget _buildVoteManipulationCard(double widthRatio) {
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
                Icon(
                  Icons.how_to_vote,
                  color: const Color(0xFF2196F3),
                  size: 20 * widthRatio,
                ),
                SizedBox(width: 8 * widthRatio),
                Text(
                  '투표 조작',
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
            
            // Case ID input
            TextFormField(
              controller: _caseIdController,
              decoration: InputDecoration(
                labelText: '사건 ID',
                hintText: '투표를 추가할 사건의 ID를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8 * widthRatio),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12 * widthRatio,
                  vertical: 12 * widthRatio,
                ),
              ),
              style: TextStyle(
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
              ),
            ),
            
            SizedBox(height: 12 * widthRatio),
            
            // Vote inputs
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _guiltyVotesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '유죄 투표',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8 * widthRatio),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12 * widthRatio,
                        vertical: 12 * widthRatio,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                
                SizedBox(width: 12 * widthRatio),
                
                Expanded(
                  child: TextFormField(
                    controller: _notGuiltyVotesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '무죄 투표',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8 * widthRatio),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12 * widthRatio,
                        vertical: 12 * widthRatio,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16 * widthRatio),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addVotes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12 * widthRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * widthRatio),
                      ),
                    ),
                    child: Text(
                      '투표 추가',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 8 * widthRatio),
                
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _forcePromoteCase,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9C27B0),
                      side: const BorderSide(color: Color(0xFF9C27B0)),
                      padding: EdgeInsets.symmetric(vertical: 12 * widthRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * widthRatio),
                      ),
                    ),
                    child: Text(
                      '강제 승급',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build system controls card
  Widget _buildSystemControlsCard(double widthRatio) {
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
                Icon(
                  Icons.settings,
                  color: const Color(0xFF9C27B0),
                  size: 20 * widthRatio,
                ),
                SizedBox(width: 8 * widthRatio),
                Text(
                  '시스템 제어',
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
            
            // Testing mode toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    '테스트 모드',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Switch(
                  value: CourtSystemConfig.isTestingMode,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _testDataService.enableTestingMode();
                      } else {
                        _testDataService.disableTestingMode();
                      }
                    });
                  },
                  activeColor: const Color(0xFF4CAF50),
                ),
              ],
            ),
            
            // Maintenance mode toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    '유지보수 모드',
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Switch(
                  value: CourtSystemConfig.systemMaintenanceMode,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _testDataService.enableMaintenanceMode();
                      } else {
                        _testDataService.disableMaintenanceMode();
                      }
                    });
                  },
                  activeColor: const Color(0xFFFF9800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build configuration card
  Widget _buildConfigurationCard(double widthRatio) {
    final debugInfo = _testDataService.getSystemDebugInfo();
    
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
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF607D8B),
                  size: 20 * widthRatio,
                ),
                SizedBox(width: 8 * widthRatio),
                Text(
                  '설정 정보',
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
            
            Container(
              padding: EdgeInsets.all(12 * widthRatio),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 설정',
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424242),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 8 * widthRatio),
                  ...debugInfo.entries.map((entry) => Padding(
                    padding: EdgeInsets.only(bottom: 4 * widthRatio),
                    child: Row(
                      children: [
                        Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontSize: 11 * widthRatio,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(width: 8 * widthRatio),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 11 * widthRatio,
                              color: const Color(0xFF424242),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildStatRow(String label, String value, double widthRatio) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * widthRatio),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              color: const Color(0xFF424242),
              fontFamily: 'Pretendard',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5F37CF),
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load system stats (placeholder - would use CaseService)
      _systemStats = {
        'activeCases': 12,
        'queuedCases': 3,
        'activeCourtSessions': 2,
        'maxConcurrentSessions': 8,
        'completedCases': 45,
      };

      // Load test data stats
      _testStats = await _testDataService.getTestDataStats();
    } catch (e) {
      _showErrorSnackBar('Failed to load stats: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateTestData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final caseIds = await _testDataService.generateTestCases();
      _showSuccessSnackBar('Generated ${caseIds.length} test cases');
      await _loadStats();
    } catch (e) {
      _showErrorSnackBar('Failed to generate test data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearTestData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테스트 데이터 삭제'),
        content: const Text('모든 테스트 데이터가 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _testDataService.clearAllTestData();
      _showSuccessSnackBar('All test data cleared');
      await _loadStats();
    } catch (e) {
      _showErrorSnackBar('Failed to clear test data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addVotes() async {
    final caseId = _caseIdController.text.trim();
    final guiltyVotes = int.tryParse(_guiltyVotesController.text) ?? 0;
    final notGuiltyVotes = int.tryParse(_notGuiltyVotesController.text) ?? 0;

    if (caseId.isEmpty) {
      _showErrorSnackBar('Please enter a case ID');
      return;
    }

    if (guiltyVotes <= 0 && notGuiltyVotes <= 0) {
      _showErrorSnackBar('Please enter at least one vote');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _testDataService.addVotesToCase(
        caseId: caseId,
        guiltyVotes: guiltyVotes,
        notGuiltyVotes: notGuiltyVotes,
      );
      _showSuccessSnackBar('Added $guiltyVotes guilty and $notGuiltyVotes not guilty votes');
      
      // Clear form
      _guiltyVotesController.clear();
      _notGuiltyVotesController.clear();
      
      await _loadStats();
    } catch (e) {
      _showErrorSnackBar('Failed to add votes: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _forcePromoteCase() async {
    final caseId = _caseIdController.text.trim();

    if (caseId.isEmpty) {
      _showErrorSnackBar('Please enter a case ID');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _testDataService.forcePromoteCase(caseId);
      _showSuccessSnackBar('Case promoted to court session');
      await _loadStats();
    } catch (e) {
      _showErrorSnackBar('Failed to promote case: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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