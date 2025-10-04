import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/inspections_repository.dart';

class MakeModelSelector extends StatefulWidget {
  const MakeModelSelector({
    required this.makeController,
    required this.modelController,
    this.vehicles = const <VehicleModel>[],
    this.repository,
    this.onMakeChanged,
    this.onModelChanged,
    super.key,
  });

  final TextEditingController makeController;
  final TextEditingController modelController;
  final List<VehicleModel> vehicles;
  final InspectionsRepository? repository;
  final ValueChanged<String>? onMakeChanged;
  final ValueChanged<String>? onModelChanged;

  @override
  State<MakeModelSelector> createState() => _MakeModelSelectorState();
}

class _MakeModelSelectorState extends State<MakeModelSelector> {
  Set<String> _allMakes = <String>{};
  final Map<String, Set<String>> _modelsByMake = <String, Set<String>>{};
  String _selectedMake = '';

  @override
  void initState() {
    super.initState();
    _selectedMake = widget.makeController.text.trim();
    if (widget.repository != null) {
      _loadMakes();
    } else {
      _allMakes = widget.vehicles.map((v) => v.make.trim()).where((m) => m.isNotEmpty).toSet();
      for (final v in widget.vehicles) {
        final make = v.make.trim();
        final model = v.model.trim();
        if (make.isEmpty || model.isEmpty) continue;
        _modelsByMake.putIfAbsent(make, () => <String>{}).add(model);
      }
    }
  }

  Future<void> _loadMakes() async {
    try {
      final repo = widget.repository!;
      final makes = await repo.fetchVehicleMakes();
      setState(() {
        _allMakes = makes.map((m) => m.name.trim()).where((n) => n.isNotEmpty).toSet();
      });
      if (_selectedMake.isNotEmpty) {
        await _loadModelsForMake(_selectedMake);
      }
    } catch (_) {
      // Silently ignore; fallback to manual entry
    }
  }

  Future<void> _loadModelsForMake(String makeName) async {
    if (widget.repository == null || makeName.trim().isEmpty) return;
    try {
      final repo = widget.repository!;
      final models = await repo.fetchVehicleModels(makeName: makeName.trim());
      setState(() {
        _modelsByMake[makeName.trim()] = models.map((m) => m.name.trim()).where((n) => n.isNotEmpty).toSet();
      });
    } catch (_) {
      // Ignore errors
    }
  }

  Iterable<String> _suggestMakes(String pattern) {
    final q = pattern.trim().toLowerCase();
    final matches = _allMakes.where((m) => m.toLowerCase().contains(q)).toList()..sort();
    if (pattern.trim().isNotEmpty && !_allMakes.map((m) => m.toLowerCase()).contains(q)) {
      return <String>[pattern.trim(), ...matches];
    }
    return matches;
  }

  Iterable<String> _suggestModels(String pattern) {
    final base = _modelsByMake[_selectedMake] ?? _modelsByMake.values.expand((s) => s).toSet();
    final q = pattern.trim().toLowerCase();
    final matches = base.where((m) => m.toLowerCase().contains(q)).toList()..sort();
    if (pattern.trim().isNotEmpty && !base.map((m) => m.toLowerCase()).contains(q)) {
      return <String>[pattern.trim(), ...matches];
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMakeField(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildModelField(context)),
      ],
    );
  }

  Widget _buildMakeField(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.makeController,
      optionsBuilder: (text) => _suggestMakes(text.text),
      onSelected: (value) async {
        _selectedMake = value.trim();
        widget.onMakeChanged?.call(_selectedMake);
        final models = _modelsByMake[_selectedMake] ?? const <String>{};
        if (!models.contains(widget.modelController.text.trim())) {
          widget.modelController.text = '';
          widget.onModelChanged?.call('');
        }
        if (widget.repository != null) {
          await _loadModelsForMake(_selectedMake);
        }
        if (mounted) setState(() {});
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(labelText: 'Make'),
        textInputAction: TextInputAction.next,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        onChanged: (value) {
          _selectedMake = value.trim();
          widget.onMakeChanged?.call(_selectedMake);
          if (widget.repository != null) {
            _loadModelsForMake(_selectedMake);
          }
          setState(() {});
        },
      ),
      optionsViewBuilder: (context, onSelected, options) => _buildOptionsList(context, onSelected, options, leadingIcon: Icons.directions_car_outlined),
    );
  }

  Widget _buildModelField(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.modelController,
      optionsBuilder: (text) => _suggestModels(text.text),
      onSelected: (value) {
        widget.modelController.text = value.trim();
        widget.onModelChanged?.call(widget.modelController.text);
        setState(() {});
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(labelText: 'Model'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        onChanged: (value) {
          widget.onModelChanged?.call(value.trim());
        },
      ),
      optionsViewBuilder: (context, onSelected, options) => _buildOptionsList(context, onSelected, options, leadingIcon: Icons.build_outlined),
    );
  }

  Widget _buildOptionsList(BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options, {required IconData leadingIcon}) {
    final opts = options.toList();
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, minWidth: 220),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: opts.length,
            itemBuilder: (context, index) {
              final value = opts[index];
              final isCreate = !_allMakes.contains(value) && !(_modelsByMake[_selectedMake] ?? const <String>{}).contains(value);
              return ListTile(
                leading: Icon(isCreate ? Icons.add_circle_outline : leadingIcon),
                title: Text(isCreate ? 'Create "$value"' : value),
                onTap: () => onSelected(value),
              );
            },
          ),
        ),
      ),
    );
  }
}
