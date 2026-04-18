import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme.dart';

/// Selfie verification screen — captures selfie for MVP auto-verification
class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selfieFile;
  bool _isVerifying = false;

  Future<void> _takeSelfie() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _selfieFile = File(image.path));
    }
  }

  Future<void> _verify() async {
    if (_selfieFile == null) return;

    setState(() => _isVerifying = true);

    final success = await context.read<UserProvider>().verifySelfie(_selfieFile!);

    if (!mounted) return;

    if (success) {
      // Navigation handled by router observing verified state
    } else {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Text(
                  'Verify your identity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a selfie to confirm you\'re a real person.\nThis won\'t be shown to anyone.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),

                const Spacer(flex: 1),

                // Selfie preview
                Center(
                  child: GestureDetector(
                    onTap: _takeSelfie,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceLight,
                        border: Border.all(
                          color: _selfieFile != null
                              ? AppTheme.success
                              : AppTheme.surfaceLighter,
                          width: 3,
                        ),
                        image: _selfieFile != null
                            ? DecorationImage(
                                image: FileImage(_selfieFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selfieFile == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppTheme.textMuted,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Take selfie',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Retake button
                if (_selfieFile != null)
                  Center(
                    child: TextButton.icon(
                      onPressed: _takeSelfie,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retake'),
                    ),
                  ),

                const Spacer(flex: 2),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _selfieFile != null && !_isVerifying ? _verify : null,
                    child: _isVerifying
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify & Continue'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
