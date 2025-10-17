import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/animated_background.dart';
import '../../../core/ui/language_menu.dart';
import '../data/inspections_repository.dart';
import '../data/models.dart';
import 'controllers/customer_dashboard_controller.dart';
import 'inspection_detail_screen.dart';

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
