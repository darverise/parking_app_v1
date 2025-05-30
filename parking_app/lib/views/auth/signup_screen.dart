import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/views/common/widgets/input_fields.dart';
import 'package:parking_app/views/common/widgets/error.dart';
import 'package:parking_app/views/auth/verification_code_screen.dart'; // Add this import

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
  String? _selectedRegistrantType; // Added for registrant type
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
      backgroundColor: Colors.white, // 统一背景色
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: isSmallScreen ? double.infinity : 500,
              padding: EdgeInsets.only(
                left: isSmallScreen ? 24.0 : 32.0,
                right: isSmallScreen ? 24.0 : 32.0,
                bottom: isSmallScreen ? 24.0 : 32.0,
                top: isSmallScreen ? 24.0 : 32.0,
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 返回按钮，风格与 verification_code_screen 一致
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

                    // App logo，简化为圆形白底+主色icon
                    Container(
                      height: 80,
                      width: 80,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),

                    // 标题
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

                    // 副标题
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

                    // 角色选择，风格与 verification_code_screen 按钮一致
                    Container(
                      margin: const EdgeInsets.only(bottom: 24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.04),
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

                    // Conditionally display Registrant Type Dropdown
                    if (_selectedRole == UserRole.owner) ...[
                      const SizedBox(height: 16.0),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.0,
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedRegistrantType,
                          decoration: InputDecoration(
                            labelText: null, // Using hint as label
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            hintText: l10n.registrantTypeHint,
                            hintStyle: TextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'individual',
                              child: Text(l10n.registrantTypeIndividual),
                            ),
                            DropdownMenuItem(
                              value: 'corporation',
                              child: Text(l10n.registrantTypeCorporation),
                            ),
                            DropdownMenuItem(
                              value: 'sole_proprietor',
                              child: Text(l10n.registrantTypeSoleProprietor),
                            ),
                            DropdownMenuItem(
                              value: 'voluntary_organization',
                              child: Text(
                                l10n.registrantTypeVoluntaryOrganization,
                              ),
                            ),
                          ],
                          onChanged:
                              (v) =>
                                  setState(() => _selectedRegistrantType = v),
                          validator: (v) {
                            if (_selectedRole == UserRole.owner &&
                                (v == null || v.isEmpty)) {
                              return l10n.requiredField;
                            }
                            return null;
                          },
                          // Use l10n.registrantType as a general label if needed, or rely on hint
                        ),
                      ),
                    ],
                    const SizedBox(height: 16.0),

                    // 输入框区域
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

                    // 生日选择器，风格统一
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.0,
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _selectDate(context, l10n),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}",
                                style: TextStyles.bodyMedium,
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // 性别下拉框
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.0,
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
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
                        hint: Text(l10n.gender),
                      ),
                    ),
                    const SizedBox(height: 16.0),

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
                    const SizedBox(height: 32.0),

                    // 注册按钮，风格统一
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => VerificationCodeScreen(
                                          email: _emailController.text,
                                        ),
                                  ),
                                );
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(160, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.15),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  l10n.signup,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),

                    // 分割线
                    const SizedBox(height: 32.0),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            l10n.or,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // 登录链接
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "${l10n.alreadyHaveAccount} ",
                          style: TextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.login,
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

  // 输入框风格统一为 AppTextField，移除外层 Container 和装饰
  Widget _buildFloatingLabelTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool showTogglePasswordVisibility = false,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      showTogglePasswordVisibility: showTogglePasswordVisibility,
      validator: validator,
      onChanged: (_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      },
    );
  }

  // 角色选择按钮风格统一
  Widget _buildRoleOption(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateUserRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.0,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: TextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new method for date selection
  Future<void> _selectDate(BuildContext context, AppLocalizations l10n) async {
    // Dismiss keyboard if it's open
    FocusScope.of(context).unfocus();

    // Delay to allow keyboard to dismiss completely
    await Future.delayed(const Duration(milliseconds: 100));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      // Use setState outside of the layout phase
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
