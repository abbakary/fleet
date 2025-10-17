import 'package:intl/intl.dart';
import 'models.dart';

class ReportGenerator {
  static String generateHtmlReport(InspectionDetailModel detail) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat.yMMMd().add_jm();
    final statusDisplay = detail.status.replaceAll('_', ' ').toUpperCase();
    final passCount = detail.responses.where((r) => r.result == 'pass').length;
    final failCount = detail.responses.where((r) => r.result == 'fail').length;
    final naCount = detail.responses.where((r) => r.result == 'not_applicable').length;

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<title>Inspection Report - ${detail.reference}</title>');
    buffer.writeln('<style>');
    buffer.writeln(_getCssStyles());
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Header
    buffer.writeln('<div class="header">');
    buffer.writeln('<h1>Fleet Inspection Report</h1>');
    buffer.writeln('<p class="report-date">Generated: ${dateFormat.format(DateTime.now())}</p>');
    buffer.writeln('</div>');

    // Inspection Summary
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Inspection Summary</h2>');
    buffer.writeln('<table class="info-table">');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Reference ID:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.reference)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Status:</strong></td>');
    buffer.writeln('<td><span class="status-badge status-${detail.status}">$statusDisplay</span></td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Created:</strong></td>');
    buffer.writeln('<td>${dateFormat.format(detail.createdAt)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('</table>');
    buffer.writeln('</div>');

    // Vehicle Information
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Vehicle Information</h2>');
    buffer.writeln('<table class="info-table">');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>License Plate:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.vehicle.licensePlate)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>VIN:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.vehicle.vin)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Make/Model:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.vehicle.make)} ${_escapeHtml(detail.vehicle.model)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Year:</strong></td>');
    buffer.writeln('<td>${detail.vehicle.year}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Type:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.vehicle.vehicleType)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Odometer:</strong></td>');
    buffer.writeln('<td>${detail.odometerReading} miles</td>');
    buffer.writeln('</tr>');
    buffer.writeln('</table>');
    buffer.writeln('</div>');

    // Customer Information
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Customer Information</h2>');
    buffer.writeln('<table class="info-table">');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Company:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.customer.legalName)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Email:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.customer.contactEmail)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Phone:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.customer.contactPhone)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('<tr>');
    buffer.writeln('<td><strong>Location:</strong></td>');
    buffer.writeln('<td>${_escapeHtml(detail.customer.city)}, ${_escapeHtml(detail.customer.state)} ${_escapeHtml(detail.customer.country)}</td>');
    buffer.writeln('</tr>');
    buffer.writeln('</table>');
    buffer.writeln('</div>');

    // Statistics
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Inspection Results Summary</h2>');
    buffer.writeln('<div class="stats-grid">');
    buffer.writeln('<div class="stat-card pass">');
    buffer.writeln('<div class="stat-value">$passCount</div>');
    buffer.writeln('<div class="stat-label">Passed</div>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="stat-card fail">');
    buffer.writeln('<div class="stat-value">$failCount</div>');
    buffer.writeln('<div class="stat-label">Failed</div>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="stat-card na">');
    buffer.writeln('<div class="stat-value">$naCount</div>');
    buffer.writeln('<div class="stat-label">N/A</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');

    // Detailed Findings
    buffer.writeln('<div class="section">');
    buffer.writeln('<h2>Detailed Inspection Findings</h2>');

    if (detail.responses.isEmpty) {
      buffer.writeln('<p class="no-data">No inspection items recorded.</p>');
    } else {
      for (final response in detail.responses) {
        final isFail = response.result == 'fail';
        buffer.writeln('<div class="finding-item ${isFail ? 'finding-fail' : ''}">');
        buffer.writeln('<h3>${_escapeHtml(response.checklistItem.title)}</h3>');

        if (response.checklistItem.description.isNotEmpty) {
          buffer.writeln('<p class="finding-description">${_escapeHtml(response.checklistItem.description)}</p>');
        }

        buffer.writeln('<div class="finding-details">');
        buffer.writeln('<span class="badge badge-${response.result}">${response.result.toUpperCase()}</span>');
        buffer.writeln('<span class="severity">Severity: ${response.severity}/5</span>');
        buffer.writeln('</div>');

        if (response.notes.isNotEmpty) {
          buffer.writeln('<div class="finding-notes">');
          buffer.writeln('<strong>Inspector Notes:</strong>');
          buffer.writeln('<p>${_escapeHtml(response.notes)}</p>');
          buffer.writeln('</div>');
        }

        buffer.writeln('</div>');
      }
    }

    buffer.writeln('</div>');

    // General Notes
    if (detail.generalNotes.isNotEmpty) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<h2>General Notes</h2>');
      buffer.writeln('<p>${_escapeHtml(detail.generalNotes)}</p>');
      buffer.writeln('</div>');
    }

    // Customer Report
    if (detail.customerReport != null) {
      buffer.writeln('<div class="section customer-report">');
      buffer.writeln('<h2>Customer Report</h2>');
      buffer.writeln('<p>${_escapeHtml(detail.customerReport!.summary)}</p>');
      if (detail.customerReport!.recommendedActions.isNotEmpty) {
        buffer.writeln('<h3>Recommended Actions</h3>');
        buffer.writeln('<p>${_escapeHtml(detail.customerReport!.recommendedActions)}</p>');
      }
      buffer.writeln('</div>');
    }

    // Footer
    buffer.writeln('<div class="footer">');
    buffer.writeln('<p>This report was automatically generated and contains confidential inspection information.</p>');
    buffer.writeln('</div>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  static String _getCssStyles() {
    return '''
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
      color: #333;
      background-color: #f5f5f5;
      padding: 20px;
    }
    
    .header {
      background: linear-gradient(135deg, #0EA5E9 0%, #6366F1 100%);
      color: white;
      padding: 40px 30px;
      border-radius: 8px;
      margin-bottom: 30px;
      text-align: center;
    }
    
    .header h1 {
      font-size: 2.5em;
      margin-bottom: 10px;
      font-weight: 700;
    }
    
    .report-date {
      font-size: 0.9em;
      opacity: 0.9;
    }
    
    .section {
      background: white;
      padding: 25px;
      margin-bottom: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }
    
    .section h2 {
      font-size: 1.5em;
      color: #1e40af;
      margin-bottom: 20px;
      padding-bottom: 10px;
      border-bottom: 2px solid #e5e7eb;
    }
    
    .section h3 {
      font-size: 1.1em;
      color: #333;
      margin: 15px 0 10px 0;
    }
    
    .info-table {
      width: 100%;
      border-collapse: collapse;
    }
    
    .info-table tr {
      border-bottom: 1px solid #e5e7eb;
    }
    
    .info-table tr:last-child {
      border-bottom: none;
    }
    
    .info-table td {
      padding: 12px;
    }
    
    .info-table td:first-child {
      width: 180px;
      font-weight: 500;
      color: #666;
    }
    
    .status-badge {
      display: inline-block;
      padding: 6px 12px;
      border-radius: 20px;
      font-weight: 600;
      font-size: 0.85em;
    }
    
    .status-submitted {
      background-color: #FED7AA;
      color: #92400e;
    }
    
    .status-approved {
      background-color: #D1FAE5;
      color: #065F46;
    }
    
    .status-rejected {
      background-color: #FEE2E2;
      color: #991B1B;
    }
    
    .status-in_progress {
      background-color: #DBEAFE;
      color: #1E40AF;
    }
    
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 20px;
      margin-top: 20px;
    }
    
    .stat-card {
      padding: 20px;
      border-radius: 8px;
      text-align: center;
      border: 2px solid #e5e7eb;
    }
    
    .stat-card.pass {
      border-color: #86efac;
      background-color: #f0fdf4;
    }
    
    .stat-card.fail {
      border-color: #fca5a5;
      background-color: #fef2f2;
    }
    
    .stat-card.na {
      border-color: #d1d5db;
      background-color: #f9fafb;
    }
    
    .stat-value {
      font-size: 2em;
      font-weight: 700;
      margin-bottom: 8px;
    }
    
    .stat-card.pass .stat-value {
      color: #16a34a;
    }
    
    .stat-card.fail .stat-value {
      color: #dc2626;
    }
    
    .stat-card.na .stat-value {
      color: #6b7280;
    }
    
    .stat-label {
      font-size: 0.9em;
      color: #666;
      font-weight: 500;
    }
    
    .finding-item {
      padding: 18px;
      margin-bottom: 15px;
      border-left: 4px solid #e5e7eb;
      background-color: #fafafa;
      border-radius: 4px;
    }
    
    .finding-item.finding-fail {
      border-left-color: #dc2626;
      background-color: #fef2f2;
    }
    
    .finding-item h3 {
      color: #1f2937;
      margin-bottom: 8px;
    }
    
    .finding-description {
      color: #666;
      font-size: 0.95em;
      margin-bottom: 12px;
    }
    
    .finding-details {
      display: flex;
      gap: 15px;
      margin-bottom: 12px;
      flex-wrap: wrap;
    }
    
    .badge {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 0.8em;
      font-weight: 600;
    }
    
    .badge-pass {
      background-color: #D1FAE5;
      color: #065F46;
    }
    
    .badge-fail {
      background-color: #FEE2E2;
      color: #991B1B;
    }
    
    .badge-not_applicable {
      background-color: #E5E7EB;
      color: #374151;
    }
    
    .severity {
      font-size: 0.9em;
      color: #666;
      padding: 2px 8px;
      background-color: #e5e7eb;
      border-radius: 4px;
    }
    
    .finding-notes {
      margin-top: 12px;
      padding: 12px;
      background-color: white;
      border-radius: 4px;
      border: 1px solid #e5e7eb;
    }
    
    .finding-notes strong {
      display: block;
      margin-bottom: 8px;
      color: #333;
    }
    
    .finding-notes p {
      color: #555;
      font-size: 0.95em;
      white-space: pre-wrap;
      word-break: break-word;
    }
    
    .customer-report {
      background-color: #f0f9ff;
      border-left: 4px solid #0284c7;
    }
    
    .no-data {
      text-align: center;
      color: #999;
      padding: 30px;
      font-style: italic;
    }
    
    .footer {
      text-align: center;
      color: #999;
      font-size: 0.85em;
      padding: 20px;
      margin-top: 40px;
      border-top: 1px solid #e5e7eb;
    }
    
    @media (max-width: 768px) {
      body {
        padding: 10px;
      }
      
      .header {
        padding: 20px;
      }
      
      .header h1 {
        font-size: 1.8em;
      }
      
      .section {
        padding: 15px;
      }
      
      .info-table td:first-child {
        width: 120px;
      }
      
      .stats-grid {
        grid-template-columns: 1fr;
      }
    }
    ''';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
