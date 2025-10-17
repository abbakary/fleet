import 'package:intl/intl.dart';
import 'models.dart';

/// Generates plain text reports that can be converted to PDF
class PdfReportGenerator {
  static String generateTextReport(InspectionDetailModel detail) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat.yMMMd().add_jm();
    final statusDisplay = detail.status.replaceAll('_', ' ').toUpperCase();
    final passCount = detail.responses.where((r) => r.result == 'pass').length;
    final failCount = detail.responses.where((r) => r.result == 'fail').length;
    final naCount = detail.responses.where((r) => r.result == 'not_applicable').length;

    // Header
    buffer.writeln('═' * 80);
    buffer.writeln('FLEET INSPECTION REPORT');
    buffer.writeln('═' * 80);
    buffer.writeln('Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('');

    // Inspection Summary
    buffer.writeln('INSPECTION SUMMARY');
    buffer.writeln('─' * 80);
    buffer.writeln('Reference ID:        ${detail.reference}');
    buffer.writeln('Status:              $statusDisplay');
    buffer.writeln('Created:             ${dateFormat.format(detail.createdAt)}');
    buffer.writeln('');

    // Vehicle Information
    buffer.writeln('VEHICLE INFORMATION');
    buffer.writeln('─' * 80);
    buffer.writeln('License Plate:       ${detail.vehicle.licensePlate}');
    buffer.writeln('VIN:                 ${detail.vehicle.vin}');
    buffer.writeln('Make/Model:          ${detail.vehicle.make} ${detail.vehicle.model}');
    buffer.writeln('Year:                ${detail.vehicle.year}');
    buffer.writeln('Type:                ${detail.vehicle.vehicleType}');
    buffer.writeln('Odometer:            ${detail.odometerReading} miles');
    buffer.writeln('');

    // Customer Information
    buffer.writeln('CUSTOMER INFORMATION');
    buffer.writeln('─' * 80);
    buffer.writeln('Company:             ${detail.customer.legalName}');
    buffer.writeln('Email:               ${detail.customer.contactEmail}');
    buffer.writeln('Phone:               ${detail.customer.contactPhone}');
    buffer.writeln('Location:            ${detail.customer.city}, ${detail.customer.state} ${detail.customer.country}');
    buffer.writeln('');

    // Results Summary
    buffer.writeln('INSPECTION RESULTS SUMMARY');
    buffer.writeln('─' * 80);
    buffer.writeln('Passed Items:        $passCount');
    buffer.writeln('Failed Items:        $failCount');
    buffer.writeln('N/A Items:           $naCount');
    buffer.writeln('Total Items:         ${detail.responses.length}');
    if (detail.responses.isNotEmpty) {
      final passPercentage = ((passCount / detail.responses.length) * 100).toStringAsFixed(1);
      buffer.writeln('Pass Rate:           $passPercentage%');
    }
    buffer.writeln('');

    // Detailed Findings
    buffer.writeln('DETAILED INSPECTION FINDINGS');
    buffer.writeln('═' * 80);

    if (detail.responses.isEmpty) {
      buffer.writeln('No inspection items recorded.');
    } else {
      for (int i = 0; i < detail.responses.length; i++) {
        final response = detail.responses[i];
        final itemNumber = i + 1;

        buffer.writeln('');
        buffer.writeln('Item $itemNumber: ${response.checklistItem.title}');
        buffer.writeln('─' * 80);

        if (response.checklistItem.description.isNotEmpty) {
          buffer.writeln('Description: ${response.checklistItem.description}');
        }

        buffer.writeln('Result:    ${response.result.toUpperCase()}');
        buffer.writeln('Severity:  ${response.severity}/5');

        if (response.notes.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('Inspector Notes:');
          buffer.writeln(_formatMultilineText(response.notes, indentation: 2));
        }

        if (response.photoPaths.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('Evidence Photos:   ${response.photoPaths.length} photo(s)');
          for (int j = 0; j < response.photoPaths.length; j++) {
            buffer.writeln('  ${j + 1}. ${response.photoPaths[j]}');
          }
        }
      }
    }

    buffer.writeln('');
    buffer.writeln('═' * 80);

    // General Notes
    if (detail.generalNotes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('GENERAL NOTES');
      buffer.writeln('─' * 80);
      buffer.writeln(_formatMultilineText(detail.generalNotes));
      buffer.writeln('');
    }

    // Customer Report
    if (detail.customerReport != null) {
      buffer.writeln('');
      buffer.writeln('CUSTOMER REPORT');
      buffer.writeln('─' * 80);
      buffer.writeln(_formatMultilineText(detail.customerReport!.summary));

      if (detail.customerReport!.recommendedActions.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Recommended Actions:');
        buffer.writeln(_formatMultilineText(detail.customerReport!.recommendedActions, indentation: 2));
      }

      if (detail.customerReport!.publishedAt != null) {
        buffer.writeln('');
        buffer.writeln('Published: ${dateFormat.format(detail.customerReport!.publishedAt!)}');
      }

      buffer.writeln('');
    }

    // Footer
    buffer.writeln('═' * 80);
    buffer.writeln('This report contains confidential inspection information.');
    buffer.writeln('Unauthorized distribution is prohibited.');
    buffer.writeln('═' * 80);

    return buffer.toString();
  }

  static String _formatMultilineText(String text, {int indentation = 0}) {
    final indent = ' ' * indentation;
    final lines = text.split('\n');
    return lines.map((line) => indent + line).join('\n');
  }
}
