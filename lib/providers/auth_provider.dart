import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

enum AuthState {
  initial,
  unauthenticated,
  sendingOTP,
  otpSent,
  verifying,
  authenticated,
  profileIncomplete,
  error,
}

/// Authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  AuthState _state = AuthState.initial;
  String? _verificationId;
  int? _resendToken;
  String? _phoneNumber;
  String? _errorMessage;
  User? _user;

  AuthState get state => _state;
  String? get verificationId => _verificationId;
  String? get phoneNumber => _phoneNumber;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  String? get uid => _user?.uid;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _state = AuthState.authenticated;
        _notificationService.saveTokenForUser(user.uid);
      } else {
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  /// Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    _state = AuthState.sendingOTP;
    _errorMessage = null;
    notifyListeners();

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      onAutoVerified: (credential) async {
        _state = AuthState.verifying;
        notifyListeners();
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _state = AuthState.authenticated;
        } catch (e) {
          _state = AuthState.error;
          _errorMessage = 'Auto-verification failed';
        }
        notifyListeners();
      },
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _state = AuthState.otpSent;
        notifyListeners();
      },
      onError: (error) {
        _state = AuthState.error;
        _errorMessage = _parseAuthError(error);
        notifyListeners();
      },
    );
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String code) async {
    if (_verificationId == null) return false;

    _state = AuthState.verifying;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithOTP(
        verificationId: _verificationId!,
        smsCode: code,
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _state = AuthState.otpSent;
      _errorMessage = _parseAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Check if user has a complete profile
  Future<bool> hasProfile() async {
    if (_user == null) return false;
    return await _authService.doesUserProfileExist(_user!.uid);
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    if (_phoneNumber != null) {
      await sendOTP(_phoneNumber!);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _state = AuthState.unauthenticated;
    _verificationId = null;
    _resendToken = null;
    _phoneNumber = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Parse Firebase auth errors into user-friendly messages
  String _parseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'invalid-verification-code':
        return 'Invalid OTP code';
      case 'session-expired':
        return 'OTP expired. Request a new one';
      default:
        return error.message ?? 'Authentication failed';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
