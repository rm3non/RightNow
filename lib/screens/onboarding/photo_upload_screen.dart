import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

/// Photo upload screen — add up to 3 photos
class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final userProvider = context.read<UserProvider>();
    final currentPhotos = userProvider.currentUser?.photoUrls.length ?? 0;
    if (currentPhotos >= AppConstants.maxPhotos) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      await userProvider.uploadPhoto(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final photos = userProvider.currentUser?.photoUrls ?? [];

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
                  'Add your photos',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Photos are only visible after a mutual match.\nNo nudity or explicit content allowed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),

                // Photo grid
                Row(
                  children: List.generate(AppConstants.maxPhotos, (index) {
                    final hasPhoto = index < photos.length;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < AppConstants.maxPhotos - 1 ? 12 : 0,
                        ),
                        child: AspectRatio(
                          aspectRatio: 0.75,
                          child: hasPhoto
                              ? _buildPhotoCard(photos[index])
                              : _buildAddPhotoCard(index == photos.length),
                        ),
                      ),
                    );
                  }),
                ),

                if (userProvider.isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 8),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (userProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    userProvider.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ],

                const Spacer(),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off_outlined,
                        color: AppTheme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your photos are hidden until you match with someone',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.info,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: photos.isNotEmpty ? () {} : null, // Navigate handled by router
                    child: Text(
                      photos.isEmpty ? 'Add at least 1 photo' : 'Continue',
                    ),
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

  Widget _buildPhotoCard(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.surfaceLight,
              child: const Icon(Icons.broken_image, color: AppTheme.textMuted),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => context.read<UserProvider>().removePhoto(url),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard(bool isPrimary) {
    return GestureDetector(
      onTap: isPrimary ? _pickPhoto : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isPrimary ? AppTheme.primary : AppTheme.surfaceLighter,
            width: isPrimary ? 2 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: isPrimary ? AppTheme.primary : AppTheme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              isPrimary ? 'Add' : '',
              style: TextStyle(
                color: isPrimary ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
