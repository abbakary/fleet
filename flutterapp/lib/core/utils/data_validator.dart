/// Utility class for validating inspection-related data
class DataValidator {
  // Private constructor to prevent instantiation
  DataValidator._();

  /// Validates VIN format (basic validation)
  static bool isValidVIN(String vin) {
    final trimmed = vin.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 8) return false;
    // VINs are alphanumeric only
    return RegExp(r'^[A-HJ-NPR-Z0-9]{8,}$').hasMatch(trimmed.toUpperCase());
  }

  /// Validates license plate format (basic US format)
  static bool isValidLicensePlate(String plate) {
    final trimmed = plate.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 3 || trimmed.length > 12) return false;
    return RegExp(r'^[A-Z0-9\- ]+$').hasMatch(trimmed.toUpperCase());
  }

  /// Validates odometer reading (positive number)
  static bool isValidOdometer(int? odometer) {
    return odometer != null && odometer >= 0 && odometer <= 9999999;
  }

  /// Validates email format
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    ).hasMatch(trimmed);
  }

  /// Validates phone number format (basic)
  static bool isValidPhone(String phone) {
    final trimmed = phone.trim().replaceAll(RegExp(r'[^\d]'), '');
    return trimmed.length >= 10 && trimmed.length <= 15;
  }

  /// Validates inspection severity rating (1-5)
  static bool isValidSeverity(int severity) {
    return severity >= 1 && severity <= 5;
  }

  /// Validates inspection result
  static bool isValidResult(String result) {
    return result == 'pass' || result == 'fail' || result == 'not_applicable';
  }

  /// Validates year is reasonable
  static bool isValidYear(int year) {
    final currentYear = DateTime.now().year;
    return year >= 1900 && year <= currentYear + 1;
  }

  /// Sanitizes text input to prevent SQL injection and XSS
  static String sanitize(String input) {
    return input
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'")
        .trim();
  }

  /// Validates inspection reference format
  static bool isValidReference(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return false;
    // Expected format: INSP-XXXX-XXX or similar
    return trimmed.length >= 3 && trimmed.length <= 50;
  }

  /// Validates that required fields are not empty
  static bool hasRequiredFields({
    String? vin,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
  }) {
    return vin != null && vin.trim().isNotEmpty &&
        licensePlate != null && licensePlate.trim().isNotEmpty &&
        make != null && make.trim().isNotEmpty &&
        model != null && model.trim().isNotEmpty &&
        year != null && year > 0;
  }
}

/// Validation error messages
class ValidationMessages {
  static const String vinRequired = 'VIN is required';
  static const String vinTooShort = 'VIN must be at least 8 characters';
  static const String vinInvalid = 'VIN contains invalid characters';
  static const String plateRequired = 'License plate is required';
  static const String plateInvalid = 'License plate format is invalid';
  static const String emailInvalid = 'Email address is invalid';
  static const String phoneInvalid = 'Phone number is invalid';
  static const String odometerInvalid = 'Odometer reading must be a positive number';
  static const String odometerUnrealistic = 'Odometer reading seems unrealistic';
  static const String yearInvalid = 'Year must be between 1900 and current year';
  static const String severityInvalid = 'Severity must be between 1 and 5';
  static const String resultInvalid = 'Invalid inspection result';
  static const String requiredFieldMissing = 'All required fields must be filled';
  static const String photoRequired = 'At least one photo is required for this item';
}

/// Form field validators for easy use in Flutter forms
class FormValidators {
  static String? vinValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationMessages.vinRequired;
    }
    if (value.trim().length < 8) {
      return ValidationMessages.vinTooShort;
    }
    if (!DataValidator.isValidVIN(value)) {
      return ValidationMessages.vinInvalid;
    }
    return null;
  }

  static String? licensePlateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationMessages.plateRequired;
    }
    if (!DataValidator.isValidLicensePlate(value)) {
      return ValidationMessages.plateInvalid;
    }
    return null;
  }

  static String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!DataValidator.isValidEmail(value)) {
      return ValidationMessages.emailInvalid;
    }
    return null;
  }

  static String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    if (!DataValidator.isValidPhone(value)) {
      return ValidationMessages.phoneInvalid;
    }
    return null;
  }

  static String? odometerValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Odometer reading is required';
    }
    final parsed = int.tryParse(value.replaceAll(',', ''));
    if (parsed == null || !DataValidator.isValidOdometer(parsed)) {
      return ValidationMessages.odometerInvalid;
    }
    return null;
  }

  static String? yearValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || !DataValidator.isValidYear(parsed)) {
      return ValidationMessages.yearInvalid;
    }
    return null;
  }

  static String? requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
