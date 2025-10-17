import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

/// Inspection timeline showing the lifecycle of an inspection
class InspectionTimeline extends StatelessWidget {
  const InspectionTimeline({
    required this.inspection,
    super.key,
  });

  final InspectionDetailModel inspection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd().add_jm();

    final events = _buildTimelineEvents();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline),
                const SizedBox(width: 8),
                Text(
                  'Inspection Timeline',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == events.length - 1;

              return _TimelineEvent(
                icon: event.icon,
                title: event.title,
                description: event.description,
                timestamp: event.timestamp,
                isCompleted: event.isCompleted,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_TimelineEventData> _buildTimelineEvents() {
    final events = <_TimelineEventData>[
      _TimelineEventData(
        icon: Icons.assignment,
        title: 'Inspection Created',
        description: 'Inspection record created in the system',
        timestamp: inspection.createdAt,
        isCompleted: true,
      ),
    ];

    if (inspection.startedAt != null) {
      events.add(
        _TimelineEventData(
          icon: Icons.play_circle_outline,
          title: 'Inspection Started',
          description: 'Inspector began the inspection process',
          timestamp: inspection.startedAt!,
          isCompleted: true,
        ),
      );
    }

    // Add status transitions
    if (inspection.status == 'submitted' || inspection.status == 'approved' || inspection.status == 'rejected') {
      events.add(
        _TimelineEventData(
          icon: Icons.check_circle_outline,
          title: 'Inspection Submitted',
          description: 'Inspector submitted the completed inspection',
          timestamp: inspection.completedAt ?? DateTime.now(),
          isCompleted: true,
        ),
      );
    }

    if (inspection.status == 'approved') {
      events.add(
        _TimelineEventData(
          icon: Icons.verified,
          title: 'Inspection Approved',
          description: 'Inspection has been reviewed and approved',
          timestamp: inspection.completedAt ?? DateTime.now(),
          isCompleted: true,
        ),
      );
    }

    if (inspection.status == 'rejected') {
      events.add(
        _TimelineEventData(
          icon: Icons.cancel_outlined,
          title: 'Inspection Rejected',
          description: 'Inspection was rejected and requires revision',
          timestamp: inspection.completedAt ?? DateTime.now(),
          isCompleted: true,
        ),
      );
    }

    // Add customer report milestone if available
    if (inspection.customerReport?.publishedAt != null) {
      events.add(
        _TimelineEventData(
          icon: Icons.description,
          title: 'Report Published',
          description: 'Customer report was published and made available',
          timestamp: inspection.customerReport!.publishedAt!,
          isCompleted: true,
        ),
      );
    }

    return events;
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.icon,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surfaceVariant,
                    border: Border.all(
                      color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Event content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFormat.format(timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }
}

class _TimelineEventData {
  _TimelineEventData({
    required this.icon,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
  });

  final IconData icon;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;
}
