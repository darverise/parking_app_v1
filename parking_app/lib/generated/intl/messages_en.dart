// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appTitle": MessageLookupByLibrary.simpleMessage("Parking App"),
    "availableSpots": MessageLookupByLibrary.simpleMessage("Available Spots"),
    "createAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account? Register",
    ),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailHint": MessageLookupByLibrary.simpleMessage("example@email.com"),
    "endParking": MessageLookupByLibrary.simpleMessage("End Parking"),
    "findParking": MessageLookupByLibrary.simpleMessage("Find Parking"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage(
      "Forgot your password?",
    ),
    "help": MessageLookupByLibrary.simpleMessage("Help"),
    "invalidEmail": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid email address",
    ),
    "invalidInput": MessageLookupByLibrary.simpleMessage("Invalid input"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "or": MessageLookupByLibrary.simpleMessage("or"),
    "parkingTime": MessageLookupByLibrary.simpleMessage("Parking Time"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "passwordHint": MessageLookupByLibrary.simpleMessage("Enter your password"),
    "passwordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password must be at least 6 characters",
    ),
    "payment": MessageLookupByLibrary.simpleMessage("Payment"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "registerNow": MessageLookupByLibrary.simpleMessage("Register"),
    "requiredField": MessageLookupByLibrary.simpleMessage(
      "This field is required",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "startParking": MessageLookupByLibrary.simpleMessage("Start Parking"),
    "welcome": MessageLookupByLibrary.simpleMessage("Welcome"),
    "welcomeMessage": MessageLookupByLibrary.simpleMessage(
      "Welcome to the Parking App",
    ),
  };
}
