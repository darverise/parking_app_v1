import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/services/auth_signin_service.dart';
import 'package:parking_app/views/auth/home_screen.dart';
import 'package:parking_app/views/common/widgets/buttons.dart';
import 'package:parking_app/views/common/widgets/error.dart';
import 'package:parking_app/views/common/widgets/input_fields.dart';
import 'package:provider/provider.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';

// Define enum outside the class
enum UserRole { user, owner }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

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
  bool _rememberMe = false;
  String? _errorMessage;

  // Add user role tracking
  UserRole _selectedRole = UserRole.user;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkSavedCredentials() async {
    try {
      final authService = Provider.of<AuthSignInService>(
        context,
        listen: false,
      );
      final isRemembered = await authService.isRememberUserLogin();
      if (isRemembered) {
        setState(() {
          _rememberMe = true;
          // If you stored the email, you could retrieve it here
          // _emailController.text = savedEmail;
        });
      }
    } catch (e) {
      debugPrint('Error checking saved credentials: $e');
    }
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
      final authService = Provider.of<AuthSignInService>(
        context,
        listen: false,
      );

      // Create sign-in request
      final signInRequest = SignInRequest(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Call API
      final response = await authService.signIn(
        signInRequest.username,
        signInRequest.password,
      );

      if (!response.isSuccess || response.data == null) {
        throw Exception(response.message ?? "Login failed");
      }

      final authUserModel = response.data!;

      // Check if user selected role matches the actual role from the backend
      final bool isOwner = authUserModel.is_owner;
      if ((_selectedRole == UserRole.owner && !isOwner) ||
          (_selectedRole == UserRole.user && isOwner)) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context).invalidInput ??
              "選択した役割がアカウントタイプと一致しません";
        });
        return;
      }

      // Save "remember me" preference
      await authService.rememberUserLogin(_rememberMe);

      if (mounted) {
        // Navigate to home screen and pass the user data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    HomePage(authUserModel: authUserModel, isOwner: isOwner),
          ),
        );
      }
    } catch (e) {
      setState(() {
        // Convert error message to user-friendly format
        if (e.toString().contains('InvalidCredentials')) {
          _errorMessage =
              AppLocalizations.of(context).invalidInput ??
              "メールアドレスまたはパスワードが無効です";
        } else if (e.toString().contains('AccountLocked')) {
          _errorMessage =
              AppLocalizations.of(context).invalidInput ??
              "試行回数が多すぎるため、アカウントがロックされました";
        } else {
          _errorMessage = e.toString();
        }
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
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? "この項目は必須です";
    }

    // Allow both email and phone input
    if (value.contains('@')) {
      // Validate as email
      final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegExp.hasMatch(value)) {
        return l10n.invalidEmail ?? "有効なメールアドレスを入力してください";
      }
    } else {
      // Validate as phone
      final phoneRegExp = RegExp(r'^\d{10,15}$');
      if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
        return l10n.invalidInput ?? "有効な電話番号を入力してください";
      }
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.requiredField ?? "この項目は必須です";
    }
    if (value.length < 6) {
      return l10n.passwordTooShort ?? "パスワードは6文字以上で入力してください";
    }
    return null;
  }

  void _navigateToRegister() {
    // 使用直接的路径字符串而非未定义的AppRoutes常量
    Navigator.of(context).pushNamed('/register');
  }

  void _navigateToForgotPassword() {
    // 使用直接的路径字符串而非未定义的AppRoutes常量
    Navigator.of(context).pushNamed('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        'assets/images/app_logo.png',
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
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
                                "ユーザー", // 使用硬编码替代l10n?.welcome
                                Icons.person,
                              ),
                              _buildRoleOption(
                                UserRole.owner,
                                "オーナー", // 使用硬编码替代l10n?.welcome
                                Icons.business,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      l10n.login ?? "ログイン",
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

                    // Email/Phone input field
                    AppTextField(
                      label: l10n.email ?? "メールアドレス/電話番号",
                      hintText: l10n.emailHint ?? "メールアドレスまたは電話番号を入力してください",
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

                    // Remember me and Forgot password row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember me checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Text(
                              "ログイン情報を保存", // 使用硬编码替代l10n?.welcome
                              style: TextStyles.bodyMedium,
                            ),
                          ],
                        ),

                        // Forgot password link
                        TextButton(
                          onPressed: _navigateToForgotPassword,
                          child: Text(l10n.forgotPassword),
                        ),
                      ],
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
                          text: l10n.createAccount,
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
