import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';

/// Match state management
class MatchProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();

  List<MatchModel> _matches = [];
  final Map<String, UserModel> _matchPartners = {};
  bool _isLoading = false;
  int _unreadMatchCount = 0;
  StreamSubscription? _matchesSub;

  List<MatchModel> get matches => _matches;
  Map<String, UserModel> get matchPartners => _matchPartners;
  bool get isLoading => _isLoading;
  int get unreadMatchCount => _unreadMatchCount;
  bool get hasNewMatches => _unreadMatchCount > 0;

  /// Initialize match listener for a user
  void initMatches(String userId) {
    _matchesSub?.cancel();
    _matchesSub = _matchService.getMatchesStream(userId).listen((matches) {
      // Detect new matches
      if (matches.length > _matches.length) {
        _unreadMatchCount += matches.length - _matches.length;
      }
      _matches = matches;
      _loadPartnerProfiles(userId);
      notifyListeners();
    });
  }

  /// Load partner profiles for all matches
  Future<void> _loadPartnerProfiles(String currentUid) async {
    for (final match in _matches) {
      final partnerUid = match.otherUser(currentUid);
      if (!_matchPartners.containsKey(partnerUid)) {
        final partner = await _matchService.getMatchPartner(
          matchId: match.matchId,
          currentUid: currentUid,
        );
        if (partner != null) {
          _matchPartners[partnerUid] = partner;
        }
      }
    }
    notifyListeners();
  }

  /// Get partner profile for a specific match
  UserModel? getPartner(String partnerUid) => _matchPartners[partnerUid];

  /// Clear unread match count
  void clearUnreadCount() {
    _unreadMatchCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _matchesSub?.cancel();
    super.dispose();
  }
}
