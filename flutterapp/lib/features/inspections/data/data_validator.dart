import 'models.dart';

class InspectionDataValidator {
  /// Validates inspection detail model for completeness and data integrity
  static ValidationResult validateInspectionDetail(InspectionDetailModel detail) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate required fields
    if (detail.reference.isEmpty) {
      errors.add('Inspection reference is missing');
    }

    if (detail.vehicle.licensePlate.isEmpty && detail.vehicle.vin.isEmpty) {
      errors.add('Vehicle identification (license plate or VIN) is missing');
    }

    if (detail.customer.legalName.isEmpty) {
      errors.add('Customer information is missing');
    }

    // Validate responses
    if (detail.responses.isEmpty) {
      warnings.add('No inspection items recorded');
    }

    // Validate individual responses
    for (final response in detail.responses) {
      if (response.checklistItem.requiresPhoto && response.photoPaths.isEmpty) {
        warnings.add('${response.checklistItem.title} requires photo but none found');
      }

      if (response.result == 'fail' && response.notes.isEmpty) {
        warnings.add('${response.checklistItem.title} marked as failed but no notes provided');
      }

      if (response.severity < 1 || response.severity > 5) {
        warnings.add('Invalid severity level for ${response.checklistItem.title}');
      }
    }

    // Validate customer report if present
    if (detail.customerReport != null) {
      if (detail.customerReport!.summary.isEmpty) {
        warnings.add('Customer report summary is empty');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Sanitizes string data to prevent injection and ensure safe display
  static String sanitizeText(String text) {
    if (text.isEmpty) return '';

    // Remove null bytes and control characters
    final sanitized = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Trim whitespace
    return sanitized.trim();
  }

  /// Validates photo paths to ensure they're safe URLs
  static bool isValidPhotoPath(String path) {
    if (path.isEmpty) return false;

    // Check for common photo URL patterns
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        Uri.parse(path);
        return true;
      } catch (_) {
        return false;
      }
    }

    // Check for file paths
    if (path.startsWith('file://') || path.startsWith('/')) {
      return true;
    }

    return false;
  }

  /// Cleans vehicle information to ensure data consistency
  static VehicleModel cleanVehicleData(VehicleModel vehicle) {
    return VehicleModel(
      id: vehicle.id,
      licensePlate: sanitizeText(vehicle.licensePlate).toUpperCase(),
      vin: sanitizeText(vehicle.vin).toUpperCase(),
      make: sanitizeText(vehicle.make),
      model: sanitizeText(vehicle.model),
      year: vehicle.year > 1900 && vehicle.year <= DateTime.now().year ? vehicle.year : 0,
      vehicleType: sanitizeText(vehicle.vehicleType),
      mileage: vehicle.mileage >= 0 ? vehicle.mileage : 0,
      customerId: vehicle.customerId,
      customerName: vehicle.customerName != null ? sanitizeText(vehicle.customerName!) : null,
    );
  }

  /// Cleans customer information
  static CustomerModel cleanCustomerData(CustomerModel customer) {
    return CustomerModel(
      id: customer.id,
      legalName: sanitizeText(customer.legalName),
      contactEmail: sanitizeText(customer.contactEmail),
      contactPhone: sanitizeText(customer.contactPhone),
      city: sanitizeText(customer.city),
      state: sanitizeText(customer.state),
      country: sanitizeText(customer.country),
      profile: customer.profile,
    );
  }

  /// Cleans inspection response data
  static InspectionDetailItemModel cleanResponseData(InspectionDetailItemModel response) {
    // Validate and clean photo paths
    final cleanedPhotos = response.photoPaths.where(isValidPhotoPath).toList();

    return InspectionDetailItemModel(
      id: response.id,
      checklistItem: response.checklistItem,
      result: _validateResult(response.result),
      severity: response.severity.clamp(1, 5),
      notes: sanitizeText(response.notes),
      photoPaths: cleanedPhotos,
    );
  }

  /// Validates and normalizes inspection result
  static String _validateResult(String result) {
    const validResults = ['pass', 'fail', 'not_applicable'];
    final normalized = result.toLowerCase();
    return validResults.contains(normalized) ? normalized : 'pass';
  }

  /// Cleans entire inspection detail model
  static InspectionDetailModel cleanInspectionData(InspectionDetailModel detail) {
    return InspectionDetailModel(
      id: detail.id,
      reference: sanitizeText(detail.reference),
      vehicle: cleanVehicleData(detail.vehicle),
      customer: cleanCustomerData(detail.customer),
      status: detail.status.toLowerCase(),
      createdAt: detail.createdAt,
      odometerReading: detail.odometerReading >= 0 ? detail.odometerReading : 0,
      generalNotes: sanitizeText(detail.generalNotes),
      responses: detail.responses.map(cleanResponseData).toList(),
      inspectorId: detail.inspectorId,
      startedAt: detail.startedAt,
      completedAt: detail.completedAt,
      customerReport: detail.customerReport,
    );
  }
}

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ValidationResult:');
    buffer.writeln('  isValid: $isValid');
    if (errors.isNotEmpty) {
      buffer.writeln('  Errors:');
      for (final error in errors) {
        buffer.writeln('    - $error');
      }
    }
    if (warnings.isNotEmpty) {
      buffer.writeln('  Warnings:');
      for (final warning in warnings) {
        buffer.writeln('    - $warning');
      }
    }
    return buffer.toString();
  }
}
