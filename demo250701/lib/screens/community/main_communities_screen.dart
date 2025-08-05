import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../models/community_model.dart';
import 'community_detail_screen.dart';

class MainCommunitiesScreen extends StatefulWidget {
  const MainCommunitiesScreen({super.key});

  @override
  State<MainCommunitiesScreen> createState() => _MainCommunitiesScreenState();
}

class _MainCommunitiesScreenState extends State<MainCommunitiesScreen> {
  final CommunityService _communityService = CommunityService();
  List<Community> _communities = [];
  List<Community> _filteredCommunities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      final communities = await _communityService.getAllCommunities();
      if (mounted) {
        setState(() {
          _communities = communities;
          _filteredCommunities = communities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load communities: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCommunities(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCommunities = _communities;
      } else {
        _filteredCommunities = _communities.where((community) {
          final nameLower = community.communityName.toLowerCase();
          final queryLower = query.toLowerCase();
          final hashtagsMatch = community.hashtags.any(
            (hashtag) => hashtag.toLowerCase().contains(queryLower),
          );
          return nameLower.contains(queryLower) || hashtagsMatch;
        }).toList();
      }
    });
  }

  Future<void> _refreshCommunities() async {
    setState(() => _isLoading = true);
    await _loadCommunities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Communities',
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshCommunities,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search communities or hashtags...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6C5CE7),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C5CE7),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: _filterCommunities,
              ),
            ),
            
            // Communities List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                      ),
                    )
                  : _filteredCommunities.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshCommunities,
                          color: const Color(0xFF6C5CE7),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredCommunities.length,
                            itemBuilder: (context, index) {
                              final community = _filteredCommunities[index];
                              return _buildCommunityCard(community);
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
            _searchQuery.isEmpty ? Icons.group_off : Icons.search_off,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No communities found'
                : 'No communities match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Be the first to create one!'
                : 'Try different keywords or hashtags',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
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
                    
                    // Date Added
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(community.dateAdded),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ],
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
                
                // Hashtags
                if (community.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: community.hashtags.take(5).map((hashtag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$hashtag',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w500,
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