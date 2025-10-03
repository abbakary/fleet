import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../data/checklist_blueprint.dart';
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
  List<VehicleAssignmentModel> _allAssignments = <VehicleAssignmentModel>[];
  List<VehicleAssignmentModel> _assignmentsToday = <VehicleAssignmentModel>[];
  List<VehicleAssignmentModel> _upcomingAssignments = <VehicleAssignmentModel>[];
  List<VehicleAssignmentModel> _overdueAssignments = <VehicleAssignmentModel>[];
  List<VehicleModel> _vehicles = <VehicleModel>[];
  List<InspectionCategoryModel> _categories = <InspectionCategoryModel>[];
  List<ChecklistGuideEntry> _checklistGuide = <ChecklistGuideEntry>[];
  List<InspectionSummaryModel> _recentInspections = <InspectionSummaryModel>[];
  int? _inspectorProfileId;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  List<VehicleAssignmentModel> get assignmentsToday => _assignmentsToday;
  List<VehicleAssignmentModel> get upcomingAssignments => _upcomingAssignments;
  List<VehicleAssignmentModel> get overdueAssignments => _overdueAssignments;
  List<VehicleAssignmentModel> get allAssignments => _allAssignments;
  bool get hasAssignments => _assignmentsToday.isNotEmpty || _upcomingAssignments.isNotEmpty || _overdueAssignments.isNotEmpty;
  List<VehicleModel> get vehicles => _vehicles;
  List<InspectionCategoryModel> get categories => _categories;
  List<ChecklistGuideEntry> get checklistGuide => _checklistGuide;
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
      final todayDate = _stripDate(today);
      _allAssignments = assignments;
      _assignmentsToday = assignments
          .where((assignment) => _isSameDate(assignment.scheduledFor, todayDate))
          .toList()
        ..sort(_compareAssignments);
      _upcomingAssignments = assignments
          .where((assignment) => _stripDate(assignment.scheduledFor).isAfter(todayDate))
          .toList()
        ..sort(_compareAssignments);
      _overdueAssignments = assignments
          .where((assignment) => _stripDate(assignment.scheduledFor).isBefore(todayDate))
          .toList()
        ..sort((a, b) => _compareAssignments(b, a));
      _vehicles = vehicles;
      _categories = categories;
      _checklistGuide = buildChecklistGuide(categories);
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

  DateTime _stripDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _compareAssignments(VehicleAssignmentModel a, VehicleAssignmentModel b) {
    return _stripDate(a.scheduledFor).compareTo(_stripDate(b.scheduledFor));
  }
}
