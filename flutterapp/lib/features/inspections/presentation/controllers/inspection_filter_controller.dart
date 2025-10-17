import 'package:flutter/foundation.dart';
import '../data/models.dart';

/// Filter options for inspections
class InspectionFilterOptions {
  const InspectionFilterOptions({
    this.statusFilter = const <String>[],
    this.dateRange,
    this.searchQuery = '',
    this.sortBy = InspectionSortField.createdDate,
    this.sortAscending = false,
  });

  final List<String> statusFilter;
  final DateRange? dateRange;
  final String searchQuery;
  final InspectionSortField sortBy;
  final bool sortAscending;

  InspectionFilterOptions copyWith({
    List<String>? statusFilter,
    DateRange? dateRange,
    String? searchQuery,
    InspectionSortField? sortBy,
    bool? sortAscending,
  }) {
    return InspectionFilterOptions(
      statusFilter: statusFilter ?? this.statusFilter,
      dateRange: dateRange ?? this.dateRange,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// Date range for filtering
class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end.add(const Duration(days: 1)));
  }
}

/// Sort field options for inspections
enum InspectionSortField {
  createdDate,
  reference,
  status,
  vehicle,
  customer,
}

/// Controller for managing inspection filters and sorting
class InspectionFilterController extends ChangeNotifier {
  InspectionFilterController({
    required List<InspectionSummaryModel> initialInspections,
  }) : _allInspections = initialInspections {
    _filteredInspections = List.from(_allInspections);
  }

  final List<InspectionSummaryModel> _allInspections;
  late List<InspectionSummaryModel> _filteredInspections;
  InspectionFilterOptions _filters = const InspectionFilterOptions();

  /// Get current filters
  InspectionFilterOptions get filters => _filters;

  /// Get filtered and sorted inspections
  List<InspectionSummaryModel> get filteredInspections => _filteredInspections;

  /// Get available statuses from all inspections
  List<String> getAvailableStatuses() {
    final statuses = <String>{};
    for (final inspection in _allInspections) {
      statuses.add(inspection.status);
    }
    return statuses.toList()..sort();
  }

  /// Update filters
  void setFilters(InspectionFilterOptions filters) {
    _filters = filters;
    _applyFilters();
    notifyListeners();
  }

  /// Update only the status filter
  void setStatusFilter(List<String> statuses) {
    _filters = _filters.copyWith(statusFilter: statuses);
    _applyFilters();
    notifyListeners();
  }

  /// Update only the search query
  void setSearchQuery(String query) {
    _filters = _filters.copyWith(searchQuery: query);
    _applyFilters();
    notifyListeners();
  }

  /// Update only the date range
  void setDateRange(DateRange? range) {
    _filters = _filters.copyWith(dateRange: range);
    _applyFilters();
    notifyListeners();
  }

  /// Update sorting
  void setSorting(InspectionSortField field, {bool ascending = false}) {
    _filters = _filters.copyWith(
      sortBy: field,
      sortAscending: ascending,
    );
    _applyFilters();
    notifyListeners();
  }

  /// Reset all filters
  void resetFilters() {
    _filters = const InspectionFilterOptions();
    _applyFilters();
    notifyListeners();
  }

  /// Apply all filters and sorting
  void _applyFilters() {
    var filtered = List<InspectionSummaryModel>.from(_allInspections);

    // Apply status filter
    if (_filters.statusFilter.isNotEmpty) {
      filtered = filtered
          .where((inspection) => _filters.statusFilter.contains(inspection.status))
          .toList();
    }

    // Apply date range filter
    if (_filters.dateRange != null) {
      filtered = filtered
          .where((inspection) => _filters.dateRange!.contains(inspection.createdAt))
          .toList();
    }

    // Apply search query
    if (_filters.searchQuery.isNotEmpty) {
      final query = _filters.searchQuery.toLowerCase();
      filtered = filtered.where((inspection) {
        return inspection.reference.toLowerCase().contains(query) ||
            inspection.vehicle.licensePlate.toLowerCase().contains(query) ||
            inspection.vehicle.vin.toLowerCase().contains(query) ||
            inspection.vehicle.make.toLowerCase().contains(query) ||
            inspection.vehicle.model.toLowerCase().contains(query) ||
            inspection.customer?.legalName.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;

      switch (_filters.sortBy) {
        case InspectionSortField.createdDate:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case InspectionSortField.reference:
          comparison = a.reference.compareTo(b.reference);
          break;
        case InspectionSortField.status:
          comparison = a.status.compareTo(b.status);
          break;
        case InspectionSortField.vehicle:
          final aVehicle = '${a.vehicle.make} ${a.vehicle.model}';
          final bVehicle = '${b.vehicle.make} ${b.vehicle.model}';
          comparison = aVehicle.compareTo(bVehicle);
          break;
        case InspectionSortField.customer:
          comparison = (a.customer?.legalName ?? '').compareTo(b.customer?.legalName ?? '');
          break;
      }

      return _filters.sortAscending ? comparison : -comparison;
    });

    _filteredInspections = filtered;
  }

  /// Get count statistics
  InspectionStats getStats() {
    return InspectionStats(
      totalCount: _allInspections.length,
      filteredCount: _filteredInspections.length,
      approvedCount: _allInspections.where((i) => i.status == 'approved').length,
      rejectedCount: _allInspections.where((i) => i.status == 'rejected').length,
      submittedCount: _allInspections.where((i) => i.status == 'submitted').length,
      inProgressCount: _allInspections.where((i) => i.status == 'in_progress').length,
    );
  }
}

/// Statistics for inspections
class InspectionStats {
  const InspectionStats({
    required this.totalCount,
    required this.filteredCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.submittedCount,
    required this.inProgressCount,
  });

  final int totalCount;
  final int filteredCount;
  final int approvedCount;
  final int rejectedCount;
  final int submittedCount;
  final int inProgressCount;

  double get approvalRate => totalCount == 0 ? 0 : (approvedCount / totalCount) * 100;
  double get rejectionRate => totalCount == 0 ? 0 : (rejectedCount / totalCount) * 100;
}
