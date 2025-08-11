import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/chat_bubble_view.dart';
// import 'views/vote_appbar_view.dart'; // 이제 selective_transparent_design에서 자체 구현 사용
import 'controllers/chat_controller.dart';
import 'controllers/vote_controller.dart';
import 'models/vote_model.dart';
import 'widgets/keyboard_aware_scaffold.dart';
import 'widgets/png_background.dart';
import 'widgets/selective_transparent_design.dart';

// 앱의 시작점입니다.
void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Stacking Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ChatController()),
          ChangeNotifierProvider(create: (context) => VoteModel()),
          ChangeNotifierProxyProvider<VoteModel, VoteController>(
            create: (context) => VoteController(context.read<VoteModel>()),
            update: (context, voteModel, voteController) => 
                voteController ?? VoteController(voteModel),
          ),
        ],
        child: const BubbleStackScreen(),
      ),
    );
  }
}

// 버블 스택 기능을 보여줄 메인 화면입니다.
class BubbleStackScreen extends StatefulWidget {
  const BubbleStackScreen({super.key});

  @override
  BubbleStackScreenState createState() => BubbleStackScreenState();
}

class BubbleStackScreenState extends State<BubbleStackScreen> {
  final TextEditingController _textController = TextEditingController();

  void _handleSendMessage(ChatController controller) {
    if (_textController.text.isNotEmpty) {
      controller.addMessage(_textController.text, context);
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<ChatController>(
      builder: (context, chatController, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          // 배경만 투명한 AppBar 사용
          appBar: const TransparentBackgroundVoteAppBar(
            title: '실소재판소',
          ),
          extendBodyBehindAppBar: true,
          extendBody: true,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // 전체 화면을 덮는 배경
              Positioned.fill(
                child: SafePngBackground(
                  imageAssetPath: 'assets/background/background.png',
                  fit: BoxFit.cover,
                  enableOverlay: true,
                  overlayColor: Colors.black.withValues(alpha: SelectiveTransparencyController.backgroundOverlayOpacity),
                  child: const SizedBox.expand(),
                ),
              ),
              
              // 메인 콘텐츠 (모든 콘텐츠가 완전히 보이도록)
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    // 메시지 리스트 뷰 (opacity 1.0 - 완전히 보임)
                    MessageListView(
                      messages: chatController.messages,
                      keyboardHeight: keyboardHeight,
                    ),
                    
                    // 경고 및 알림 메시지 (opacity 1.0 - 완전히 보임)
                    Center(
                      child: chatController.isLimitReached
                          ? const LimitReachedWarningView()
                          : chatController.showResetNotice
                              ? const ResetNoticeView()
                              : const SizedBox.shrink(),
                    ),
                    
                    // 배경만 투명한 하단 입력창
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: KeyboardAwarePositioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        minKeyboardPadding: 20.0,
                        child: TransparentBackgroundBottomInput(
                          controller: _textController,
                          participantCount: chatController.participantCount,
                          onSend: () {
                            if (!chatController.isLimitReached) {
                              _handleSendMessage(chatController);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

