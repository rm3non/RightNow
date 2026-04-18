import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM notification service
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize notifications and request permissions
  Future<void> initialize() async {
    // Request permission (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token and save to user profile
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveToken);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Save FCM token to user's document
  Future<void> _saveToken(String token) async {
    // This will be called after auth, so we store it for later use
    _currentToken = token;
  }

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Save the token to Firestore for the given user
  Future<void> saveTokenForUser(String uid) async {
    if (_currentToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcm_token': _currentToken});
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // In MVP, we rely on default notification display
    // Future: show in-app notification banner
  }

  /// Handle background messages (must be top-level function)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
  }
}
