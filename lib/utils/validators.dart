/// Input validators for profile fields
class Validators {
  Validators._();

  /// Validate name/alias (2-20 chars, no special chars)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 20) {
      return 'Name must be 20 characters or less';
    }
    // No URLs or social handles in name
    if (RegExp(r'[@#]').hasMatch(value)) {
      return 'Special characters not allowed';
    }
    return null;
  }

  /// Validate age (18-99)
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Enter a valid age';
    }
    if (age < 18) {
      return 'Must be 18 or older';
    }
    if (age > 99) {
      return 'Enter a valid age';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove non-digit chars for validation
    final digits = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validate OTP code
  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be numeric';
    }
    return null;
  }
}
