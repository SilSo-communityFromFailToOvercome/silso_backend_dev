import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:judge/models/vote_model.dart';
import 'package:judge/controllers/vote_controller.dart';
import 'package:judge/views/vote_appbar_view.dart';

void main() {
  group('Vote functionality tests', () {
    testWidgets('VoteModel basic functionality test', (WidgetTester tester) async {
      final voteModel = VoteModel();
      
      // Initial state
      expect(voteModel.agreeCount, 0);
      expect(voteModel.disagreeCount, 0);
      expect(voteModel.agreeRatio, 0.5);
      expect(voteModel.totalVotes, 0);

      // Add agree vote
      voteModel.addVote(true);
      expect(voteModel.agreeCount, 1);
      expect(voteModel.disagreeCount, 0);
      expect(voteModel.agreeRatio, 1.0);

      // Add disagree vote
      voteModel.addVote(false);
      expect(voteModel.agreeCount, 1);
      expect(voteModel.disagreeCount, 1);
      expect(voteModel.agreeRatio, 0.5);

      // Reset votes
      voteModel.resetVotes();
      expect(voteModel.agreeCount, 0);
      expect(voteModel.disagreeCount, 0);
    });

    testWidgets('VoteController functionality test', (WidgetTester tester) async {
      final voteModel = VoteModel();
      final voteController = VoteController(voteModel);
      
      // Initial state
      expect(voteController.isVotingActive, true);
      expect(voteController.totalVotes, 0);
      expect(voteController.agreePercentage, 50);

      // Add votes through controller
      voteController.addVote(true);
      voteController.addVote(true);
      voteController.addVote(false);

      expect(voteController.totalVotes, 3);
      expect(voteController.agreePercentage, 67);

      // Test statistics
      final stats = voteController.getVoteStatistics();
      expect(stats['totalVotes'], 3);
      expect(stats['agreeCount'], 2);
      expect(stats['disagreeCount'], 1);

      voteController.dispose();
    });

    testWidgets('VoteAppBarView UI test', (WidgetTester tester) async {
      final voteModel = VoteModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: voteModel,
            child: const Scaffold(
              appBar: VoteAppBarView(title: 'Test Vote'),
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Test Vote'), findsOneWidget);
      
      // Verify vote buttons exist
      expect(find.text('찬성'), findsOneWidget);
      expect(find.text('반대'), findsOneWidget);

      // Verify quit icon exists
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Test vote interaction
      await tester.tap(find.text('찬성'));
      await tester.pumpAndSettle();
      
      expect(voteModel.agreeCount, 1);

      await tester.tap(find.text('반대'));
      await tester.pumpAndSettle();
      
      expect(voteModel.disagreeCount, 1);
    });

    testWidgets('Vote control row test', (WidgetTester tester) async {
      final voteModel = VoteModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: voteModel,
            child: Scaffold(
              body: VoteControlRowWidget(voteModel: voteModel, title: 'Test Title'),
            ),
          ),
        ),
      );

      // Verify title is displayed
      expect(find.text('Test Title'), findsOneWidget);
      
      // Verify buttons exist
      expect(find.text('찬성'), findsOneWidget);
      expect(find.text('반대'), findsOneWidget);

      // Test vote functionality
      await tester.tap(find.text('찬성'));
      await tester.pumpAndSettle();
      expect(voteModel.agreeCount, 1);

      await tester.tap(find.text('반대'));
      await tester.pumpAndSettle();
      expect(voteModel.disagreeCount, 1);
    });

    testWidgets('Vote summary widget test', (WidgetTester tester) async {
      final voteModel = VoteModel();
      voteModel.setVotes(15, 5); // 75% agree
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteSummaryWidget(voteModel: voteModel),
          ),
        ),
      );

      expect(find.text('총 투표수: 20'), findsOneWidget);
      expect(find.text('찬성률: 75%'), findsOneWidget);
    });
  });
}