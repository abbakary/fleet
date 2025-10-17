import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

class InspectionHeaderCard extends StatelessWidget {
  const InspectionHeaderCard({
    required this.reference,
    required this.vehicle,
    required this.customer,
    required this.status,
    required this.createdAt,
    this.odometerReading,
    super.key,
  });

  final String reference;
  final VehicleModel vehicle;
  final CustomerModel customer;
  final String status;
  final DateTime createdAt;
  final int? odometerReading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(status);
    final vehicleDisplay =
        vehicle.licensePlate.isNotEmpty ? '${vehicle.licensePlate} • ${vehicle.make} ${vehicle.model}' : vehicle.vin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reference: $reference', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(vehicleDisplay, style: theme.textTheme.bodyLarge),
                      Text('Customer: ${customer.legalName}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(DateFormat.yMMMd().add_jm().format(createdAt), style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (odometerReading != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Odometer', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text('$odometerReading mi', style: theme.textTheme.bodyMedium),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'submitted' => Colors.deepOrange,
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'in_progress' => Colors.blue,
      _ => Colors.grey,
    };
  }
}

class InspectionResponsesSection extends StatelessWidget {
  const InspectionResponsesSection({
    required this.responses,
    required this.resolveMediaUrl,
    this.showFindings = false,
    super.key,
  });

  final List<InspectionDetailItemModel> responses;
  final String Function(String) resolveMediaUrl;
  final bool showFindings;

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No inspection items recorded', style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Inspection Findings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        ...responses.map((response) => _InspectionResponseCard(
              response: response,
              resolveMediaUrl: resolveMediaUrl,
              showFindings: showFindings,
            )),
      ],
    );
  }
}

class _InspectionResponseCard extends StatelessWidget {
  const _InspectionResponseCard({
    required this.response,
    required this.resolveMediaUrl,
    required this.showFindings,
  });

  final InspectionDetailItemModel response;
  final String Function(String) resolveMediaUrl;
  final bool showFindings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhotos = response.photoPaths.isNotEmpty;
    final isFail = response.result == 'fail';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isFail ? theme.colorScheme.errorContainer.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(response.checklistItem.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (response.checklistItem.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            response.checklistItem.description,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFail ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    response.result.toUpperCase(),
                    style: TextStyle(
                      color: isFail ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.report_problem_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Severity: ${response.severity}/5', style: theme.textTheme.bodySmall),
              ],
            ),
            if (response.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Inspector Notes:', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(response.notes, style: theme.textTheme.bodySmall),
            ],
            if (hasPhotos) ...[
              const SizedBox(height: 12),
              Text('Evidence Photos', style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: response.photoPaths.length,
                  itemBuilder: (context, index) {
                    final url = resolveMediaUrl(response.photoPaths[index]);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 150,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 150,
                          height: 110,
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerReportSection extends StatelessWidget {
  const CustomerReportSection({required this.report, super.key});

  final CustomerReportModel report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Customer Report Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.summary, style: theme.textTheme.bodyMedium),
            if (report.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Recommended Actions:', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(report.recommendedActions, style: theme.textTheme.bodySmall),
            ],
            if (report.publishedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Published: ${DateFormat.yMMMd().add_jm().format(report.publishedAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GeneralNotesSection extends StatelessWidget {
  const GeneralNotesSection({required this.notes, super.key});

  final String notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General Notes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(notes, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class InspectionStatisticsSection extends StatelessWidget {
  const InspectionStatisticsSection({required this.responses, super.key});

  final List<InspectionDetailItemModel> responses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passCount = responses.where((r) => r.result == 'pass').length;
    final failCount = responses.where((r) => r.result == 'fail').length;
    final naCount = responses.where((r) => r.result == 'not_applicable').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'Passed', count: passCount, color: Colors.green),
                _StatItem(label: 'Failed', count: failCount, color: Colors.red),
                _StatItem(label: 'N/A', count: naCount, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
