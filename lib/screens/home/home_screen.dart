import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../feed/feed_screen.dart';
import '../matches/matches_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import 'post_intent_sheet.dart';

/// Home screen — main app shell with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    MatchesScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  void _initProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().currentUser;
      final uid = context.read<AuthProvider>().uid;
      if (user != null && uid != null) {
        context.read<FeedProvider>().initFeed(user);
        context.read<MatchProvider>().initMatches(uid);
        context.read<ChatProvider>().initChats(uid);
      }
    });
  }

  void _showPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PostIntentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<MatchProvider>();
    final feedProvider = context.watch<FeedProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(context, feedProvider),

              // Content
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      ),

      // FAB for posting intent
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showPostSheet,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.surfaceLighter.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: matchProvider.hasNewMatches,
                backgroundColor: AppTheme.accent,
                label: Text(
                  matchProvider.unreadMatchCount.toString(),
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.favorite_outline),
              ),
              activeIcon: const Icon(Icons.favorite),
              label: 'Matches',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, FeedProvider feedProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: const Text(
              'Right Now',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Active post indicator
          if (feedProvider.hasActivePost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppTheme.success, size: 8),
                  SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
