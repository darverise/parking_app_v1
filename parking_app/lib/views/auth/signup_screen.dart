import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Add this import
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/views/common/widgets/input_fields.dart';
import 'package:parking_app/views/common/widgets/buttons.dart';
import 'package:parking_app/views/common/widgets/error.dart';

// Define enum outside the class
enum UserRole { user, owner }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _prefectureController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;
  String? _errorMessage;

  void _updateUserRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _navigateToSignIn() {
    Navigator.of(context).pop();
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ← ログインに戻る
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _navigateToSignIn,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        label: Text(
                          l10n.backToLogin,
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
                    const SizedBox(height: 8.0),
                    // Fake SVG image placeholder
                    Container(
                      height: 80,
                      width: 80,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      l10n.signup,
                      style: TextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      l10n.createAccountTitle,
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: FormErrorText(text: _errorMessage),
                      ),
                    AppTextField(
                      label: l10n.name,
                      hintText: l10n.nameHint,
                      controller: _nameController,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.phone,
                      hintText: l10n.phoneHint,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.postalCode,
                      hintText: l10n.postalCodeHint,
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.prefecture,
                      hintText: l10n.prefectureHint,
                      controller: _prefectureController,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.address,
                      hintText: l10n.addressHint,
                      controller: _addressController,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    // Replace the birthday field with a TextField that supports date picking
                    TextField(
                      controller: _birthdayController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _birthdayController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                      decoration: InputDecoration(
                        labelText: l10n.birthday,
                        hintText: l10n.birthdayHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Gender dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: l10n.gender,
                        hintText: l10n.genderHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(l10n.genderMale),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(l10n.genderFemale),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(l10n.genderOther),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.email,
                      hintText: l10n.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.password,
                      hintText: l10n.passwordHint,
                      controller: _passwordController,
                      obscureText: true,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                      showTogglePasswordVisibility: true,
                    ),
                    const SizedBox(height: 16.0),
                    AppTextField(
                      label: l10n.confirmPassword,
                      hintText: l10n.confirmPasswordHint,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator:
                          (v) =>
                              v != _passwordController.text
                                  ? l10n.passwordsDoNotMatch
                                  : null,
                      showTogglePasswordVisibility: true,
                    ),
                    const SizedBox(height: 16.0),
                    // User/Owner segmented control
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Row(
                          children: [
                            _buildRoleOption(
                              UserRole.user,
                              l10n.user,
                              Icons.person,
                            ),
                            _buildRoleOption(
                              UserRole.owner,
                              l10n.owner,
                              Icons.business,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    PrimaryButton(
                      text: l10n.signup,
                      onPressed: () {},
                      isLoading: _isLoading,
                    ),

                    // Add login link below the signup button
                    const SizedBox(height: 24.0),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "すでにアカウントをお持ちですか？ ",
                          style: TextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: "ログイン",
                              style: TextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = _navigateToSignIn,
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
