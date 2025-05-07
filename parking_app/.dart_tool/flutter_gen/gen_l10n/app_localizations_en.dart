// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Parking App';

  @override
  String get welcomeMessage => 'Welcome to Parking App';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get findParking => 'Find Parking';

  @override
  String get availableSpots => 'Available Spots';

  @override
  String get parkingTime => 'Parking Time';

  @override
  String get startParking => 'Start Parking';

  @override
  String get endParking => 'End Parking';

  @override
  String get payment => 'Payment';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get help => 'Help';

  @override
  String get language => 'Language';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get or => 'or';

  @override
  String get createAccount => 'Don\'t have an account? Register';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get registerNow => 'Register';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';
}
