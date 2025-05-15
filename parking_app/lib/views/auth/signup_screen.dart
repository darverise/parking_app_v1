import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/sliding_date_picker.dart';
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
  DateTime _selectedDate = DateTime(2000, 1, 1);

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

                    // App logo with enhanced styling
                    Container(
                      height: 80,
                      width: 80,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),

                    // Title with enhanced styling
                    Text(
                      l10n.signup,
                      style: TextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),

                    // Subtitle with enhanced styling
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

                    // User/Owner segmented control with enhanced styling
                    Container(
                      margin: const EdgeInsets.only(bottom: 24.0),
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

                    // Name field with floating label
                    _buildFloatingLabelTextField(
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

                    // Phone field with floating label
                    _buildFloatingLabelTextField(
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

                    // Postal code field with floating label
                    _buildFloatingLabelTextField(
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

                    // Prefecture field with floating label
                    _buildFloatingLabelTextField(
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

                    // Address field with floating label
                    _buildFloatingLabelTextField(
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

                    // Custom sliding date picker
                    SlidingDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      labelText: l10n.birthday,
                      hintText: l10n.birthdayHint,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Gender dropdown with enhanced styling
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: l10n.gender,
                          hintText: l10n.genderHint,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
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
                    ),
                    const SizedBox(height: 16.0),

                    // Email field with floating label
                    _buildFloatingLabelTextField(
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

                    // Password field with floating label
                    _buildFloatingLabelTextField(
                      label: l10n.password,
                      hintText: l10n.passwordHint,
                      controller: _passwordController,
                      obscureText: true,
                      showTogglePasswordVisibility: true,
                      validator:
                          (v) =>
                              v == null || v.isEmpty
                                  ? l10n.requiredField
                                  : null,
                    ),
                    const SizedBox(height: 16.0),

                    // Confirm password field with floating label
                    _buildFloatingLabelTextField(
                      label: l10n.confirmPassword,
                      hintText: l10n.confirmPasswordHint,
                      controller: _confirmPasswordController,
                      obscureText: true,
                      showTogglePasswordVisibility: true,
                      validator:
                          (v) =>
                              v != _passwordController.text
                                  ? l10n.passwordsDoNotMatch
                                  : null,
                    ),
                    const SizedBox(height: 24.0),

                    // Enhanced signup button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: PrimaryButton(
                        text: l10n.signup,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Here we would handle the signup process
                            setState(() {
                              _isLoading = true;
                            });
                            // Simulate API call
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                _isLoading = false;
                              });
                            });
                          }
                        },
                        isLoading: _isLoading,
                      ),
                    ),

                    // Enhanced login link
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
                                decoration: TextDecoration.underline,
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

  Widget _buildFloatingLabelTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool showTogglePasswordVisibility = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppTextField(
        label: label,
        hintText: hintText,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        showTogglePasswordVisibility: showTogglePasswordVisibility,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ]
                    : null,
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
