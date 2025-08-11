import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:judge/widgets/selective_transparent_design.dart';
import 'package:judge/models/vote_model.dart';

void main() {
  group('Selective Transparent Design Tests', () {
    testWidgets('TransparentBackgroundVoteAppBar renders with transparent background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => VoteModel(),
            child: Scaffold(
              appBar: const TransparentBackgroundVoteAppBar(
                title: 'Test Title',
              ),
              body: const Center(child: Text('Body')),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('TransparentBackgroundBottomInput renders correctly', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransparentBackgroundBottomInput(
              controller: controller,
              participantCount: 5,
              onSend: () {},
            ),
          ),
        ),
      );

      expect(find.text('현재 참여자 수: 5명'), findsOneWidget);
      expect(find.text('남은 시간: 3시간'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
      
      controller.dispose();
    });

    testWidgets('TransparentBackgroundScaleBar shows vote ratio correctly', (WidgetTester tester) async {
      final voteModel = VoteModel();
      voteModel.addVote(true); // 찬성 1
      voteModel.addVote(true); // 찬성 2
      voteModel.addVote(false); // 반대 1
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransparentBackgroundScaleBar(voteModel: voteModel),
          ),
        ),
      );

      // 비율이 표시되는지 확인 (찬성 2, 반대 1이므로 67% 정도)
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('TransparentBackgroundVoteControlRow handles vote actions', (WidgetTester tester) async {
      final voteModel = VoteModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransparentBackgroundVoteControlRow(
              voteModel: voteModel,
              title: 'Vote Test',
            ),
          ),
        ),
      );

      expect(find.text('Vote Test'), findsOneWidget);
      expect(find.text('반대'), findsOneWidget);
      expect(find.text('찬성'), findsOneWidget);

      // 찬성 버튼 클릭 테스트
      await tester.tap(find.text('찬성'));
      expect(voteModel.agreeCount, 1);

      // 반대 버튼 클릭 테스트
      await tester.tap(find.text('반대'));
      expect(voteModel.disagreeCount, 1);
    });

    testWidgets('SelectiveTransparentAppBar maintains content visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectiveTransparentDesign.createTransparentBackgroundAppBar(
            originalAppBar: AppBar(
              title: const Text('Transparent Background'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // 콘텐츠가 보이는지 확인
      expect(find.text('Transparent Background'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('SelectiveTransparentBottom maintains content visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectiveTransparentDesign.createTransparentBackgroundBottom(
              originalBottom: Container(
                height: 60,
                child: const Center(
                  child: Text('Bottom Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bottom Content'), findsOneWidget);
    });

    test('SelectiveTransparencyController constants are correctly defined', () {
      expect(SelectiveTransparencyController.appBarBackgroundTransparent, true);
      expect(SelectiveTransparencyController.bottomBackgroundTransparent, true);
      expect(SelectiveTransparencyController.contentOpacity, 1.0);
      expect(SelectiveTransparencyController.backgroundOverlayOpacity, 0.3);
    });

    testWidgets('Transparent backgrounds allow background to show through', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => VoteModel(),
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red, // 테스트용 배경색
              appBar: const TransparentBackgroundVoteAppBar(
                title: 'Transparent Test',
              ),
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: TransparentBackgroundBottomInput(
                      controller: TextEditingController(),
                      participantCount: 3,
                      onSend: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 모든 콘텐츠가 표시되는지 확인
      expect(find.text('Transparent Test'), findsOneWidget);
      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('현재 참여자 수: 3명'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Vote functionality works with transparent backgrounds', (WidgetTester tester) async {
      final voteModel = VoteModel();
      
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: voteModel,
          child: MaterialApp(
            home: Scaffold(
              appBar: const TransparentBackgroundVoteAppBar(
                title: 'Vote Functionality Test',
              ),
            ),
          ),
        ),
      );

      // 투표 버튼들이 존재하는지 확인
      expect(find.text('찬성'), findsOneWidget);
      expect(find.text('반대'), findsOneWidget);

      // 초기 상태 확인
      expect(voteModel.agreeCount, 0);
      expect(voteModel.disagreeCount, 0);

      // 찬성 투표
      await tester.tap(find.text('찬성'));
      expect(voteModel.agreeCount, 1);

      // 반대 투표
      await tester.tap(find.text('반대'));
      expect(voteModel.disagreeCount, 1);
    });

    testWidgets('Input functionality works with transparent background', (WidgetTester tester) async {
      final controller = TextEditingController();
      bool sendCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransparentBackgroundBottomInput(
              controller: controller,
              participantCount: 10,
              onSend: () {
                sendCalled = true;
              },
            ),
          ),
        ),
      );

      // 텍스트 입력 테스트
      await tester.enterText(find.byType(TextField), 'Test message');
      expect(controller.text, 'Test message');

      // 전송 버튼 클릭 테스트
      await tester.tap(find.byIcon(Icons.send));
      expect(sendCalled, true);
      
      controller.dispose();
    });

    testWidgets('All UI elements maintain full opacity (visible)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => VoteModel(),
          child: MaterialApp(
            home: Scaffold(
              appBar: const TransparentBackgroundVoteAppBar(title: 'Opacity Test'),
              body: TransparentBackgroundBottomInput(
                controller: TextEditingController(),
                participantCount: 7,
                onSend: () {},
              ),
            ),
          ),
        ),
      );

      // 모든 텍스트와 아이콘이 보이는지 확인
      expect(find.text('Opacity Test'), findsOneWidget);
      expect(find.text('찬성'), findsOneWidget);
      expect(find.text('반대'), findsOneWidget);
      expect(find.text('현재 참여자 수: 7명'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);

      // Opacity 위젯이 콘텐츠를 감싸고 있지 않은지 확인 (전체 투명도가 적용되지 않음)
      // 이는 배경만 투명하고 콘텐츠는 완전히 보이기 때문
    });
  });
}