import 'package:flutter/material.dart';
import '../controllers/inspection_filter_controller.dart';

/// Filter panel widget for inspections
class InspectionFilterPanel extends StatefulWidget {
  const InspectionFilterPanel({
    required this.controller,
    required this.availableStatuses,
    required this.onClose,
    super.key,
  });

  final InspectionFilterController controller;
  final List<String> availableStatuses;
  final VoidCallback onClose;

  @override
  State<InspectionFilterPanel> createState() => _InspectionFilterPanelState();
}

class _InspectionFilterPanelState extends State<InspectionFilterPanel> {
  late List<String> _selectedStatuses;
  late String _searchQuery;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedStatuses = List.from(widget.controller.filters.statusFilter);
    _searchQuery = widget.controller.filters.searchQuery;
    _startDate = widget.controller.filters.dateRange?.start;
    _endDate = widget.controller.filters.dateRange?.end;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search',
                          hintText: 'Reference, VIN, License Plate...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => _searchQuery = value,
                      ),
                      const SizedBox(height: 20),

                      // Status filter
                      Text('Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.availableStatuses.map((status) {
                          final isSelected = _selectedStatuses.contains(status);
                          return FilterChip(
                            label: Text(_statusDisplay(status)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStatuses.add(status);
                                } else {
                                  _selectedStatuses.remove(status);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Date range
                      Text('Date Range', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ListTile(
                        title: const Text('Start Date'),
                        subtitle: _startDate != null ? Text(_formatDate(_startDate!)) : const Text('Not selected'),
                        trailing: _startDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _startDate = null),
                              )
                            : null,
                        onTap: () => _selectStartDate(context),
                      ),
                      ListTile(
                        title: const Text('End Date'),
                        subtitle: _endDate != null ? Text(_formatDate(_endDate!)) : const Text('Not selected'),
                        trailing: _endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _endDate = null),
                              )
                            : null,
                        onTap: () => _selectEndDate(context),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedStatuses.clear();
                      _searchQuery = '';
                      _startDate = null;
                      _endDate = null;
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                  FilledButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.done),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _applyFilters() {
    final dateRange = _startDate != null && _endDate != null
        ? DateRange(start: _startDate!, end: _endDate!)
        : null;

    widget.controller.setFilters(
      InspectionFilterOptions(
        statusFilter: _selectedStatuses,
        searchQuery: _searchQuery,
        dateRange: dateRange,
        sortBy: widget.controller.filters.sortBy,
        sortAscending: widget.controller.filters.sortAscending,
      ),
    );
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _statusDisplay(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }
}

/// Sort options widget
class InspectionSortOptions extends StatelessWidget {
  const InspectionSortOptions({
    required this.currentField,
    required this.isAscending,
    required this.onSortChanged,
    super.key,
  });

  final InspectionSortField currentField;
  final bool isAscending;
  final Function(InspectionSortField, bool) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<InspectionSortField>(
      onSelected: (field) {
        if (field == currentField) {
          // Toggle ascending/descending
          onSortChanged(field, !isAscending);
        } else {
          onSortChanged(field, false);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: InspectionSortField.createdDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Created Date'),
              if (currentField == InspectionSortField.createdDate)
                Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            ],
          ),
        ),
        PopupMenuItem(
          value: InspectionSortField.reference,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reference'),
              if (currentField == InspectionSortField.reference)
                Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            ],
          ),
        ),
        PopupMenuItem(
          value: InspectionSortField.status,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Status'),
              if (currentField == InspectionSortField.status)
                Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            ],
          ),
        ),
        PopupMenuItem(
          value: InspectionSortField.vehicle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vehicle'),
              if (currentField == InspectionSortField.vehicle)
                Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            ],
          ),
        ),
        PopupMenuItem(
          value: InspectionSortField.customer,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Customer'),
              if (currentField == InspectionSortField.customer)
                Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort),
          const SizedBox(width: 4),
          Text(_getSortLabel()),
        ],
      ),
    );
  }

  String _getSortLabel() {
    final fieldLabel = switch (currentField) {
      InspectionSortField.createdDate => 'Date',
      InspectionSortField.reference => 'Reference',
      InspectionSortField.status => 'Status',
      InspectionSortField.vehicle => 'Vehicle',
      InspectionSortField.customer => 'Customer',
    };
    final direction = isAscending ? '↑' : '↓';
    return '$fieldLabel $direction';
  }
}

/// Active filter chips display
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    required this.filters,
    required this.onFilterRemoved,
    super.key,
  });

  final InspectionFilterOptions filters;
  final Function(String filterType) onFilterRemoved;

  @override
  Widget build(BuildContext context) {
    final activeFilters = <String>[];

    if (filters.statusFilter.isNotEmpty) {
      activeFilters.add('Status: ${filters.statusFilter.join(", ")}');
    }

    if (filters.searchQuery.isNotEmpty) {
      activeFilters.add('Search: ${filters.searchQuery}');
    }

    if (filters.dateRange != null) {
      activeFilters.add('Date Range');
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeFilters.map((filter) {
        return Chip(
          label: Text(filter),
          onDeleted: () => onFilterRemoved(filter),
        );
      }).toList(),
    );
  }
}
