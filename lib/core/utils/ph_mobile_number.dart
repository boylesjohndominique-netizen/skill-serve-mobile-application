import 'package:flutter/services.dart';

/// Phone numbers on SkillServe are Philippine mobile numbers in one shape:
/// 11 digits starting with 09 (09123456789). Mirrors the API's
/// `PhilippineMobileNumber`, which normalises the same way and has the final
/// say.
class PhMobileNumber {
  PhMobileNumber._();

  static const length = 11;
  static const hint = '09123456789';
  static const message = 'Enter an 11-digit mobile number starting with 09, e.g. 09123456789.';

  static final _pattern = RegExp(r'^09\d{9}$');

  /// The number as 09XXXXXXXXX: spaces, dashes and a +63 / 63 prefix are
  /// dropped, and a number typed without its leading 0 gets it.
  static String normalise(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('639')) digits = '0${digits.substring(2)}';
    if (digits.startsWith('9')) digits = '0$digits';
    return digits.length > length ? digits.substring(0, length) : digits;
  }

  static bool isValid(String value) => _pattern.hasMatch(normalise(value));

  /// For a form field: null when [value] is a valid number, or empty and not
  /// [required].
  static String? validate(String? value, {bool required = true, String? requiredMessage}) {
    final digits = normalise(value ?? '');
    if (digits.isEmpty) return required ? (requiredMessage ?? 'Enter your mobile number.') : null;
    return _pattern.hasMatch(digits) ? null : message;
  }

  /// Keeps the field to an 11-digit 09 number as the user types or pastes:
  /// "+63 912 345 6789" becomes "09123456789", and nothing past the 11th
  /// digit is accepted.
  static final TextInputFormatter formatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = normalise(newValue.text);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  });
}
