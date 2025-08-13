import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';
import '../services/court_service.dart';
import '../models/court_chat_message.dart';
import '../controllers/chat_controller.dart';
import '../widgets/court_chat_input.dart';
import '../widgets/court_chat_message_widget.dart';
import '../widgets/png_background.dart';
import '../widgets/selective_transparent_design.dart';
import '../add_court.dart';

// Court session screen for promoted cases
class CourtSessionScreen extends StatefulWidget {
  final CaseModel caseModel;
  final CourtSessionData? courtSession;

  const CourtSessionScreen({
    super.key,
    required this.caseModel,
    this.courtSession,
  });

  @override
  State<CourtSessionScreen> createState() => _CourtSessionScreenState();
}

class _CourtSessionScreenState extends State<CourtSessionScreen> {
  final CaseService _caseService = CaseService();
  final CourtService _courtService = CourtService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late Stream<List<CourtChatMessage>> _chatMessagesStream;
  CourtSessionData? _currentSession;
  bool _isInitialized = false;
  int _messageCount = 0;
  bool _isSilenced = false;
  DateTime? _silenceTimestamp;
  bool _hasUserSentMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Initialize or find existing court session
  Future<void> _initializeSession() async {
    try {
      if (widget.courtSession != null) {
        _currentSession = widget.courtSession;
      } else if (widget.caseModel.courtSessionId != null) {
        // Find existing session by court session ID
        _currentSession = await _courtService.getCourtSession(widget.caseModel.courtSessionId!);
      }

      if (_currentSession != null) {
        _chatMessagesStream = _courtService.getCourtChatMessages(_currentSession!.id);
        setState(() {
          _isInitialized = true;
        });

        // Show session description popup after build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSessionDescriptionDialog();
        });

        // Auto-join the session
        await _joinSession();
      } else {
        // Session not found or case not promoted yet
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('법정 세션을 찾을 수 없습니다'),
              backgroundColor: Color(0xFFE57373),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('세션 초기화 실패: ${e.toString()}'),
            backgroundColor: const Color(0xFFE57373),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // Join the court session
  Future<void> _joinSession() async {
    if (_currentSession == null) return;

    try {
      await _courtService.joinCourtSession(_currentSession!.id);
    } catch (e) {
      // Joining might fail if already joined, which is okay
      debugPrint('Join session failed (might already be joined): ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
          ),
        ),
      );
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return ChangeNotifierProvider(
      create: (context) => ChatController(),
      child: Consumer<ChatController>(
        builder: (context, chatController, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(),
            extendBodyBehindAppBar: true,
            extendBody: true,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Background that covers entire screen
                Positioned.fill(
                  child: SafePngBackground(
                    imageAssetPath: 'assets/background/background.png',
                    fit: BoxFit.cover,
                    enableOverlay: true,
                    overlayColor: Colors.black.withValues(alpha: SelectiveTransparencyController.backgroundOverlayOpacity),
                    child: const SizedBox.expand(),
                  ),
                ),
                
                // Main content
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Column(
                    children: [
                      // Case information header
                      _buildCaseInfoHeader(),
                      
                      // Chat messages
                      Expanded(
                        child: _buildChatView(keyboardHeight),
                      ),
                      
                      // Chat input
                      SafeArea(
                        child: CourtChatInput(
                          controller: _textController,
                          onSend: (message, messageType) => _sendCourtChatMessage(message, messageType),
                          isEnabled: true,
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
    );
  }

  // Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실소재판소',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
          if (_currentSession != null)
            Text(
              '참여자: ${_currentSession!.currentLiveMembers}명',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                fontFamily: 'Pretendard',
              ),
            ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showSessionDescriptionDialog,
        ),
      ],
    );
  }

  // Build case information header
  Widget _buildCaseInfoHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.caseModel.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Voting results
          Row(
            children: [
              // Guilty side
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '유죄 ${widget.caseModel.guiltyVotes}표 (${widget.caseModel.guiltyPercentage.toInt()}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF424242),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Not guilty side
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '무죄 ${widget.caseModel.notGuiltyVotes}표 (${(100 - widget.caseModel.guiltyPercentage).toInt()}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF424242),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
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
          
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: const Color(0xFFE0E0E0),
            ),
            child: Stack(
              children: [
                if (widget.caseModel.guiltyPercentage > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: (widget.caseModel.guiltyPercentage / 100) * 
                             (MediaQuery.of(context).size.width - 64),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: const Color(0xFFFF4444),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build chat view
  Widget _buildChatView(double keyboardHeight) {
    return StreamBuilder<List<CourtChatMessage>>(
      stream: _chatMessagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.7),
              ),
            ),
          );
        }

        final messages = snapshot.data ?? [];
        
        // Update message count and check for silence trigger
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nonSystemMessages = _isSilenced && _silenceTimestamp != null
              ? messages.where((msg) => msg.messageType != ChatMessageType.system && msg.timestamp.isAfter(_silenceTimestamp!)).toList()
              : messages.where((msg) => msg.messageType != ChatMessageType.system).toList();
          
          final currentCount = nonSystemMessages.length;
          
          // Trigger popup every 5 messages, but only if user has sent a message
          if (currentCount >= 5 && (currentCount ~/ 5) > (_messageCount ~/ 5) && _hasUserSentMessage) {
            _messageCount = currentCount;
            _showSilencePopup();
          } else {
            _messageCount = currentCount;
          }
        });

        // Filter messages based on silence timestamp
        final displayMessages = _isSilenced && _silenceTimestamp != null 
            ? messages.where((msg) => msg.timestamp.isAfter(_silenceTimestamp!)).toList()
            : messages;

        if (displayMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share your thoughts!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: false,
          padding: const EdgeInsets.only(bottom: 160),
          itemCount: displayMessages.length,
          itemBuilder: (context, index) {
            final message = displayMessages[index];
            
            // Auto-scroll when new message is added
            if (index == displayMessages.length - 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            }
            
            return CourtChatMessageWidget(
              message: message,
              onDelete: () => _deleteCourtChatMessage(message.id),
            );
          },
        );
      },
    );
  }

  // Send court chat message
  Future<void> _sendCourtChatMessage(String message, ChatMessageType messageType) async {
    if (_currentSession == null || message.trim().isEmpty) return;
    
    // Mark that user has sent a message (excluding system messages)
    if (messageType != ChatMessageType.system && !_hasUserSentMessage) {
      _hasUserSentMessage = true;
    }
    
    try {
      await _courtService.sendChatMessage(
        courtId: _currentSession!.id,
        message: message.trim(),
        messageType: messageType,
      );
      
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send message: ${e.toString()}',
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

  // Delete court chat message
  Future<void> _deleteCourtChatMessage(String messageId) async {
    if (_currentSession == null) return;
    
    try {
      await _courtService.deleteChatMessage(messageId, _currentSession!.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete message: ${e.toString()}',
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

  // Auto-scroll to bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Show session description dialog
  void _showSessionDescriptionDialog() {
    if (_currentSession == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5F37CF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gavel,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Court Session',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live Discussion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF121212),
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
                widget.caseModel.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121212),
                  fontFamily: 'Pretendard',
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Voting results
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '투표 결과',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '유죄: ${widget.caseModel.guiltyVotes}표 (${widget.caseModel.guiltyPercentage.toInt()}%)\n'
                      '무죄: ${widget.caseModel.notGuiltyVotes}표 (${(100 - widget.caseModel.guiltyPercentage).toInt()}%)\n'
                      '총 투표: ${widget.caseModel.totalVotes}표',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF424242),
                        fontFamily: 'Pretendard',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F37CF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5F37CF).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF5F37CF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'How to participate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5F37CF),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 투표는 이미 완료되었습니다\n'
                      '• 이제 토론을 통해 의견을 나누세요\n'
                      '• 상대방을 존중하며 참여해주세요\n'
                      '• 논리적인 근거를 제시해주세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F37CF),
                        fontFamily: 'Pretendard',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Session info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.people_outline,
                      label: 'Participants',
                      value: '${_currentSession!.currentLiveMembers}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'Time Left',
                      value: _formatTimeLeft(_currentSession!.timeLeft),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
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
                    'Continue Discussion',
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

  // Show silence popup
  void _showSilencePopup() async {
    if (!mounted || _currentSession == null) return;
    
    // Add silence marker to database
    await _sendCourtChatMessage('정숙', ChatMessageType.system);
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gavel icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Silence message
              const Text(
                '정숙!!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                '5 messages reached.\nMessages cleared for order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                  fontFamily: 'Pretendard',
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _silenceTimestamp = DateTime.now();
                      _messageCount = 0;
                      _isSilenced = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
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
      ),
    );
  }

  // Build info item
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // Format time left
  String _formatTimeLeft(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Ending soon';
    }
  }
}