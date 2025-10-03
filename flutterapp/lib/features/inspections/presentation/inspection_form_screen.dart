import 'dart:io';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/models.dart';

class InspectionFormScreen extends StatefulWidget {
  const InspectionFormScreen({
    required this.inspectorId,
    required this.categories,
    required this.vehicles,
    this.assignment,
    this.initialVehicle,
    super.key,
  });

  final int inspectorId;
  final List<InspectionCategoryModel> categories;
  final List<VehicleModel> vehicles;
  final VehicleAssignmentModel? assignment;
  final VehicleModel? initialVehicle;

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  late VehicleModel? _selectedVehicle = widget.initialVehicle ?? (widget.vehicles.isNotEmpty ? widget.vehicles.first : null);
  late final Map<int, ChecklistItemModel> _checklistItems = {
    for (final category in widget.categories) for (final item in category.items) item.id: item,
  };
  late final Map<int, InspectionItemModel> _responses = {
    for (final entry in _checklistItems.entries)
      entry.key: InspectionItemModel.initialFromChecklist(entry.value),
  };
  final Map<int, List<String>> _photoPaths = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final odometer = widget.assignment?.remarks.contains('ODO:') == true
        ? _extractOdometer(widget.assignment!.remarks)
        : null;
    if (odometer != null) {
      _odometerController.text = odometer.toString();
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Inspection'),
        actions: [
          IconButton(
            tooltip: 'Discard',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    children: [
                      _buildContextCard(context),
                      const SizedBox(height: 24),
                      for (final category in widget.categories) ...[
                        _CategoryHeader(name: category.name, description: category.description),
                        const SizedBox(height: 16),
                        ...category.items.map((item) => _ChecklistItemEditor(
                              item: item,
                              response: _responses[item.id]!,
                              photos: _photoPaths[item.id] ?? const <String>[],
                              onResultChanged: (result) => _updateResponse(item.id, result: result),
                              onSeverityChanged: (severity) => _updateResponse(item.id, severity: severity.round()),
                              onNotesChanged: (notes) => _updateResponse(item.id, notes: notes),
                              onAddPhoto: () => _addPhoto(item.id),
                              onRemovePhoto: (path) => _removePhoto(item.id, path),
                            )),
                        const SizedBox(height: 24),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, -4)),
                  ],
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).maybePop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Save inspection draft'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF5AD2F4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 10))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.assignment != null ? 'Assignment inspection' : 'Ad-hoc inspection',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VehicleModel>(
                value: _selectedVehicle,
                decoration: InputDecoration(
                  labelText: 'Vehicle',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                dropdownColor: const Color(0xFF3069C8),
                items: widget.vehicles
                    .map(
                      (vehicle) => DropdownMenuItem<VehicleModel>(
                        value: vehicle,
                        child: Text(
                          '${vehicle.licensePlate} • ${vehicle.make} ${vehicle.model}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedVehicle = value),
                validator: (value) => value == null ? 'Select a vehicle' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Odometer',
                        labelStyle: const TextStyle(color: Colors.white70),
                        suffixText: 'mi',
                        suffixStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter odometer';
                        }
                        final odometer = int.tryParse(value.replaceAll(',', ''));
                        if (odometer == null || odometer < 0) {
                          return 'Invalid value';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _notesController,
                      minLines: 1,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'General notes',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addPhoto(int itemId) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _PhotoSourceSheet(item: _checklistItems[itemId]!),
    );
    if (source == null) {
      return;
    }
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) {
      return;
    }
    setState(() {
      final current = _photoPaths[itemId] ?? <String>[];
      current.add(picked.path);
      _photoPaths[itemId] = current;
      _responses[itemId] = _responses[itemId]!.copyWith(photoUris: current);
    });
  }

  void _removePhoto(int itemId, String path) {
    setState(() {
      final current = _photoPaths[itemId];
      if (current == null) {
        return;
      }
      current.remove(path);
      if (current.isEmpty) {
        _photoPaths.remove(itemId);
      }
      _responses[itemId] = _responses[itemId]!.copyWith(photoUris: current ?? const <String>[]);
    });
  }

  void _updateResponse(
    int itemId, {
    String? result,
    int? severity,
    String? notes,
  }) {
    setState(() {
      final current = _responses[itemId]!;
      _responses[itemId] = current.copyWith(
        result: result,
        severity: severity,
        notes: notes,
        photoUris: _photoPaths[itemId],
      );
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final vehicle = _selectedVehicle;
    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a vehicle before submitting.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final odometer = int.tryParse(_odometerController.text.replaceAll(',', '')) ?? 0;
      final items = _responses.values
          .map((response) => response.copyWith(photoUris: _photoPaths[response.checklistItemId]))
          .toList();
      final draft = InspectionDraftModel(
        assignmentId: widget.assignment?.id,
        vehicleId: vehicle.id,
        inspectorId: widget.inspectorId,
        odometerReading: odometer,
        generalNotes: _notesController.text.trim(),
        items: items,
      );
      if (!mounted) return;
      Navigator.of(context).pop(draft);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  int? _extractOdometer(String remarks) {
    final pattern = RegExp(r'ODO:(\d+)');
    final match = pattern.firstMatch(remarks);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.name, required this.description});

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ChecklistItemEditor extends StatelessWidget {
  const _ChecklistItemEditor({
    required this.item,
    required this.response,
    required this.photos,
    required this.onResultChanged,
    required this.onSeverityChanged,
    required this.onNotesChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final ChecklistItemModel item;
  final InspectionItemModel response;
  final List<String> photos;
  final ValueChanged<String> onResultChanged;
  final ValueChanged<double> onSeverityChanged;
  final ValueChanged<String> onNotesChanged;
  final Future<void> Function() onAddPhoto;
  final ValueChanged<String> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requiresPhoto = item.requiresPhoto;
    final severityLabel = _severityLabel(response.severity);
    final hasFailure = response.result == InspectionItemResponse.RESULT_FAIL;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6))],
        border: Border.all(color: hasFailure ? theme.colorScheme.error.withOpacity(0.35) : theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    if (item.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.description,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              if (requiresPhoto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Photo required',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              const ButtonSegment(value: InspectionItemResponse.RESULT_PASS, label: Text('Pass'), icon: Icon(Icons.check_circle_outline)),
              const ButtonSegment(value: InspectionItemResponse.RESULT_FAIL, label: Text('Fail'), icon: Icon(Icons.error_outline)),
              const ButtonSegment(value: InspectionItemResponse.RESULT_NA, label: Text('N/A'), icon: Icon(Icons.help_outline)),
            ],
            selected: <String>{response.result},
            onSelectionChanged: (values) => onResultChanged(values.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Severity', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(severityLabel, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Slider(
                      value: response.severity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: response.severity.toString(),
                      onChanged: hasFailure ? onSeverityChanged : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                hasFailure ? Icons.warning_rounded : Icons.verified_outlined,
                color: hasFailure ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: response.notes,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            onChanged: onNotesChanged,
            validator: (value) {
              if (response.result == InspectionItemResponse.RESULT_FAIL && photos.isEmpty) {
                return 'Photo evidence is required for failures.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _PhotoGallery(
            photos: photos,
            onAdd: onAddPhoto,
            onRemove: onRemovePhoto,
            requiresPhoto: requiresPhoto,
          ),
        ],
      ),
    );
  }

  String _severityLabel(int severity) {
    switch (severity) {
      case 1:
        return 'Minor';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'High';
      case 5:
        return 'Critical';
      default:
        return 'Unknown';
    }
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.requiresPhoto,
  });

  final List<String> photos;
  final Future<void> Function() onAdd;
  final ValueChanged<String> onRemove;
  final bool requiresPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photo evidence', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (requiresPhoto)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.star, size: 14, color: theme.colorScheme.error),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                requiresPhoto ? 'Capture at least one photo when recording a failure.' : 'Optional — attach reference photos.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: photos
                .map(
                  (path) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(path),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onTap: () => onRemove(path),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet({required this.item});

  final ChecklistItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attach photo for "${item.title}"', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _PhotoSourceTile(
              icon: Icons.camera_alt_outlined,
              title: 'Use camera',
              subtitle: 'Capture real-time evidence',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _PhotoSourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Upload from gallery',
              subtitle: 'Select from existing photos',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
