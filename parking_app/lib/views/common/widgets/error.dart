import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/text_styles.dart';
import 'buttons.dart';

class ErrorMessageDisplay extends StatelessWidget {
  final String message;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  final IconData icon;

  const ErrorMessageDisplay({
    Key? key,
    required this.message,
    this.actionButtonText,
    this.onActionPressed,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.error, size: 64.0),
            const SizedBox(height: 16.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.bodyLarge,
            ),
            if (actionButtonText != null && onActionPressed != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: PrimaryButton(
                  text: actionButtonText!,
                  onPressed: onActionPressed,
                  fullWidth: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FormErrorText extends StatelessWidget {
  final String? text;
  final bool visible;

  const FormErrorText({Key? key, this.text, this.visible = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty || !visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text!,
        style: TextStyles.bodyMedium.copyWith(color: AppColors.error),
      ),
    );
  }
}

class ErrorSnackbar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
