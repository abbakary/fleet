import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../data/inspections_repository.dart';
import '../../data/models.dart';

class InspectorDashboardController extends ChangeNotifier {
  InspectorDashboardController({
    required this.repository,
    required this.sessionController,
  });

  final InspectionsRepository repository;
  final SessionController sessionController;

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  List<VehicleAssignmentModel> _assignments = <VehicleAssignmentModel>[];
  List<VehicleModel> _vehicles = <VehicleModel>[];
  List<InspectionCategoryModel> _categories = <InspectionCategoryModel>[];
  List<InspectionSummaryModel> _recentInspections = <InspectionSummaryModel>[];
  int? _inspectorProfileId;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  List<VehicleAssignmentModel> get assignments => _assignments;
  List<VehicleModel> get vehicles => _vehicles;
  List<InspectionCategoryModel> get categories => _categories;
  List<InspectionSummaryModel> get recentInspections => _recentInspections;
  int? get inspectorProfileId => _inspectorProfileId;

  Future<void> loadDashboard() async {
    _setLoading(true);
    _error = null;
    notifyListeners();
    try {
      await repository.syncPendingInspections();
      final assignments = await repository.fetchAssignments();
      final vehicles = await repository.fetchVehicles();
      final categories = await repository.fetchCategories();
      final inspections = await repository.fetchInspections();
      final today = DateTime.now();
      _assignments = assignments.where((a) => _isSameDate(a.scheduledFor, today)).toList();
      _vehicles = vehicles;
      _categories = categories;
      _recentInspections = inspections;
      _inspectorProfileId = _resolveInspectorId(assignments, inspections);
    } on AppException catch (exception) {
      _error = exception.message;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<InspectionSubmissionResult> submitInspection(InspectionDraftModel draft) async {
    final result = await repository.submitInspection(draft);
    if (result.isSubmitted) {
      await loadDashboard();
    }
    return result;
  }

  Future<int> syncOfflineInspections() async {
    _isSyncing = true;
    notifyListeners();
    try {
      return await repository.syncPendingInspections();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  VehicleModel? vehicleById(int id) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int?> createVehicle({
    required int customerId,
    required String vin,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String vehicleType,
    String? axleConfiguration,
    int mileage = 0,
    String? notes,
  }) async {
    try {
      final vehicleId = await repository.createVehicle(
        customerId: customerId,
        vin: vin,
        licensePlate: licensePlate,
        make: make,
        model: model,
        year: year,
        vehicleType: vehicleType,
        axleConfiguration: axleConfiguration,
        mileage: mileage,
        notes: notes,
      );
      await loadDashboard();
      return vehicleId;
    } on AppException catch (exception) {
      _error = exception.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() {
    return sessionController.logout();
  }

  int? _resolveInspectorId(List<VehicleAssignmentModel> assignments, List<InspectionSummaryModel> inspections) {
    if (assignments.isNotEmpty) {
      return assignments.first.inspectorId;
    }
    for (final inspection in inspections) {
      final inspector = inspection.inspector;
      if (inspector != null) {
        return inspector.id;
      }
    }
    return null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
