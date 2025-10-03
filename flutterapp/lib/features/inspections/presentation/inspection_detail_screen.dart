import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/inspections_repository.dart';
import '../data/models.dart';

class InspectionDetailScreen extends StatefulWidget {
  const InspectionDetailScreen({required this.summary, super.key});

  final InspectionSummaryModel summary;

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  Future<InspectionDetailModel>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<InspectionDetailModel> _load() async {
    final repo = context.read<InspectionsRepository>();
    return repo.fetchInspectionDetail(widget.summary.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Details'),
      ),
      body: SafeArea(
        child: FutureBuilder<InspectionDetailModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Failed to load inspection.'));
            }
            final detail = snapshot.data!;
            return _DetailView(detail: detail);
          },
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.detail});

  final InspectionDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<InspectionsRepository>();
    final date = DateFormat.yMMMd().add_jm().format(detail.createdAt);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.customerReport != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(detail.customerReport!.summary),
                  if (detail.customerReport!.recommendedActions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Recommended actions', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(detail.customerReport!.recommendedActions),
                  ],
                  if (detail.customerReport!.publishedAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Published: ${DateFormat.yMMMd().add_jm().format(detail.customerReport!.publishedAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reference: ${detail.reference}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Vehicle: ${detail.vehicle.licensePlate.isNotEmpty ? detail.vehicle.licensePlate : detail.vehicle.vin}'),
                Text('Customer: ${detail.customer.legalName}'),
                Text('Odometer: ${detail.odometerReading} mi'),
                Text('Status: ${detail.status.replaceAll('_', ' ')}'),
                Text('Created: $date'),
                if (detail.generalNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${detail.generalNotes}')
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...detail.responses.map((r) => _ResponseCard(response: r, resolve: repo.resolveMediaUrl)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response, required this.resolve});

  final InspectionDetailItemModel response;
  final String Function(String) resolve;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = response.photoPaths.isNotEmpty;
    final hasFailure = response.result == 'fail';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(response.checklistItem.title, style: Theme.of(context).textTheme.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasFailure ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    response.result.toUpperCase(),
                    style: TextStyle(
                      color: hasFailure ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (response.checklistItem.description.isNotEmpty)
              Text(
                response.checklistItem.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.report, size: 16),
                const SizedBox(width: 6),
                Text('Severity: ${response.severity}')
              ],
            ),
            if (response.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${response.notes}')
            ],
            if (hasPhotos) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: response.photoPaths.length,
                  itemBuilder: (context, index) {
                    final url = resolve(response.photoPaths[index]);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, width: 150, height: 110, fit: BoxFit.cover),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
