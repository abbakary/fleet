import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import 'photo_gallery_widget.dart';

/// Organized inspection summary card showing key details
class InspectionSummaryCard extends StatelessWidget {
  const InspectionSummaryCard({
    required this.reference,
    required this.vehicle,
    required this.customer,
    required this.status,
    required this.createdAt,
    required this.inspector,
    super.key,
  });

  final String reference;
  final VehicleModel vehicle;
  final CustomerModel customer;
  final String status;
  final DateTime createdAt;
  final InspectorProfileModel? inspector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with reference and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reference: $reference',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('Status', style: theme.textTheme.labelSmall),
                      Text(
                        status.replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Two-column info layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.licensePlate.isNotEmpty ? vehicle.licensePlate : 'N/A'} • ${vehicle.make} ${vehicle.model}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('VIN', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(vehicle.vin.isNotEmpty ? vehicle.vin : 'N/A', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(customer.legalName, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Text('Created', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (inspector != null) ...[
              const SizedBox(height: 16),
              Text('Inspector', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(inspector!.profile.fullName, style: theme.textTheme.bodyMedium),
            ],
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

  IconData _statusIcon(String status) {
    return switch (status) {
      'submitted' => Icons.check_circle_outline,
      'approved' => Icons.verified,
      'rejected' => Icons.cancel_outlined,
      'in_progress' => Icons.hourglass_bottom,
      _ => Icons.info_outline,
    };
  }
}

/// Inspection progress and statistics
class InspectionProgressSection extends StatelessWidget {
  const InspectionProgressSection({
    required this.responses,
    super.key,
  });

  final List<InspectionDetailItemModel> responses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passCount = responses.where((r) => r.result == 'pass').length;
    final failCount = responses.where((r) => r.result == 'fail').length;
    final naCount = responses.where((r) => r.result == 'not_applicable').length;
    final total = responses.length;
    final passPercentage = total > 0 ? ((passCount / total) * 100).toStringAsFixed(1) : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inspection Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatWidget(
                  icon: Icons.check_circle,
                  label: 'Passed',
                  value: passCount.toString(),
                  color: Colors.green,
                ),
                _StatWidget(
                  icon: Icons.cancel,
                  label: 'Failed',
                  value: failCount.toString(),
                  color: Colors.red,
                ),
                _StatWidget(
                  icon: Icons.help,
                  label: 'N/A',
                  value: naCount.toString(),
                  color: Colors.grey,
                ),
                _StatWidget(
                  icon: Icons.trending_up,
                  label: 'Pass Rate',
                  value: '$passPercentage%',
                  color: Colors.blue,
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: passCount / total,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  const _StatWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// Organized section for inspection findings grouped by category
class InspectionFindingsByCategorySection extends StatelessWidget {
  const InspectionFindingsByCategorySection({
    required this.responses,
    required this.resolveMediaUrl,
    super.key,
  });

  final List<InspectionDetailItemModel> responses;
  final String Function(String) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No inspection items recorded',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Group by category
    final grouped = <String, List<InspectionDetailItemModel>>{};
    for (final response in responses) {
      final category = response.checklistItem.categoryName;
      grouped.putIfAbsent(category, () => []).add(response);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Inspection Findings by Category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ...grouped.entries.map((entry) {
          final category = entry.key;
          final items = entry.value;
          return _CategorySection(
            category: category,
            items: items,
            resolveMediaUrl: resolveMediaUrl,
          );
        }),
      ],
    );
  }
}

class _CategorySection extends StatefulWidget {
  const _CategorySection({
    required this.category,
    required this.items,
    required this.resolveMediaUrl,
  });

  final String category;
  final List<InspectionDetailItemModel> items;
  final String Function(String) resolveMediaUrl;

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failCount = widget.items.where((r) => r.result == 'fail').length;
    final hasFailures = failCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.items.length} items',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (hasFailures)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$failCount failed',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.items
                    .map((response) => _FindingItem(
                          response: response,
                          resolveMediaUrl: widget.resolveMediaUrl,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _FindingItem extends StatelessWidget {
  const _FindingItem({
    required this.response,
    required this.resolveMediaUrl,
  });

  final InspectionDetailItemModel response;
  final String Function(String) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFail = response.result == 'fail';
    final hasPhotos = response.photoPaths.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFail ? theme.colorScheme.errorContainer.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFail ? theme.colorScheme.error.withOpacity(0.3) : theme.colorScheme.outlineVariant,
          ),
        ),
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
                      Text(
                        response.checklistItem.title,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (response.checklistItem.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          response.checklistItem.description,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFail ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    response.result.toUpperCase(),
                    style: TextStyle(
                      color: isFail ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Severity: ${response.severity}/5',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (response.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inspector Notes', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(response.notes, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            if (hasPhotos) ...[
              const SizedBox(height: 8),
              PhotoGallery(
                photoUrls: response.photoPaths.map(resolveMediaUrl).toList(),
                maxCrossAxisCount: 3,
                onImageTap: (index, url) {
                  PhotoViewerDialog.show(
                    context,
                    photoUrls: response.photoPaths.map(resolveMediaUrl).toList(),
                    initialIndex: index,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section for customer comments/interaction
class CommentsSection extends StatelessWidget {
  const CommentsSection({
    required this.inspectorName,
    required this.comments,
    super.key,
  });

  final String inspectorName;
  final List<Map<String, String>> comments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment_outlined),
                const SizedBox(width: 8),
                Text('Comments & Notes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            if (comments.isEmpty)
              Text(
                'No comments yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              ...comments.map((comment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(comment['author'] ?? 'Unknown', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text(comment['date'] ?? '', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment['text'] ?? '', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
