import 'dart:convert';
import 'package:intl/intl.dart';
import 'models.dart';

/// Handles exporting inspection data to various formats
class InspectionExporter {
  // Private constructor
  InspectionExporter._();

  /// Export inspection to CSV format
  static String exportToCSV(InspectionDetailModel inspection) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat.yMMMd().add_jm();

    // Header
    buffer.writeln('Fleet Inspection Export - CSV');
    buffer.writeln('Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('');

    // Inspection Summary
    buffer.writeln('INSPECTION SUMMARY');
    buffer.writeln('Reference ID,Status,Created Date,Completed Date');
    buffer.writeln('${_escapeCsv(inspection.reference)},${inspection.status},'
        '${dateFormat.format(inspection.createdAt)},'
        '${inspection.completedAt != null ? dateFormat.format(inspection.completedAt!) : "N/A"}');
    buffer.writeln('');

    // Vehicle Information
    buffer.writeln('VEHICLE INFORMATION');
    buffer.writeln('License Plate,VIN,Make,Model,Year,Type,Odometer');
    buffer.writeln('${_escapeCsv(inspection.vehicle.licensePlate)},'
        '${_escapeCsv(inspection.vehicle.vin)},'
        '${_escapeCsv(inspection.vehicle.make)},'
        '${_escapeCsv(inspection.vehicle.model)},'
        '${inspection.vehicle.year},'
        '${_escapeCsv(inspection.vehicle.vehicleType)},'
        '${inspection.odometerReading}');
    buffer.writeln('');

    // Customer Information
    buffer.writeln('CUSTOMER INFORMATION');
    buffer.writeln('Company Name,Email,Phone,City,State,Country');
    buffer.writeln('${_escapeCsv(inspection.customer.legalName)},'
        '${_escapeCsv(inspection.customer.contactEmail)},'
        '${_escapeCsv(inspection.customer.contactPhone)},'
        '${_escapeCsv(inspection.customer.city)},'
        '${_escapeCsv(inspection.customer.state)},'
        '${_escapeCsv(inspection.customer.country)}');
    buffer.writeln('');

    // Results Summary
    final passCount = inspection.responses.where((r) => r.result == 'pass').length;
    final failCount = inspection.responses.where((r) => r.result == 'fail').length;
    final naCount = inspection.responses.where((r) => r.result == 'not_applicable').length;
    buffer.writeln('RESULTS SUMMARY');
    buffer.writeln('Passed,Failed,Not Applicable,Total');
    buffer.writeln('$passCount,$failCount,$naCount,${inspection.responses.length}');
    buffer.writeln('');

    // Detailed Findings
    if (inspection.responses.isNotEmpty) {
      buffer.writeln('DETAILED FINDINGS');
      buffer.writeln('Category,Item Title,Result,Severity,Notes');

      for (final response in inspection.responses) {
        buffer.writeln('${_escapeCsv(response.checklistItem.categoryName)},'
            '${_escapeCsv(response.checklistItem.title)},'
            '${response.result},'
            '${response.severity},'
            '${_escapeCsv(response.notes)}');
      }
      buffer.writeln('');
    }

    // General Notes
    if (inspection.generalNotes.isNotEmpty) {
      buffer.writeln('GENERAL NOTES');
      buffer.writeln(_escapeCsv(inspection.generalNotes));
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Export inspection to JSON format
  static String exportToJSON(InspectionDetailModel inspection) {
    final data = {
      'inspection': {
        'id': inspection.id,
        'reference': inspection.reference,
        'status': inspection.status,
        'created_at': inspection.createdAt.toIso8601String(),
        'completed_at': inspection.completedAt?.toIso8601String(),
        'odometer_reading': inspection.odometerReading,
        'general_notes': inspection.generalNotes,
      },
      'vehicle': {
        'id': inspection.vehicle.id,
        'license_plate': inspection.vehicle.licensePlate,
        'vin': inspection.vehicle.vin,
        'make': inspection.vehicle.make,
        'model': inspection.vehicle.model,
        'year': inspection.vehicle.year,
        'type': inspection.vehicle.vehicleType,
        'mileage': inspection.vehicle.mileage,
      },
      'customer': {
        'id': inspection.customer.id,
        'legal_name': inspection.customer.legalName,
        'email': inspection.customer.contactEmail,
        'phone': inspection.customer.contactPhone,
        'city': inspection.customer.city,
        'state': inspection.customer.state,
        'country': inspection.customer.country,
      },
      'findings': inspection.responses
          .map((response) => {
                'id': response.id,
                'category': response.checklistItem.categoryName,
                'title': response.checklistItem.title,
                'description': response.checklistItem.description,
                'result': response.result,
                'severity': response.severity,
                'notes': response.notes,
                'photo_count': response.photoPaths.length,
              })
          .toList(),
      'summary': {
        'total_items': inspection.responses.length,
        'passed': inspection.responses.where((r) => r.result == 'pass').length,
        'failed': inspection.responses.where((r) => r.result == 'fail').length,
        'not_applicable': inspection.responses.where((r) => r.result == 'not_applicable').length,
      },
    };

    if (inspection.customerReport != null) {
      data['customer_report'] = {
        'summary': inspection.customerReport!.summary,
        'recommended_actions': inspection.customerReport!.recommendedActions,
        'published_at': inspection.customerReport!.publishedAt?.toIso8601String(),
      };
    }

    return jsonEncode(data);
  }

  /// Export multiple inspections to CSV
  static String exportMultipleToCSV(List<InspectionDetailModel> inspections) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat.yMMMd().add_jm();

    buffer.writeln('Fleet Inspection Batch Export - CSV');
    buffer.writeln('Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('Total Inspections: ${inspections.length}');
    buffer.writeln('');

    buffer.writeln('Reference,Status,Vehicle,Customer,Created Date,Pass Rate');

    for (final inspection in inspections) {
      final passCount = inspection.responses.where((r) => r.result == 'pass').length;
      final total = inspection.responses.length;
      final passRate = total > 0 ? ((passCount / total) * 100).toStringAsFixed(1) : '0.0';

      final vehicleDisplay =
          '${inspection.vehicle.licensePlate.isNotEmpty ? inspection.vehicle.licensePlate : inspection.vehicle.vin}';
      final customerName = inspection.customer.legalName;

      buffer.writeln('${_escapeCsv(inspection.reference)},'
          '${inspection.status},'
          '${_escapeCsv(vehicleDisplay)},'
          '${_escapeCsv(customerName)},'
          '${DateFormat.yMMMMd().format(inspection.createdAt)},'
          '$passRate%');
    }

    return buffer.toString();
  }

  /// Generate inspection summary report
  static String generateSummaryReport(InspectionDetailModel inspection) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat.yMMMd().add_jm();

    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('INSPECTION SUMMARY REPORT');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Report Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('');

    buffer.writeln('QUICK FACTS:');
    buffer.writeln('  Reference ID: ${inspection.reference}');
    buffer.writeln('  Status: ${inspection.status}');
    buffer.writeln('  Vehicle: ${inspection.vehicle.make} ${inspection.vehicle.model} (${inspection.vehicle.year})');
    buffer.writeln('  License Plate: ${inspection.vehicle.licensePlate}');
    buffer.writeln('  Customer: ${inspection.customer.legalName}');
    buffer.writeln('  Inspection Date: ${dateFormat.format(inspection.createdAt)}');
    buffer.writeln('');

    final passCount = inspection.responses.where((r) => r.result == 'pass').length;
    final failCount = inspection.responses.where((r) => r.result == 'fail').length;
    final naCount = inspection.responses.where((r) => r.result == 'not_applicable').length;
    final total = inspection.responses.length;
    final passRate = total > 0 ? ((passCount / total) * 100).toStringAsFixed(1) : '0.0';

    buffer.writeln('INSPECTION RESULTS:');
    buffer.writeln('  Total Items: $total');
    buffer.writeln('  Passed: $passCount');
    buffer.writeln('  Failed: $failCount');
    buffer.writeln('  Not Applicable: $naCount');
    buffer.writeln('  Pass Rate: $passRate%');
    buffer.writeln('');

    if (failCount > 0) {
      buffer.writeln('FAILED ITEMS:');
      for (final response in inspection.responses.where((r) => r.result == 'fail')) {
        buffer.writeln('  • ${response.checklistItem.title} (Severity: ${response.severity}/5)');
      }
      buffer.writeln('');
    }

    if (inspection.generalNotes.isNotEmpty) {
      buffer.writeln('NOTES:');
      buffer.writeln(inspection.generalNotes);
      buffer.writeln('');
    }

    buffer.writeln('═══════════════════════════════════════════════════════');

    return buffer.toString();
  }

  /// Escape CSV values to handle commas and quotes
  static String _escapeCsv(String value) {
    if (value.isEmpty) return '""';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Export file helper
class ExportFileHelper {
  // Private constructor
  ExportFileHelper._();

  /// Generate filename for export
  static String generateFilename({
    required String reference,
    required String format,
    DateTime? date,
  }) {
    final timestamp = date ?? DateTime.now();
    final formattedDate = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    return 'inspection_${reference}_$formattedDate.$format';
  }

  /// Get MIME type for format
  static String getMimeType(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
