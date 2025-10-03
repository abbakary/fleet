import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/animated_background.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/inspections_repository.dart';
import '../data/models.dart';
import 'controllers/inspector_dashboard_controller.dart';
import 'inspection_detail_screen.dart';
import 'inspection_form_screen.dart';

class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({required this.profile, super.key});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InspectorDashboardController>(
      create: (context) => InspectorDashboardController(
        repository: context.read<InspectionsRepository>(),
        sessionController: context.read<SessionController>(),
      )..loadDashboard(),
      child: _InspectorHomeView(profile: profile),
    );
  }
}

class _InspectorHomeView extends StatefulWidget {
  const _InspectorHomeView({required this.profile});

  final PortalProfile profile;

  @override
  State<_InspectorHomeView> createState() => _InspectorHomeViewState();
}

class _InspectorHomeViewState extends State<_InspectorHomeView> {
  bool _fabOpen = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<InspectorDashboardController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Inspector • ${widget.profile.fullName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: () async {
                  await controller.signOut();
                },
              ),
            ],
          ),
          floatingActionButton: _buildFab(context, controller),
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
                            _QuickActionsBar(
                              onNewInspection: controller.vehicles.isEmpty || controller.inspectorProfileId == null
                                  ? null
                                  : () => _startAdHocInspection(context, controller),
                              onSync: controller.isSyncing
                                  ? null
                                  : () async {
                                      final processed = await controller.syncOfflineInspections();
                                      if (!context.mounted) return;
                                      final message = processed > 0
                                          ? 'Synced $processed inspection(s).'
                                          : 'No inspections waiting for sync.';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    },
                              onRefresh: controller.refresh,
                            ),
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
                            if (controller.isSyncing)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Syncing offline inspections…'),
                                  ],
                                ),
                              ),
                            Text(
                              'Today\'s assignments',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (controller.assignments.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No assignments scheduled.'),
                                ),
                              )
                            else
                              ...controller.assignments.map((assignment) {
                                final vehicle = controller.vehicleById(assignment.vehicleId);
                                return _AssignmentCard(
                                  assignment: assignment,
                                  vehicle: vehicle,
                                  onStart: () => _startAssignmentInspection(context, controller, assignment),
                                  onAddVehicle: vehicle?.customerId != null
                                      ? () => _openAddVehicleDialog(context, controller, vehicle!.customerId!)
                                      : null,
                                );
                              }),
                            const SizedBox(height: 32),
                            Text(
                              'Recent inspections',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (controller.recentInspections.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No inspections submitted yet.'),
                                ),
                              )
                            else
                              ...controller.recentInspections.map(
                                (inspection) => _InspectionListTile(
                                  inspection: inspection,
                                  onTap: () => _openInspectionDetail(context, inspection),
                                ),
                              ),
                            const SizedBox(height: 12),
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

  Widget _buildFab(BuildContext context, InspectorDashboardController controller) {
    if (controller.inspectorProfileId == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_fabOpen) ...[
          _MiniFab(
            icon: Icons.add_task,
            label: 'New inspection',
            onTap: controller.vehicles.isEmpty ? null : () => _startAdHocInspection(context, controller),
          ),
          const SizedBox(height: 10),
          _MiniFab(
            icon: Icons.sync,
            label: controller.isSyncing ? 'Syncing…' : 'Sync offline',
            onTap: controller.isSyncing
                ? null
                : () async {
                    final processed = await controller.syncOfflineInspections();
                    if (!context.mounted) return;
                    final message = processed > 0
                        ? 'Synced $processed inspection(s).'
                        : 'No inspections waiting for sync.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          child: Icon(_fabOpen ? Icons.close : Icons.menu),
        ),
      ],
    );
  }

  Future<void> _startAssignmentInspection(
    BuildContext context,
    InspectorDashboardController controller,
    VehicleAssignmentModel assignment,
  ) async {
    await _openInspectionForm(
      context,
      controller,
      assignment: assignment,
      initialVehicle: controller.vehicleById(assignment.vehicleId),
    );
  }

  Future<void> _startAdHocInspection(
    BuildContext context,
    InspectorDashboardController controller,
  ) async {
    await _openInspectionForm(context, controller);
  }

  Future<void> _openInspectionForm(
    BuildContext context,
    InspectorDashboardController controller, {
    VehicleAssignmentModel? assignment,
    VehicleModel? initialVehicle,
  }) async {
    final inspectorId = controller.inspectorProfileId;
    if (inspectorId == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inspector profile missing'),
          content: const Text(
            'Unable to determine your inspector profile. Please sync assignments or contact an administrator.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    if (controller.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist categories not available. Try refreshing.')),
      );
      return;
    }

    final draft = await Navigator.of(context).push<InspectionDraftModel>(
      MaterialPageRoute(
        builder: (_) => InspectionFormScreen(
          inspectorId: inspectorId,
          categories: controller.categories,
          vehicles: controller.vehicles,
          assignment: assignment,
          initialVehicle: initialVehicle,
        ),
      ),
    );

    if (draft == null) {
      return;
    }

    final result = await controller.submitInspection(draft);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isSubmitted
              ? 'Inspection submitted successfully.'
              : 'Inspection saved offline and will sync when online.',
        ),
      ),
    );
  }

  Future<void> _openAddVehicleDialog(
    BuildContext context,
    InspectorDashboardController controller,
    int customerId,
  ) async {
    final vin = TextEditingController();
    final plate = TextEditingController();
    final make = TextEditingController();
    final model = TextEditingController();
    final year = TextEditingController(text: DateTime.now().year.toString());
    final type = TextEditingController();
    final mileage = TextEditingController(text: '0');
    final notes = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add vehicle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: plate,
                  decoration: const InputDecoration(labelText: 'License plate'),
                  validator: _req,
                ),
                TextFormField(
                  controller: vin,
                  decoration: const InputDecoration(labelText: 'VIN'),
                  validator: _req,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: make,
                        decoration: const InputDecoration(labelText: 'Make'),
                        validator: _req,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: model,
                        decoration: const InputDecoration(labelText: 'Model'),
                        validator: _req,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: year,
                        decoration: const InputDecoration(labelText: 'Year'),
                        keyboardType: TextInputType.number,
                        validator: _req,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: type,
                        decoration: const InputDecoration(labelText: 'Vehicle type'),
                        validator: _req,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: mileage,
                        decoration: const InputDecoration(labelText: 'Mileage'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: notes,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              final id = await controller.createVehicle(
                customerId: customerId,
                vin: vin.text.trim(),
                licensePlate: plate.text.trim(),
                make: make.text.trim(),
                model: model.text.trim(),
                year: int.tryParse(year.text) ?? DateTime.now().year,
                vehicleType: type.text.trim(),
                mileage: int.tryParse(mileage.text) ?? 0,
                notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
              );
              if (!context.mounted) {
                return;
              }
              if (id != null) {
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle added.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await controller.refresh();
    }
  }

  String? _req(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Required' : null;
  }

  Future<void> _openInspectionDetail(
    BuildContext context,
    InspectionSummaryModel summary,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionDetailScreen(summary: summary),
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({this.onNewInspection, this.onSync, this.onRefresh});

  final VoidCallback? onNewInspection;
  final Future<void> Function()? onSync;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onNewInspection,
              icon: const Icon(Icons.add_task),
              label: const Text('New inspection'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onSync,
              icon: const Icon(Icons.sync),
              label: const Text('Sync offline'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFab extends StatelessWidget {
  const _MiniFab({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.vehicle,
    required this.onStart,
    this.onAddVehicle,
  });

  final VehicleAssignmentModel assignment;
  final VehicleModel? vehicle;
  final VoidCallback onStart;
  final VoidCallback? onAddVehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduled = DateFormat.yMMMMd().format(assignment.scheduledFor);
    final vehicleLabel = vehicle != null
        ? '${vehicle!.licensePlate} • ${vehicle!.make} ${vehicle!.model}'
        : 'Vehicle #${assignment.vehicleId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicleLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Scheduled for $scheduled'),
            const SizedBox(height: 4),
            Text('Status: ${assignment.status.replaceAll('_', ' ')}'),
            if (assignment.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(assignment.remarks),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onAddVehicle != null)
                  OutlinedButton.icon(
                    onPressed: onAddVehicle,
                    icon: const Icon(Icons.add),
                    label: const Text('Add vehicle'),
                  ),
                if (onAddVehicle != null) const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.assignment_turned_in),
                  label: const Text('Start inspection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionListTile extends StatelessWidget {
  const _InspectionListTile({required this.inspection, required this.onTap});

  final InspectionSummaryModel inspection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, inspection.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          inspection.vehicle.licensePlate.isNotEmpty
              ? '${inspection.vehicle.licensePlate} • ${inspection.vehicle.make} ${inspection.vehicle.model}'
              : inspection.vehicle.vin,
        ),
        subtitle: Text('${inspection.statusDisplay} • ${DateFormat.yMMMd().format(inspection.createdAt)}'),
        trailing: Icon(Icons.chevron_right, color: statusColor),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'submitted' => Colors.deepOrange,
      'approved' => Colors.green,
      'in_progress' => Colors.blue,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}
