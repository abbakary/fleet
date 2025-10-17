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
    final total = detail.responses.length;
    final passPercentage = total > 0 ? ((passCount / total) * 100).toStringAsFixed(1) : '0.0';

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
    buffer.writeln('<header class="report-header">');
    buffer.writeln('<h1>Fleet Inspection Report</h1>');
    buffer.writeln('<p class="generated-date">Generated: ${dateFormat.format(DateTime.now())}</p>');
    buffer.writeln('</header>');

    // Inspection Summary Section
    buffer.writeln('<section class="section">');
    buffer.writeln('<h2>Inspection Summary</h2>');
    buffer.writeln('<div class="info-grid">');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Reference ID</label>');
    buffer.writeln('<value>${_escapeHtml(detail.reference)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Status</label>');
    buffer.writeln('<value><span class="status-badge status-${detail.status}">$statusDisplay</span></value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Created Date</label>');
    buffer.writeln('<value>${dateFormat.format(detail.createdAt)}</value>');
    buffer.writeln('</div>');
    if (detail.completedAt != null) {
      buffer.writeln('<div class="info-item">');
      buffer.writeln('<label>Completed Date</label>');
      buffer.writeln('<value>${dateFormat.format(detail.completedAt!)}</value>');
      buffer.writeln('</div>');
    }
    buffer.writeln('</div>');
    buffer.writeln('</section>');

    // Vehicle Information Section
    buffer.writeln('<section class="section">');
    buffer.writeln('<h2>Vehicle Information</h2>');
    buffer.writeln('<div class="info-grid">');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>License Plate</label>');
    buffer.writeln('<value>${_escapeHtml(detail.vehicle.licensePlate.isNotEmpty ? detail.vehicle.licensePlate : 'N/A')}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>VIN</label>');
    buffer.writeln('<value>${_escapeHtml(detail.vehicle.vin)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Make & Model</label>');
    buffer.writeln('<value>${_escapeHtml(detail.vehicle.make)} ${_escapeHtml(detail.vehicle.model)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Year</label>');
    buffer.writeln('<value>${detail.vehicle.year}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Vehicle Type</label>');
    buffer.writeln('<value>${_escapeHtml(detail.vehicle.vehicleType)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Odometer Reading</label>');
    buffer.writeln('<value>${detail.odometerReading} miles</value>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    buffer.writeln('</section>');

    // Customer Information Section
    buffer.writeln('<section class="section">');
    buffer.writeln('<h2>Customer Information</h2>');
    buffer.writeln('<div class="info-grid">');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Company Name</label>');
    buffer.writeln('<value>${_escapeHtml(detail.customer.legalName)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Email</label>');
    buffer.writeln('<value>${_escapeHtml(detail.customer.contactEmail)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Phone</label>');
    buffer.writeln('<value>${_escapeHtml(detail.customer.contactPhone)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="info-item">');
    buffer.writeln('<label>Location</label>');
    buffer.writeln('<value>${_escapeHtml(detail.customer.city)}, ${_escapeHtml(detail.customer.state)} ${_escapeHtml(detail.customer.country)}</value>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    buffer.writeln('</section>');

    // Results Summary Section
    buffer.writeln('<section class="section">');
    buffer.writeln('<h2>Inspection Results Summary</h2>');
    buffer.writeln('<div class="stats-grid">');
    buffer.writeln('<div class="stat-card pass">');
    buffer.writeln('<div class="stat-value">$passCount</div>');
    buffer.writeln('<div class="stat-label">Passed Items</div>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="stat-card fail">');
    buffer.writeln('<div class="stat-value">$failCount</div>');
    buffer.writeln('<div class="stat-label">Failed Items</div>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="stat-card na">');
    buffer.writeln('<div class="stat-value">$naCount</div>');
    buffer.writeln('<div class="stat-label">N/A Items</div>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="stat-card rate">');
    buffer.writeln('<div class="stat-value">$passPercentage%</div>');
    buffer.writeln('<div class="stat-label">Pass Rate</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    if (total > 0) {
      final progressPercent = (passCount / total * 100).toStringAsFixed(0);
      buffer.writeln('<div class="progress-bar">');
      buffer.writeln('<div class="progress-fill" style="width: $progressPercent%"></div>');
      buffer.writeln('</div>');
    }
    buffer.writeln('</section>');

    // Detailed Findings Section
    if (detail.responses.isNotEmpty) {
      buffer.writeln('<section class="section">');
      buffer.writeln('<h2>Detailed Inspection Findings</h2>');

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

        buffer.writeln('<div class="category-section">');
        buffer.writeln('<h3 class="category-title">$category ${categoryFailCount > 0 ? '<span class="fail-badge">$categoryFailCount Issues</span>' : ''}</h3>');

        for (final response in items) {
          final isFail = response.result == 'fail';
          buffer.writeln('<div class="finding-item ${isFail ? 'finding-fail' : ''}">');
          buffer.writeln('<div class="finding-header">');
          buffer.writeln('<h4>${_escapeHtml(response.checklistItem.title)}</h4>');
          buffer.writeln('<span class="badge badge-${response.result}">${response.result.toUpperCase()}</span>');
          buffer.writeln('</div>');

          if (response.checklistItem.description.isNotEmpty) {
            buffer.writeln('<p class="finding-description">${_escapeHtml(response.checklistItem.description)}</p>');
          }

          buffer.writeln('<div class="finding-meta">');
          buffer.writeln('<span class="severity">Severity: ${response.severity}/5</span>');
          buffer.writeln('</div>');

          if (response.notes.isNotEmpty) {
            buffer.writeln('<div class="finding-notes">');
            buffer.writeln('<strong>Inspector Notes:</strong>');
            buffer.writeln('<p>${_escapeHtml(response.notes)}</p>');
            buffer.writeln('</div>');
          }

          if (response.photoPaths.isNotEmpty) {
            buffer.writeln('<div class="finding-photos">');
            buffer.writeln('<strong>Evidence Photos (${response.photoPaths.length}):</strong>');
            buffer.writeln('<ul class="photo-list">');
            for (int i = 0; i < response.photoPaths.length; i++) {
              buffer.writeln('<li>[Photo ${i + 1}] ${_escapeHtml(response.photoPaths[i])}</li>');
            }
            buffer.writeln('</ul>');
            buffer.writeln('</div>');
          }

          buffer.writeln('</div>');
        }

        buffer.writeln('</div>');
      }

      buffer.writeln('</section>');
    }

    // General Notes Section
    if (detail.generalNotes.isNotEmpty) {
      buffer.writeln('<section class="section">');
      buffer.writeln('<h2>General Notes</h2>');
      buffer.writeln('<div class="notes-box">');
      buffer.writeln('<p>${_escapeHtml(detail.generalNotes)}</p>');
      buffer.writeln('</div>');
      buffer.writeln('</section>');
    }

    // Customer Report Section
    if (detail.customerReport != null) {
      buffer.writeln('<section class="section customer-report-section">');
      buffer.writeln('<h2>Customer Report</h2>');
      buffer.writeln('<div class="customer-report">');
      buffer.writeln('<p class="report-summary">${_escapeHtml(detail.customerReport!.summary)}</p>');

      if (detail.customerReport!.recommendedActions.isNotEmpty) {
        buffer.writeln('<h3>Recommended Actions</h3>');
        buffer.writeln('<p>${_escapeHtml(detail.customerReport!.recommendedActions)}</p>');
      }

      if (detail.customerReport!.publishedAt != null) {
        buffer.writeln('<p class="report-date">Published: ${dateFormat.format(detail.customerReport!.publishedAt!)}</p>');
      }

      buffer.writeln('</div>');
      buffer.writeln('</section>');
    }

    // Footer
    buffer.writeln('<footer class="report-footer">');
    buffer.writeln('<p>This report contains confidential inspection information. Unauthorized distribution is prohibited.</p>');
    buffer.writeln('<p>Report ID: ${_escapeHtml(detail.reference)} | Generated: ${dateFormat.format(DateTime.now())}</p>');
    buffer.writeln('</footer>');

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
    
    .report-header {
      background: linear-gradient(135deg, #0EA5E9 0%, #6366F1 100%);
      color: white;
      padding: 40px 30px;
      border-radius: 8px;
      margin-bottom: 30px;
      text-align: center;
    }
    
    .report-header h1 {
      font-size: 2.5em;
      margin-bottom: 10px;
      font-weight: 700;
    }
    
    .generated-date {
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
      margin-top: 15px;
      margin-bottom: 10px;
    }
    
    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 20px;
      margin-bottom: 10px;
    }
    
    .info-item {
      border-left: 3px solid #0EA5E9;
      padding-left: 15px;
    }
    
    .info-item label {
      display: block;
      font-size: 0.85em;
      color: #666;
      font-weight: 500;
      margin-bottom: 5px;
    }
    
    .info-item value {
      display: block;
      font-size: 1em;
      color: #333;
      font-weight: 500;
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
      grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
      gap: 15px;
      margin-bottom: 20px;
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
    
    .stat-card.rate {
      border-color: #93c5fd;
      background-color: #eff6ff;
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
    
    .stat-card.rate .stat-value {
      color: #0ea5e9;
    }
    
    .stat-label {
      font-size: 0.9em;
      color: #666;
      font-weight: 500;
    }
    
    .progress-bar {
      width: 100%;
      height: 10px;
      background-color: #e5e7eb;
      border-radius: 5px;
      overflow: hidden;
    }
    
    .progress-fill {
      height: 100%;
      background: linear-gradient(90deg, #16a34a, #22c55e);
      transition: width 0.3s ease;
    }
    
    .category-section {
      margin-bottom: 20px;
      border-top: 1px solid #e5e7eb;
      padding-top: 15px;
    }
    
    .category-title {
      color: #1e40af;
      margin-bottom: 15px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .fail-badge {
      background-color: #FEE2E2;
      color: #991B1B;
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 0.85em;
      font-weight: 600;
    }
    
    .finding-item {
      padding: 16px;
      margin-bottom: 12px;
      border-left: 4px solid #e5e7eb;
      background-color: #fafafa;
      border-radius: 4px;
    }
    
    .finding-item.finding-fail {
      border-left-color: #dc2626;
      background-color: #fef2f2;
    }
    
    .finding-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 10px;
    }
    
    .finding-header h4 {
      color: #1f2937;
      margin: 0;
      flex: 1;
    }
    
    .badge {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 0.8em;
      font-weight: 600;
      margin-left: 10px;
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
    
    .finding-description {
      color: #666;
      font-size: 0.95em;
      margin-bottom: 10px;
    }
    
    .finding-meta {
      display: flex;
      gap: 15px;
      margin-bottom: 10px;
      flex-wrap: wrap;
    }
    
    .severity {
      font-size: 0.9em;
      color: #666;
      padding: 2px 8px;
      background-color: #e5e7eb;
      border-radius: 4px;
    }
    
    .finding-notes {
      margin-top: 10px;
      padding: 10px;
      background-color: white;
      border-radius: 4px;
      border: 1px solid #e5e7eb;
    }
    
    .finding-notes strong {
      display: block;
      margin-bottom: 6px;
      color: #333;
    }
    
    .finding-notes p {
      color: #555;
      font-size: 0.95em;
      white-space: pre-wrap;
      word-break: break-word;
    }
    
    .finding-photos {
      margin-top: 10px;
      padding: 10px;
      background-color: white;
      border-radius: 4px;
      border: 1px solid #e5e7eb;
    }
    
    .finding-photos strong {
      display: block;
      margin-bottom: 6px;
      color: #333;
    }
    
    .photo-list {
      margin-left: 20px;
      color: #666;
      font-size: 0.9em;
    }
    
    .photo-list li {
      margin-bottom: 4px;
      word-break: break-all;
    }
    
    .notes-box {
      padding: 15px;
      background-color: #f9f9f9;
      border-radius: 4px;
      border-left: 4px solid #0EA5E9;
    }
    
    .notes-box p {
      color: #555;
      white-space: pre-wrap;
      word-break: break-word;
    }
    
    .customer-report-section {
      background-color: #f0f9ff;
      border-left: 4px solid #0284c7;
    }
    
    .customer-report {
      padding: 15px;
      background-color: white;
      border-radius: 4px;
    }
    
    .report-summary {
      font-style: italic;
      color: #555;
      margin-bottom: 15px;
    }
    
    .report-date {
      font-size: 0.9em;
      color: #999;
      margin-top: 10px;
    }
    
    .report-footer {
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
      
      .report-header {
        padding: 20px;
      }
      
      .report-header h1 {
        font-size: 1.8em;
      }
      
      .section {
        padding: 15px;
      }
      
      .info-grid {
        grid-template-columns: 1fr;
      }
      
      .stats-grid {
        grid-template-columns: repeat(2, 1fr);
      }
      
      .finding-header {
        flex-direction: column;
      }
      
      .badge {
        margin-left: 0;
        margin-top: 8px;
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
