import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth/phone_entry_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/onboarding/photo_upload_screen.dart';
import '../screens/onboarding/selfie_verification_screen.dart';
import '../screens/home/home_screen.dart';

/// App routing configuration using GoRouter
GoRouter createRouter(AuthProvider authProvider, UserProvider userProvider) {
  return GoRouter(
    refreshListenable: Listenable.merge([authProvider, userProvider]),
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final authState = authProvider.state;
      final hasProfile = userProvider.hasProfile;
      final isVerified = userProvider.isVerified;
      final isProfileComplete = userProvider.isProfileComplete;
      final currentPath = state.uri.path;

      // Not logged in → auth flow
      if (!isLoggedIn) {
        if (authState == AuthState.otpSent ||
            authState == AuthState.verifying) {
          return currentPath == '/otp' ? null : '/otp';
        }
        return currentPath == '/' ? null : '/';
      }

      // Logged in but no profile → profile setup
      if (!hasProfile) {
        return currentPath == '/setup' ? null : '/setup';
      }

      // Has profile but no photos → photo upload
      if (!isProfileComplete) {
        return currentPath == '/photos' ? null : '/photos';
      }

      // Has profile but not verified → selfie verification
      if (!isVerified) {
        return currentPath == '/verify' ? null : '/verify';
      }

      // Fully set up → home
      if (currentPath == '/' ||
          currentPath == '/otp' ||
          currentPath == '/setup' ||
          currentPath == '/photos' ||
          currentPath == '/verify') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, __) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/photos',
        builder: (_, __) => const PhotoUploadScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (_, __) => const SelfieVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
}
