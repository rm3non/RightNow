import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/feed_service.dart';
import '../services/post_service.dart';
import '../services/interest_service.dart';
import '../config/constants.dart';
import '../utils/content_filter.dart';

/// Feed and intent post state management
class FeedProvider extends ChangeNotifier {
  final FeedService _feedService = FeedService();
  final PostService _postService = PostService();
  final InterestService _interestService = InterestService();

  List<PostModel> _feedPosts = [];
  PostModel? _activePost;
  Set<String> _sentInterestPostIds = {};
  bool _isLoading = false;
  bool _isPostingIntent = false;
  String? _errorMessage;
  IntentType? _intentFilter;
  StreamSubscription? _feedSub;
  StreamSubscription? _postSub;
  StreamSubscription? _interestSub;

  List<PostModel> get feedPosts => _feedPosts;
  PostModel? get activePost => _activePost;
  bool get isLoading => _isLoading;
  bool get isPostingIntent => _isPostingIntent;
  String? get errorMessage => _errorMessage;
  IntentType? get intentFilter => _intentFilter;
  bool get hasActivePost => _activePost != null && !_activePost!.isExpired;

  /// Check if user has already sent interest for a post
  bool hasExpressedInterest(String postId) => _sentInterestPostIds.contains(postId);

  /// Initialize feed for a user
  void initFeed(UserModel user) {
    _feedSub?.cancel();
    _postSub?.cancel();
    _interestSub?.cancel();

    // Listen to feed
    _feedSub = _feedService
        .getFeedStream(currentUser: user, intentTypeFilter: _intentFilter)
        .listen((posts) {
      _feedPosts = posts;
      notifyListeners();
    });

    // Listen to user's active post
    _postSub = _postService.getUserActivePostStream(user.uid).listen((post) {
      _activePost = post;
      notifyListeners();
    });

    // Listen to sent interests
    _interestSub =
        _interestService.getSentInterestPostIds(user.uid).listen((postIds) {
      _sentInterestPostIds = postIds.toSet();
      notifyListeners();
    });
  }

  /// Set intent type filter and refresh feed
  void setIntentFilter(IntentType? filter, UserModel user) {
    _intentFilter = filter;
    notifyListeners();

    // Re-subscribe with new filter
    _feedSub?.cancel();
    _feedSub = _feedService
        .getFeedStream(currentUser: user, intentTypeFilter: filter)
        .listen((posts) {
      _feedPosts = posts;
      notifyListeners();
    });
  }

  /// Create a new intent post
  Future<bool> createPost({
    required UserModel user,
    required String text,
    required IntentType intentType,
  }) async {
    // Validate content
    final filterResult = ContentFilter.filterIntentText(text);
    if (!filterResult.isAllowed) {
      _errorMessage = filterResult.reason;
      notifyListeners();
      return false;
    }

    _isPostingIntent = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _postService.createPost(
        user: user,
        text: filterResult.filteredText,
        intentType: intentType,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isPostingIntent = false;
      notifyListeners();
    }
  }

  /// Express interest ("I'm in") on a post
  Future<void> expressInterest({
    required String fromUser,
    required PostModel post,
  }) async {
    try {
      await _interestService.expressInterest(
        fromUser: fromUser,
        toUser: post.userId,
        toPost: post.postId,
      );
      _sentInterestPostIds.add(post.postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to express interest';
      notifyListeners();
    }
  }

  /// Expire the user's active post
  Future<void> expireActivePost() async {
    if (_activePost == null) return;
    try {
      await _postService.expirePost(_activePost!.postId);
    } catch (e) {
      _errorMessage = 'Failed to remove post';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _postSub?.cancel();
    _interestSub?.cancel();
    super.dispose();
  }
}
