class Validators {
  Validators._();

  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // allow optional if empty
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Indian GSTIN Validation (15 alphanumeric characters: 2 state + 10 PAN + 1 entity + 1 Z + 1 check digit)
  static String? gstin(String? value) {
    if (value == null || value.trim().isEmpty) return null; // GSTIN may be optional for unregistered buyers
    final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstinRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Invalid GSTIN format (e.g. 27ABCDE1234F1Z5)';
    }
    return null;
  }

  /// Indian PAN Validation (10 alphanumeric characters)
  static String? pan(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Invalid PAN format (e.g. ABCDE1234F)';
    }
    return null;
  }

  /// Positive number validation
  static String? positiveNumber(String? value, [String message = 'Please enter a valid number']) {
    if (value == null || value.trim().isEmpty) return null;
    final numVal = double.tryParse(value.trim());
    if (numVal == null || numVal <= 0) {
      return message;
    }
    return null;
  }
}
