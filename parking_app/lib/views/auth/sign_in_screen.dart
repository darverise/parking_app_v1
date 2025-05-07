import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../common/widgets/buttons.dart';
import '../common/widgets/input_fields.dart';
import '../common/widgets/error.dart';

// Define enum outside the class
enum UserRole { user, owner }

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  // Add user role tracking
  UserRole _selectedRole = UserRole.user;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _updateUserRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Here you would implement actual authentication logic
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate network request

      // For demonstration, we'll just print the credentials
      debugPrint('Signing in with: ${_emailController.text}');

      // Navigate to home screen or handle success scenario
      // Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    // メールアドレスの検証を行う
    final l10n = AppLocalizations.of(context); // 非nullアサーション演算子を削除
    if (value == null || value.isEmpty) {
      return l10n.requiredField;
    }
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(value)) {
      return l10n.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // パスワードの検証を行う
    final l10n = AppLocalizations.of(context); // 非nullアサーション演算子を削除
    if (value == null || value.isEmpty) {
      return l10n.requiredField;
    }
    if (value.length < 6) {
      return l10n.passwordTooShort;
    }
    return null;
  }

  void _navigateToRegister() {
    // 登録画面に移動する
    // Navigator.of(context).pushNamed('/register');
    debugPrint('Navigate to register screen');
  }

  void _navigateToForgotPassword() {
    // パスワード再設定画面に移動する
    // Navigator.of(context).pushNamed('/forgot-password');
    debugPrint('Navigate to forgot password screen');
  }

  @override
  Widget build(BuildContext context) {
    // 国際化リソースを取得
    final l10n = AppLocalizations.of(context); // 非nullアサーション演算子を削除
    // 画面サイズを取得
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isSmallScreen ? double.infinity : 500,
              padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo or Image
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Image.asset(
                        'assets/images/app_logo.png', // Ensure this asset exists
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if logo image doesn't exist
                          return Icon(
                            Icons.local_parking,
                            size: 80.0,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),

                    // User/Owner segmented control
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              _buildRoleOption(
                                UserRole.user,
                                'ユーザー',
                                Icons.person,
                              ),
                              _buildRoleOption(
                                UserRole.owner,
                                'オーナー',
                                Icons.business,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      l10n.login,
                      style: TextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),

                    // Error message if any
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: FormErrorText(text: _errorMessage),
                      ),

                    // Email input field
                    AppTextField(
                      label: l10n.email,
                      hintText: l10n.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Password input field
                    AppTextField(
                      label: l10n.password,
                      hintText: l10n.passwordHint,
                      controller: _passwordController,
                      obscureText: true,
                      validator: _validatePassword,
                      focusNode: _passwordFocusNode,
                      textInputAction: TextInputAction.done,
                      showTogglePasswordVisibility: true,
                      onFieldSubmitted: (_) => _handleSignIn(),
                    ),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: Text(l10n.forgotPassword),
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // Login button
                    PrimaryButton(
                      text: l10n.login,
                      onPressed: _handleSignIn,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 24.0),

                    // "or" divider
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            l10n.or,
                            style: TextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 24.0),

                    // Registration link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: '${l10n.createAccount.split('？')[0]}？',
                          style: TextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.registerNow,
                              style: TextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = _navigateToRegister,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build each role option
  Widget _buildRoleOption(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => _updateUserRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.0,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
