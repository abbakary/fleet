import 'package:intl/intl.dart';
import 'models.dart';

/// Generates plain text reports optimized for PDF conversion
class PdfReportGenerator {
  static String generateTextReport(InspectionDetailModel detail) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat.yMMMd().add_jm();
    final statusDisplay = detail.status.replaceAll('_', ' ').toUpperCase();
    final passCount = detail.responses.where((r) => r.result == 'pass').length;
    final failCount = detail.responses.where((r) => r.result == 'fail').length;
    final naCount = detail.responses.where((r) => r.result == 'not_applicable').length;
    final total = detail.responses.length;
    final passPercentage = total > 0 ? ((passCount / total) * 100).toStringAsFixed(1) : '0.0';

    // Main header
    buffer.writeln('╔═══════════════════════════════════════════════════════════════════════════════╗');
    buffer.writeln('║                    FLEET INSPECTION REPORT                                    ║');
    buffer.writeln('╚═══════════════════════════════════════════════════════════════════════════════╝');
    buffer.writeln('');
    buffer.writeln('Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('');

    // Inspection Summary
    buffer.writeln('┌─ INSPECTION SUMMARY ─────────────────────────────────────────────────────────┐');
    buffer.writeln('│');
    buffer.writeln('│  Reference ID:  ${detail.reference}');
    buffer.writeln('│  Status:        $statusDisplay');
    buffer.writeln('│  Created:       ${dateFormat.format(detail.createdAt)}');
    if (detail.completedAt != null) {
      buffer.writeln('│  Completed:     ${dateFormat.format(detail.completedAt!)}');
    }
    buffer.writeln('│');
    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────────┘');
    buffer.writeln('');

    // Vehicle Information
    buffer.writeln('┌─ VEHICLE INFORMATION ────────────────────────────────────────────────────────┐');
    buffer.writeln('│');
    buffer.writeln('│  License Plate:  ${detail.vehicle.licensePlate.isNotEmpty ? detail.vehicle.licensePlate : 'N/A'}');
    buffer.writeln('│  VIN:            ${detail.vehicle.vin}');
    buffer.writeln('│  Make & Model:   ${detail.vehicle.make} ${detail.vehicle.model}');
    buffer.writeln('│  Year:           ${detail.vehicle.year}');
    buffer.writeln('│  Type:           ${detail.vehicle.vehicleType}');
    buffer.writeln('│  Odometer:       ${detail.odometerReading} miles');
    buffer.writeln('│');
    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────────┘');
    buffer.writeln('');

    // Customer Information
    buffer.writeln('┌─ CUSTOMER INFORMATION ───────────────────────────────────────────────────────┐');
    buffer.writeln('│');
    buffer.writeln('│  Company:        ${detail.customer.legalName}');
    buffer.writeln('│  Email:          ${detail.customer.contactEmail}');
    buffer.writeln('│  Phone:          ${detail.customer.contactPhone}');
    buffer.writeln('│  Location:       ${detail.customer.city}, ${detail.customer.state} ${detail.customer.country}');
    buffer.writeln('│');
    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────────┘');
    buffer.writeln('');

    // Results Summary
    buffer.writeln('┌─ INSPECTION RESULTS SUMMARY ─────────────────────────────────────────────────┐');
    buffer.writeln('│');
    buffer.writeln('│  Passed Items:    $passCount');
    buffer.writeln('│  Failed Items:    $failCount');
    buffer.writeln('│  N/A Items:       $naCount');
    buffer.writeln('│  Total Items:     $total');
    buffer.writeln('│  Pass Rate:       $passPercentage%');
    buffer.writeln('│');
    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────────┘');
    buffer.writeln('');

    // Detailed Findings
    if (detail.responses.isNotEmpty) {
      buffer.writeln('╔═══════════════════════════════════════════════════════════════════════════════╗');
      buffer.writeln('║                       DETAILED INSPECTION FINDINGS                           ║');
      buffer.writeln('╚═══════════════════════════════════════════════��═══════════════════════════════╝');
      buffer.writeln('');

      // Group findings by category
      final grouped = <String, List<InspectionDetailItemModel>>{};
      for (final response in detail.responses) {
        final category = response.checklistItem.categoryName;
        grouped.putIfAbsent(category, () => []).add(response);
      }

      for (final entry in grouped.entries) {
        final category = entry.key;
        final items = entry.value;
        final categoryFailCount = items.where((r) => r.result == 'fail').length;

        buffer.writeln('');
        buffer.writeln('─ $category ${categoryFailCount > 0 ? '[$categoryFailCount Issues]' : ''}');
        buffer.writeln('');

        for (int idx = 0; idx < items.length; idx++) {
          final response = items[idx];
          final itemNum = idx + 1;

          buffer.writeln('$itemNum. ${response.checklistItem.title}');
          buffer.writeln('   Status: ${response.result.toUpperCase()}');
          buffer.writeln('   Severity: ${response.severity}/5');

          if (response.checklistItem.description.isNotEmpty) {
            buffer.writeln('   Description: ${response.checklistItem.description}');
          }

          if (response.notes.isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('   Inspector Notes:');
            for (final line in response.notes.split('\n')) {
              buffer.writeln('   > $line');
            }
          }

          if (response.photoPaths.isNotEmpty) {
            buffer.writeln('');
            buffer.writeln('   Evidence Photos: ${response.photoPaths.length}');
            for (int photoIdx = 0; photoIdx < response.photoPaths.length; photoIdx++) {
              buffer.writeln('   [Photo ${photoIdx + 1}] ${response.photoPaths[photoIdx]}');
            }
          }

          buffer.writeln('');
        }
      }
    }

    // General Notes
    if (detail.generalNotes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('╔═══════════════════════════════════════════════════════════════════════════════╗');
      buffer.writeln('║                          GENERAL NOTES                                      ║');
      buffer.writeln('╚══════════════════════════════════════════════════════════════���════════════════╝');
      buffer.writeln('');
      for (final line in detail.generalNotes.split('\n')) {
        buffer.writeln(line);
      }
      buffer.writeln('');
    }

    // Customer Report
    if (detail.customerReport != null) {
      buffer.writeln('');
      buffer.writeln('╔═══════════════════════════════════════════════════════════════════════════════╗');
      buffer.writeln('║                         CUSTOMER REPORT                                     ║');
      buffer.writeln('╚═══════════════════════════════════════════════════════════════════════════════╝');
      buffer.writeln('');
      buffer.writeln('Summary:');
      buffer.writeln(detail.customerReport!.summary);

      if (detail.customerReport!.recommendedActions.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Recommended Actions:');
        buffer.writeln(detail.customerReport!.recommendedActions);
      }

      if (detail.customerReport!.publishedAt != null) {
        buffer.writeln('');
        buffer.writeln('Published: ${dateFormat.format(detail.customerReport!.publishedAt!)}');
      }

      buffer.writeln('');
    }

    // Footer
    buffer.writeln('');
    buffer.writeln('╔═══════════════════════════════════════════════════════════════════════════════╗');
    buffer.writeln('║  This report contains confidential inspection information.                   ║');
    buffer.writeln('║  Unauthorized distribution is prohibited.                                    ║');
    buffer.writeln('║                                                                               ║');
    buffer.writeln('║  Report ID: ${detail.reference}');
    buffer.writeln('║  Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('╚═══════════════════════════════════════════════════════════════════════════════╝');

    return buffer.toString();
  }
}
