import 'package:intl/intl.dart';
import 'package:flutter/material.dart' show TimeOfDay;

/// A utility class for validating dates in the frontend
class DateValidator {
  /// Validates if the string is a valid date format (yyyy-MM-dd)
  static bool isValidDateFormat(String input, {String format = 'yyyy-MM-dd'}) {
    try {
      DateFormat(format).parseStrict(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a date is in the past
  static bool isPastDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  /// Checks if a date is in the future
  static bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now);
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Validates if a date is within a specific range
  static bool isWithinRange(
    DateTime date,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (date.isAtSameMomentAs(startDate) || date.isAfter(startDate)) &&
        (date.isAtSameMomentAs(endDate) || date.isBefore(endDate));
  }

  /// Validates if the age calculated from the birthdate is at least the minimum age
  static bool isMinimumAge(DateTime birthDate, int minimumAge) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= minimumAge;
  }

  /// Validates if two dates are the same (ignoring time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if a date string can be parsed into a valid date
  static bool canParseDate(String input, {String format = 'yyyy-MM-dd'}) {
    try {
      DateFormat(format).parseStrict(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the difference in days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Checks if the current time is between two times of the day
  static bool isTimeBetween(TimeOfDay start, TimeOfDay end, TimeOfDay time) {
    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      start.hour,
      start.minute,
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      end.hour,
      end.minute,
    );
    final checkTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (endTime.isBefore(startTime)) {
      // Handle cases where the range crosses midnight
      return checkTime.isAfter(startTime) || checkTime.isBefore(endTime);
    }

    return checkTime.isAfter(startTime) && checkTime.isBefore(endTime);
  }
}
