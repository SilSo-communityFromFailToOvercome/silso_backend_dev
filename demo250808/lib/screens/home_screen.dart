import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import 'community/add_community_screen.dart';
import 'community/main_communities_screen.dart';
import 'community/my_communities_screen.dart';
import 'community/community_detail_screen.dart';
import 'community/recommended_communities_screen.dart';

//testing
import 'community/community_mvp/community_tab_mycom.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    print("screens/home_screen.dart is showing");
    // Ensure user is subscribed to default community
    _communityService.ensureDefaultCommunitySubscription();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildCommunityActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return Material(
      color: isSpecial 
          ? const Color(0xFFFFD700).withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSpecial ? const Color(0xFFFFD700) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSpecial ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Silso',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
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
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _authService.getUserDisplayName(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_authService.isAnonymous)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Guest Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Community Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Community Hub',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Connect, Share, Discover',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Access Buttons Layout
                    Column(
                      children: [
                        // First Row - 2 buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildCommunityActionButton(
                                icon: Icons.explore,
                                label: 'Browse All',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const MainCommunitiesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCommunityActionButton(
                                icon: Icons.recommend,
                                label: 'Recommended',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const RecommendedCommunitiesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Second Row - 2 buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildCommunityActionButton(
                                icon: Icons.group,
                                label: 'My Communities',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const MyCommunitiesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCommunityActionButton(
                                icon: Icons.add_circle,
                                label: 'Create New',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CommunityMainTabScreenMycom(), //const AddCommunityScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Third Row - Default Community (Full Width)
                        _buildCommunityActionButton(
                          icon: Icons.star,
                          label: '종합게시반 - Default Community for All Users',
                          onTap: () async {
                            try {
                              // Show loading indicator
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Loading default community...'),
                                      ],
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }

                              final defaultCommunity = await _communityService.initializeDefaultCommunity();
                              
                              if (defaultCommunity != null && mounted) {
                                // Clear any existing snackbars
                                ScaffoldMessenger.of(context).clearSnackBars();
                                
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CommunityDetailScreen(community: defaultCommunity),
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to initialize default community'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          isSpecial: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // User Account Information
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              // Account Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _authService.currentUser?.email ?? 'Not provided',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'Display Name',
                      value: _authService.currentUser?.displayName ?? 'Not set',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.fingerprint,
                      label: 'User ID',
                      value: '${_authService.currentUser?.uid.substring(0, 8)}...',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: _authService.isAnonymous ? Icons.visibility_off : Icons.verified_user,
                      label: 'Account Type',
                      value: _authService.isAnonymous ? 'Guest User' : 'Registered User',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Created',
                      value: _authService.currentUser?.metadata.creationTime != null
                          ? _formatDate(_authService.currentUser!.metadata.creationTime!)
                          : 'Unknown',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.schedule,
                      label: 'Last Sign In',
                      value: _authService.currentUser?.metadata.lastSignInTime != null
                          ? _formatDate(_authService.currentUser!.metadata.lastSignInTime!)
                          : 'Unknown',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6C5CE7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Development-only Community Screen that bypasses profile setup
class _DevCommunityScreen extends StatelessWidget {
  const _DevCommunityScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Community (Dev Mode)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Development Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.code, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Development Mode: Profile setup bypassed',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.people,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Welcome to the Community!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connect, share experiences, and discover new perspectives with fellow community members.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Community Navigation Options
              Column(
                children: [
                  // Add Community Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddCommunityScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle, color: Colors.white),
                      label: const Text(
                        'Add Community',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Main Page Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MainCommunitiesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.home, color: Colors.white),
                      label: const Text(
                        'Main Page',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF74B9FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // My Communities Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyCommunitiesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.group, color: Colors.white),
                      label: const Text(
                        'My Communities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

}