import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:parking_app/core/auth/auth_signin_api.dart';
import 'package:parking_app/core/utils/dialog_helper.dart';

/// Helper class for avatar-related operations
class AvatarHelper {
  /// Pick an image from gallery or camera and upload it
  static Future<String?> pickAndUploadAvatar(
    BuildContext context,
    AuthSignInApi authApi, {
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      // Show loading indicator
      DialogHelper.showLoadingDialog(context);

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (image == null) {
        return null;
      }

      // Show uploading indicator
      DialogHelper.showLoadingDialog(context);

      // Prepare form data
      final File imageFile = File(image.path);
      final filename = path.basename(imageFile.path);
      final FormData formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: filename,
        ),
      });

      // Upload avatar
      final response = await authApi.uploadAvatar(formData);

      // Close uploading dialog
      Navigator.of(context).pop();

      if (response.isSuccess && response.data != null) {
        // Return avatar URL
        return response.data;
      } else {
        // Show error message
        if (context.mounted) {
          DialogHelper.showErrorDialog(
            context,
            'Upload Failed',
            response.message ?? 'Could not upload avatar',
          );
        }
        return null;
      }
    } catch (e) {
      // Make sure to close any open dialog
      Navigator.of(context).pop();

      // Show error message
      if (context.mounted) {
        DialogHelper.showErrorDialog(
          context,
          'Error',
          'An unexpected error occurred: $e',
        );
      }
      return null;
    }
  }

  /// Build avatar widget with proper error handling
  static Widget buildAvatar({
    required String? avatarUrl,
    required double radius,
    required VoidCallback onTap,
    Widget? placeholder,
    bool showEditIcon = true,
  }) {
    return Stack(
      children: [
        // Avatar image or placeholder
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
            child:
                avatarUrl == null || avatarUrl.isEmpty
                    ? placeholder ??
                        Icon(
                          Icons.person,
                          size: radius * 1.2,
                          color: Colors.grey[400],
                        )
                    : null,
          ),
        ),

        // Edit icon overlay
        if (showEditIcon)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  /// Show avatar selection options dialog
  static Future<ImageSource?> showAvatarSourceDialog(
    BuildContext context,
  ) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
