import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../models/community_model.dart';
import 'community_detail_screen.dart';
import 'search_communities_screen.dart';

class RecommendedCommunitiesScreen extends StatefulWidget {
  const RecommendedCommunitiesScreen({super.key});

  @override
  State<RecommendedCommunitiesScreen> createState() => _RecommendedCommunitiesScreenState();
}

class _RecommendedCommunitiesScreenState extends State<RecommendedCommunitiesScreen> {
  final CommunityService _communityService = CommunityService();
  List<Community> _recommendedCommunities = [];
  List<String> _userInterests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedCommunities();
  }

  Future<void> _loadRecommendedCommunities() async {
    try {
      // Load user interests first
      final interests = await _communityService.getUserInterests();
      
      // Load recommended communities based on user interests
      final recommendations = await _communityService.getRecommendedCommunities();
      
      if (mounted) {
        setState(() {
          _userInterests = interests;
          _recommendedCommunities = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recommendations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshRecommendations() async {
    setState(() => _isLoading = true);
    await _loadRecommendedCommunities();
  }

  int _calculateRelevanceScore(Community community) {
    if (_userInterests.isEmpty) return 0;
    
    int matchingTags = 0;
    for (String hashtag in community.hashtags) {
      for (String interest in _userInterests) {
        if (hashtag.toLowerCase().contains(interest.toLowerCase()) ||
            interest.toLowerCase().contains(hashtag.toLowerCase())) {
          matchingTags++;
        }
      }
    }
    return matchingTags;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Recommended for You',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchCommunitiesScreen(),
                ),
              );
            },
            tooltip: 'Search Communities',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshRecommendations,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // User Interests Header
            if (_userInterests.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Interests',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Based on your selected categories',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _userInterests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getInterestDisplayName(interest),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.recommend,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recommended Communities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Recommendations List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                      ),
                    )
                  : _recommendedCommunities.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshRecommendations,
                          color: const Color(0xFF6C5CE7),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _recommendedCommunities.length,
                            itemBuilder: (context, index) {
                              final community = _recommendedCommunities[index];
                              final relevanceScore = _calculateRelevanceScore(community);
                              return _buildRecommendedCommunityCard(community, relevanceScore, index + 1);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.recommend_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile setup to get personalized recommendations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCommunityCard(Community community, int relevanceScore, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CommunityDetailScreen(community: community),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank and Relevance Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRankColor(rank),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (relevanceScore > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFF6C5CE7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$relevanceScore match${relevanceScore > 1 ? 'es' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Text(
                      _formatDate(community.dateAdded),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Community Header
                Row(
                  children: [
                    // Community Banner or Default Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: community.communityBanner != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                community.communityBanner!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: 24,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Community Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.communityName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${community.memberCount} members',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                
                // Announcement
                if (community.announcement != null && community.announcement!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      community.announcement!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                // Hashtags with relevance highlighting
                if (community.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: community.hashtags.take(5).map((hashtag) {
                      final isRelevant = _isHashtagRelevant(hashtag);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isRelevant 
                              ? const Color(0xFF6C5CE7).withValues(alpha: 0.4)
                              : const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: isRelevant 
                              ? Border.all(
                                  color: const Color(0xFF6C5CE7),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Text(
                          '#$hashtag',
                          style: TextStyle(
                            fontSize: 12,
                            color: isRelevant 
                                ? const Color(0xFF6C5CE7) 
                                : const Color(0xFF6C5CE7).withValues(alpha: 0.8),
                            fontWeight: isRelevant 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF6C5CE7); // Default purple
    }
  }

  bool _isHashtagRelevant(String hashtag) {
    for (String interest in _userInterests) {
      if (hashtag.toLowerCase().contains(interest.toLowerCase()) ||
          interest.toLowerCase().contains(hashtag.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  String _getInterestDisplayName(String interestId) {
    // Map interest IDs to display names
    const Map<String, String> interestMap = {
      'business': '자영업',
      'startup': '스타트업',
      'career_change': '이직',
      'resignation': '퇴사',
      'employment': '취직',
      'study': '학업',
      'contest': '공모전',
      'mental_care': '멘탈케어',
      'relationships': '인간관계',
      'daily_life': '일상',
      'humor': '유머',
      'health': '건강',
    };
    
    return interestMap[interestId] ?? interestId;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}