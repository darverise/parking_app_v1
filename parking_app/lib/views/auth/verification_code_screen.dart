import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;
  final String? phoneNumber;

  const VerificationCodeScreen({
    super.key,
    required this.email,
    this.phoneNumber,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _resendTimeLeft = 59;
  Timer? _timer;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSmsMode = false; // Track if we're in SMS verification mode

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Set focus to first digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });

    // Add listeners to controllers and focus nodes
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() {
        _onTextChanged(i);
      });

      _focusNodes[i].addListener(() {
        setState(() {}); // Rebuild to update the visual state of inputs
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimeLeft > 0) {
          _resendTimeLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _onTextChanged(int index) {
    if (_controllers[index].text.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        // Last digit entered, hide keyboard
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace &&
          _controllers[index].text.isEmpty &&
          index > 0) {
        // Move to previous field when backspace is pressed on empty field
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }
  }

  String get _getFullCode {
    return _controllers.map((controller) => controller.text).join();
  }

  void _verifyCode() {
    final code = _getFullCode;
    if (code.length != 6) {
      // Show error if code is incomplete
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).verificationCodeIncomplete,
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate verification process
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      // Navigate to next screen or show success
      // This is where you would normally verify the code with your backend
      Navigator.of(context).pushReplacementNamed('/verification-success');
    });
  }

  void _resendCode() {
    if (_resendTimeLeft > 0) return;

    setState(() {
      _resendTimeLeft = 59;
    });
    _startResendTimer();

    // Show confirmation that code was resent
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).verificationCodeResent),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _switchToSmsMode() {
    setState(() {
      _isSmsMode = true;

      // Reset verification fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Reset timer if needed
      _resendTimeLeft = 59;
      _timer?.cancel();
      _startResendTimer();

      // Set focus to first digit again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      });
    });

    // Show confirmation that we switched to SMS mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).switchedToSmsVerification),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _switchToEmailMode() {
    setState(() {
      _isSmsMode = false;

      // Reset verification fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Reset timer if needed
      _resendTimeLeft = 59;
      _timer?.cancel();
      _startResendTimer();

      // Set focus to first digit again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      });
    });

    // Show confirmation that we switched to email mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).switchedToEmailVerification),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    // Calculate the available width for the verification code fields
    final fieldSpacing = isSmallScreen ? 4.0 : 6.0;
    final availableWidth = screenSize.width - (isSmallScreen ? 24.0 : 32.0);
    final fieldWidth = (availableWidth - (fieldSpacing * 10)) / 6;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0), // Zero height app bar
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
        ),
      ),
      body: SafeArea(
        top: false, // Don't apply safe area at top to give us more control
        child: Column(
          children: [
            // Back button positioned higher with custom padding
            Container(
              padding: EdgeInsets.only(
                top:
                    MediaQuery.of(context).padding.top +
                    4, // Adjust to device notch height
                left: isSmallScreen ? 24.0 : 32.0,
                right: isSmallScreen ? 24.0 : 32.0,
              ),
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                label: Text(
                  l10n.backToRegistration,
                  style: TextStyles.bodyMedium,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                ),
              ),
            ),

            // Rest of the content in scrollable area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: isSmallScreen ? double.infinity : 500,
                    padding: EdgeInsets.only(
                      left: isSmallScreen ? 24.0 : 32.0,
                      right: isSmallScreen ? 24.0 : 32.0,
                      bottom: isSmallScreen ? 24.0 : 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 8.0,
                        ), // Reduced space after back button
                        // Title
                        Text(
                          _isSmsMode
                              ? l10n.smsVerificationCode
                              : l10n.verificationCode,
                          style: TextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28.0,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),

                        // Message
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16.0 : 24.0,
                          ),
                          child: Text(
                            _isSmsMode
                                ? l10n.smsVerificationCodeInstructions
                                : l10n.verificationCodeInstructions,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32.0),

                        // Verification code input fields - Modified to use white background
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              6,
                              (index) => _buildCodeDigitField(
                                index,
                                fieldWidth,
                                fieldSpacing,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32.0),

                        // Verify button
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            onTapDown: (_) => _animationController.forward(),
                            onTapUp: (_) => _animationController.reverse(),
                            onTapCancel: () => _animationController.reverse(),
                            child: ElevatedButton(
                              onPressed: _verifyCode,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(160, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        l10n.verify,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Resend code option
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.identReceiveCode,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            GestureDetector(
                              onTap: _resendTimeLeft > 0 ? null : _resendCode,
                              child: Text(
                                l10n.resend,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      _resendTimeLeft > 0
                                          ? Colors.grey[500]
                                          : AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            if (_resendTimeLeft > 0)
                              Text(
                                " (${_resendTimeLeft}s)",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32.0),

                        // Separator
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                l10n.or,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),

                        // SMS Verification option text
                        Text(
                          _isSmsMode
                              ? l10n.verifyWithEmail
                              : l10n.verifyWithPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),

                        // SMS button - now functional with proper switch feedback
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap:
                                  _isSmsMode
                                      ? _switchToEmailMode
                                      : _switchToSmsMode,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isSmsMode ? Icons.email : Icons.sms,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isSmsMode
                                            ? l10n.receiveCodeViaEmail
                                            : l10n.receiveCodeViaSMS,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeDigitField(int index, double width, double spacing) {
    final bool isFocused = _focusNodes[index].hasFocus;
    final bool hasValue = _controllers[index].text.isNotEmpty;
    final bool shouldHighlight = isFocused || hasValue;

    return Container(
      width: width, // Use calculated width
      height: 56,
      margin: EdgeInsets.symmetric(horizontal: spacing), // Use dynamic spacing
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: shouldHighlight ? AppColors.primary : Colors.grey[300]!,
          width: shouldHighlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                shouldHighlight
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.transparent,
            blurRadius: shouldHighlight ? 8 : 0,
            spreadRadius: shouldHighlight ? 1 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onKeyPressed(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.length == 1) {
              if (index < 5) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                FocusScope.of(context).unfocus();
              }
            }
          },
        ),
      ),
    );
  }
}
