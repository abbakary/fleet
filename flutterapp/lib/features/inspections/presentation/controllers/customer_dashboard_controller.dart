import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../data/inspections_repository.dart';
import '../../data/models.dart';

class CustomerDashboardController extends ChangeNotifier {
  CustomerDashboardController({required this.repository});

  final InspectionsRepository repository;

  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _error;
  List<VehicleModel> _vehicles = <VehicleModel>[];
  List<InspectionSummaryModel> _inspections = <InspectionSummaryModel>[];
  InspectionDetailModel? _selectedInspection;

  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get error => _error;
  List<VehicleModel> get vehicles => _vehicles;
  List<InspectionSummaryModel> get inspections => _inspections;
  InspectionDetailModel? get selectedInspection => _selectedInspection;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final vehicles = await repository.fetchVehicles();
      final inspections = await repository.fetchInspections();
      _vehicles = vehicles;
      _inspections = inspections;
    } on AppException catch (exception) {
      _error = exception.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<InspectionDetailModel?> loadInspectionDetail(int id) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      final detail = await repository.fetchInspectionDetail(id);
      _selectedInspection = detail;
      return detail;
    } on AppException catch (exception) {
      _error = exception.message;
      return null;
    } finally {
      _isDetailLoading = false;
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

  String resolveMediaUrl(String path) => repository.resolveMediaUrl(path);
}
