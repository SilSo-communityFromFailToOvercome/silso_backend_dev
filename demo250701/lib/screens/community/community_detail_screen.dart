import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../services/community_service.dart';
import '../../services/auth_service.dart';
import 'add_post_screen.dart';
import 'community_posts_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({
    super.key,
    required this.community,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  late Community _community;
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _checkSubscriptionStatus();
  }

  void _checkSubscriptionStatus() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      setState(() {
        _isSubscribed = _community.members.contains(currentUserId);
      });
    }
  }

  Future<void> _toggleSubscription() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to subscribe to communities'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSubscribed) {
        await _communityService.leaveCommunity(_community.communityId);
        setState(() {
          _isSubscribed = false;
          _community = _community.copyWith(
            memberCount: _community.memberCount - 1,
            members: _community.members.where((id) => id != currentUserId).toList(),
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left community successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _communityService.joinCommunity(_community.communityId);
        setState(() {
          _isSubscribed = true;
          _community = _community.copyWith(
            memberCount: _community.memberCount + 1,
            members: [..._community.members, currentUserId],
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined community successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isSubscribed ? 'leave' : 'join'} community: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2D2D44),
            onSelected: (value) {
              switch (value) {
                case 'report':
                  _showReportDialog();
                  break;
                case 'share':
                  _shareCommunity();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Share', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Report', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community Banner/Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _community.communityBanner != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _community.communityBanner!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.group,
                                      color: Colors.white,
                                      size: 40,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Community Name
                    Center(
                      child: Text(
                        _community.communityName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Member Count
                    Center(
                      child: Text(
                        '${_community.memberCount} ${_community.memberCount == 1 ? 'Member' : 'Members'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subscribe/Unsubscribe Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleSubscription,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isSubscribed ? Icons.check : Icons.add,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isSubscribed ? 'Subscribed' : 'Subscribe',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubscribed 
                              ? Colors.green.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons for Subscribed Members
              if (_isSubscribed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToAddPost(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Add Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToViewPosts(),
                          icon: const Icon(Icons.visibility, color: Colors.white),
                          label: const Text(
                            'View Posts',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF74B9FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Community Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Announcement Section
                    if (_community.announcement != null && _community.announcement!.isNotEmpty) ...[
                      _buildSectionTitle('Announcement'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          _community.announcement!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Community Information
                    _buildSectionTitle('Community Information'),
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Creator',
                      value: 'User ${_community.creatorId.substring(0, 8)}...',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date Added',
                      value: _formatDetailedDate(_community.dateAdded),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(
                      icon: Icons.group,
                      label: 'Members',
                      value: '${_community.memberCount}',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(
                      icon: Icons.post_add,
                      label: 'Posts',
                      value: '${_community.posts.length}',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Hashtags Section
                    if (_community.hashtags.isNotEmpty) ...[
                      _buildSectionTitle('Hashtags'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _community.hashtags.map((hashtag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '#$hashtag',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6C5CE7),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Report Community',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to report this community for inappropriate content?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _shareCommunity() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
      ),
    );
  }

  Future<void> _navigateToAddPost() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPostScreen(community: _community),
      ),
    );

    // If a post was created successfully, show a success message
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Optionally refresh the community data to update post count
      _refreshCommunityData();
    }
  }

  void _navigateToViewPosts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityPostsScreen(community: _community),
      ),
    );
  }

  Future<void> _refreshCommunityData() async {
    try {
      final updatedCommunity = await _communityService.getCommunity(_community.communityId);
      setState(() {
        _community = updatedCommunity;
      });
    } catch (e) {
      // Handle error silently
    }
  }
}