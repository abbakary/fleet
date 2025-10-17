import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/animated_background.dart';
import '../../../core/ui/language_menu.dart';
import '../data/inspections_repository.dart';
import '../data/models.dart';
import 'controllers/customer_dashboard_controller.dart';
import 'inspection_detail_screen.dart';

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({required this.inspection, required this.onTap});

  final InspectionSummaryModel inspection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(inspection.status);
    final statusIcon = _statusIcon(inspection.status);
    final vehicleDisplay = inspection.vehicle.licensePlate.isNotEmpty
        ? '${inspection.vehicle.licensePlate} • ${inspection.vehicle.make} ${inspection.vehicle.model}'
        : inspection.vehicle.vin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with vehicle and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleDisplay,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inspection ID: ${inspection.reference}',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Status and date info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        inspection.statusDisplay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Created', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(inspection.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('View Report'),
                ),
              ),
            ],
          ),
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

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({required this.profile, super.key});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerDashboardController(
        repository: context.read<InspectionsRepository>(),
      )..loadDashboard(),
      child: _CustomerHomeView(profile: profile),
    );
  }
}

class _CustomerHomeView extends StatelessWidget {
  const _CustomerHomeView({required this.profile});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerDashboardController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Customer • ${profile.organization.isNotEmpty ? profile.organization : profile.fullName}',
            ),
            actions: const [LanguageMenu()],
          ),
          body: Stack(
            children: [
              const TopWaves(),
              const AnimatedParticlesBackground(),
              SafeArea(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: controller.refresh,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          children: [
                            if (controller.error != null)
                              Card(
                                color: Theme.of(context).colorScheme.errorContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    controller.error ?? '',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                            Text('Your vehicles', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            if (controller.vehicles.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No vehicles registered.'),
                                ),
                              )
                            else
                              ...controller.vehicles.map(
                                (v) => Card(
                                  child: ListTile(
                                    title: Text(
                                      v.licensePlate.isNotEmpty
                                          ? '${v.licensePlate} • ${v.make} ${v.model}'
                                          : v.vin,
                                    ),
                                    subtitle: Text(
                                      'Type: ${v.vehicleType} • Mileage: ${v.mileage} mi',
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Text('Inspection history', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            if (controller.inspections.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No inspections yet.'),
                                ),
                              )
                            else
                              ...controller.inspections.map(
                                (inspection) => _InspectionCard(
                                  inspection: inspection,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => InspectionDetailScreen(summary: inspection),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
