import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../config/constants.dart';

/// User profile state management
class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _userSub;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _currentUser != null;
  bool get isVerified => _currentUser?.verified ?? false;
  bool get isProfileComplete => _currentUser?.isProfileComplete ?? false;

  /// Load and listen to current user profile
  void loadUser(String uid) {
    _userSub?.cancel();
    _userSub = _userService.getUserStream(uid).listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  /// Create initial user profile
  Future<void> createProfile({
    required String uid,
    required String nameOrAlias,
    required int age,
    required Gender gender,
    required Preference preference,
    required RelationshipType relationshipType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        nameOrAlias: nameOrAlias,
        age: age,
        gender: gender,
        preference: preference,
        relationshipType: relationshipType,
        contentMode: ContentMode.safe,
        photoUrls: [],
        verified: false,
        createdAt: now,
        lastActive: now,
      );

      await _userService.createUser(user);
      _currentUser = user;
    } catch (e) {
      _errorMessage = 'Failed to create profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a photo
  Future<String?> uploadPhoto(File file) async {
    if (_currentUser == null) return null;
    if (_currentUser!.photoUrls.length >= AppConstants.maxPhotos) {
      _errorMessage = 'Maximum ${AppConstants.maxPhotos} photos allowed';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final url = await _storageService.uploadPhoto(
        uid: _currentUser!.uid,
        file: file,
      );
      await _userService.addPhotoUrl(_currentUser!.uid, url);
      return url;
    } catch (e) {
      _errorMessage = 'Failed to upload photo';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove a photo
  Future<void> removePhoto(String photoUrl) async {
    if (_currentUser == null) return;

    try {
      await _storageService.deletePhoto(photoUrl);
      await _userService.removePhotoUrl(_currentUser!.uid, photoUrl);
    } catch (e) {
      _errorMessage = 'Failed to remove photo';
      notifyListeners();
    }
  }

  /// Upload selfie and verify user
  Future<bool> verifySelfie(File file) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.uploadSelfie(
        uid: _currentUser!.uid,
        file: file,
      );
      // MVP: auto-verify after selfie capture
      await _userService.verifyUser(_currentUser!.uid);
      return true;
    } catch (e) {
      _errorMessage = 'Verification failed';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle content mode
  Future<void> toggleContentMode() async {
    if (_currentUser == null) return;

    final newMode = _currentUser!.contentMode == ContentMode.safe
        ? ContentMode.openEnabled
        : ContentMode.safe;

    try {
      await _userService.updateContentMode(_currentUser!.uid, newMode);
    } catch (e) {
      _errorMessage = 'Failed to update mode';
      notifyListeners();
    }
  }

  /// Update profile fields
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.updateUser(_currentUser!.uid, updates);
    } catch (e) {
      _errorMessage = 'Failed to update profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
