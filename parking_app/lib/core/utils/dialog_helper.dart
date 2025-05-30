// lib/core/utils/app_dialog_helper.dart
import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';

/// Helper class for showing dialogs and snackbars
class DialogHelper {
  /// Shows a loading dialog
  static Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// Shows an error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyles.dialogTitle.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyles.dialogBody),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyles.dialogLabel.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a success dialog
  static Future<void> showSuccessDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyles.dialogTitle.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyles.dialogBody),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyles.dialogLabel.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmText,
    String cancelText,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyles.dialogTitle.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: TextStyles.dialogBody),
          actions: <Widget>[
            TextButton(
              child: Text(
                cancelText,
                style: TextStyles.dialogLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                confirmText,
                style: TextStyles.dialogLabel.copyWith(
                  color: AppColors.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Shows a snackbar message
  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: duration,
      ),
    );
  }
}
