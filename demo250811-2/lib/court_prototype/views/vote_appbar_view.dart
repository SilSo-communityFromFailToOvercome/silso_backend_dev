import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vote_model.dart';

// Main Vote AppBar widget - 3 Row composition
class VoteAppBarView extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onQuitPressed;

  const VoteAppBarView({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onQuitPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(180.0); // Increased height for 3 rows

  @override
  Widget build(BuildContext context) {
    return Consumer<VoteModel>(
      builder: (context, voteModel, child) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF3F3329),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 1st Row: Quit Icon (right aligned)
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: onQuitPressed ?? () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // 2nd Row: Dynamic Scale Bar
                DynamicScaleBarWidget(voteModel: voteModel),
                // 3rd Row: 반대 Button / Title / 찬성 Button
                VoteControlRowWidget(voteModel: voteModel, title: title),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 2nd Row: Dynamic Scale Bar Widget
class DynamicScaleBarWidget extends StatelessWidget {
  final VoteModel voteModel;

  const DynamicScaleBarWidget({
    super.key,
    required this.voteModel,
  });

  @override
  Widget build(BuildContext context) {
    final agreeRatio = voteModel.agreeRatio;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Stack(
          children: [
            // Background (oppose color)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            // Agree section (dynamically changing area)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: (screenWidth - 32) * agreeRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            // Center indicator (current ratio display)
            Positioned(
              left: (screenWidth - 32) * agreeRatio - 20,
              top: -8,
              child: Container(
                width: 40,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    '${(agreeRatio * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF3F3329),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3rd Row: Vote Control Row Widget (반대 / Title / 찬성)
class VoteControlRowWidget extends StatelessWidget {
  final VoteModel voteModel;
  final String title;

  const VoteControlRowWidget({
    super.key,
    required this.voteModel,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Oppose button
          GestureDetector(
            onTap: () => voteModel.addVote(false),
            child: Container(
              width: 80,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF44336),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '반대',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Center title area
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Agree button
          GestureDetector(
            onTap: () => voteModel.addVote(true),
            child: Container(
              width: 80,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '찬성',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Vote result summary widget (optional)
class VoteSummaryWidget extends StatelessWidget {
  final VoteModel voteModel;

  const VoteSummaryWidget({
    super.key,
    required this.voteModel,
  });

  @override
  Widget build(BuildContext context) {
    final totalVotes = voteModel.agreeCount + voteModel.disagreeCount;
    final agreePercentage = (voteModel.agreeRatio * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '총 투표수: $totalVotes',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            '찬성률: $agreePercentage%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: agreePercentage >= 50 
                  ? const Color(0xFF4CAF50) 
                  : const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}