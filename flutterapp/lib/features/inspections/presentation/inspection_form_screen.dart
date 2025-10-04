import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/animated_background.dart';

import '../data/guided_steps.dart';
import '../data/inspections_repository.dart';
import '../data/models.dart';
import 'widgets/photo_annotation_screen.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  late final List<_GuidedStep> _steps;
  late final Map<int, ChecklistItemModel> _checklistItems;
  late final Map<int, InspectionItemModel> _responses;
  final Map<int, List<String>> _photoPaths = <int, List<String>>{};
  final Map<String, List<String>> _stepPhotos = <String, List<String>>{};
  final Map<String, TextEditingController> _stepNotesControllers = <String, TextEditingController>{};
  final Map<String, Set<int>> _instructionCompletion = <String, Set<int>>{};
  final Map<String, ScrollController> _stepScrollControllers = <String, ScrollController>{};
  final Map<String, bool> _operationalChecks = <String, bool>{
    'brake_test': false,
    'steering_check': false,
    'engine_start': false,
    'transmission_check': false,
  };
  final Set<String> _skippedSteps = <String>{};

  VehicleModel? _selectedVehicle;
  int _currentStepIndex = 0;
  bool _isSubmitting = false;
  bool _identificationVerified = false;
  bool _trailerNotApplicable = false;

  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _generalNotesController = TextEditingController();
  final TextEditingController _vehicleConditionController = TextEditingController();
  final TextEditingController _identificationNotesController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _operationalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    _checklistItems = {
      for (final category in widget.categories) for (final item in category.items) item.id: item,
    };
    _responses = {
      for (final entry in _checklistItems.entries) entry.key: InspectionItemModel.initialFromChecklist(entry.value),
    };
    _selectedVehicle = widget.initialVehicle ?? (widget.vehicles.isNotEmpty ? widget.vehicles.first : null);
    if (_selectedVehicle != null) {
      _applyVehicleDefaults(_selectedVehicle!);
    }
    final odometer = widget.assignment?.remarks.contains('ODO:') == true ? _extractOdometer(widget.assignment!.remarks) : null;
    if (odometer != null) {
      _odometerController.text = odometer.toString();
    }
    for (final step in _steps) {
      _stepNotesControllers[step.definition.code] = TextEditingController();
      _instructionCompletion[step.definition.code] = <int>{};
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _odometerController.dispose();
    _generalNotesController.dispose();
    _vehicleConditionController.dispose();
    _identificationNotesController.dispose();
    _vinController.dispose();
    _plateController.dispose();
    _operationalNotesController.dispose();
    for (final controller in _stepNotesControllers.values) {
      controller.dispose();
    }
    for (final controller in _stepScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final step = _steps[_currentStepIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guidedInspectionTitle),
        actions: [
          IconButton(
            tooltip: l10n.discardTooltip,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressHeader(theme, step, context),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) => _buildStepPage(_steps[index]),
                ),
              ),
            ),
            const Divider(height: 1),
            _buildNavigationBar(step, context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme, _GuidedStep step, BuildContext context) {
    final l10n = context.l10n;
    final progress = (_currentStepIndex + 1) / _steps.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.stepProgress(_currentStepIndex + 1, _steps.length), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(_stepTitle(context, step.definition.code), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_stepSummary(context, step.definition.code), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }

  Widget _buildStepPage(_GuidedStep step) {
    switch (step.definition.code) {
      case 'pre_trip_documentation':
        return _buildPreTripStep(step);
      case 'operational_tests':
        return _buildOperationalStep(step);
      default:
        return _buildChecklistStep(step);
    }
  }

  Widget _buildPreTripStep(_GuidedStep step) {
    final l10n = context.l10n;
    final vehicleItems = widget.vehicles
        .map(
          (vehicle) => DropdownMenuItem<VehicleModel>(
            value: vehicle,
            child: Text('${vehicle.licensePlate} • ${vehicle.make} ${vehicle.model}', overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
    final theme = Theme.of(context);
    final instructionState = _instructionStateFor(step);
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _StepIntroCard(
            step: step,
            completedIndices: instructionState,
            enabled: true,
            onToggle: (index, value) => _onInstructionToggle(step, index, value),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<VehicleModel>(
                    value: _selectedVehicle,
                    decoration: InputDecoration(labelText: l10n.vehicleLabel),
                    items: vehicleItems,
                    onChanged: (selected) {
                      setState(() {
                        _selectedVehicle = selected;
                        if (selected != null) {
                          _applyVehicleDefaults(selected);
                        }
                      });
                    },
                    validator: (value) => value == null ? l10n.selectVehicleBeforeContinuing : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _startScan(
                            title: l10n.scanVin,
                            onValue: (value) => _vinController.text = value,
                          ),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(l10n.scanVin),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _startScan(
                            title: l10n.scanPlate,
                            onValue: (value) => _plateController.text = value,
                          ),
                          icon: const Icon(Icons.directions_car_filled_outlined),
                          label: Text(l10n.scanPlate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vinController,
                    decoration: InputDecoration(labelText: l10n.vinLabel),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.vinCaptureRequired;
                      }
                      if (value.trim().length < 8) {
                        return l10n.vinIncomplete;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _plateController,
                    decoration: InputDecoration(labelText: l10n.licensePlateLabel),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) => value == null || value.trim().isEmpty ? l10n.enterLicensePlate : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _odometerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.odometerLabel),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.odometerRequired;
                      }
                      final parsed = int.tryParse(value.replaceAll(',', ''));
                      if (parsed == null || parsed < 0) {
                        return l10n.odometerInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleConditionController,
                    decoration: InputDecoration(
                      labelText: l10n.generalVehicleConditionLabel,
                      hintText: l10n.generalVehicleConditionHint,
                    ),
                    minLines: 3,
                    maxLines: 6,
                    validator: (value) => value == null || value.trim().isEmpty ? l10n.generalVehicleConditionRequired : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _identificationNotesController,
                    decoration: InputDecoration(
                      labelText: l10n.identificationNotesLabel,
                      hintText: l10n.identificationNotesHint,
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _identificationVerified,
                    onChanged: (value) => setState(() => _identificationVerified = value ?? false),
                    title: Text(l10n.identificationVerifiedTitle),
                    subtitle: Text(l10n.identificationVerifiedSubtitle),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGeneralPhotoSection(step, requiresPhoto: true, helperText: l10n.captureBaselinePhoto),
          const SizedBox(height: 24),
          _buildStepNotesField(step, hintText: l10n.captureBaselinePhoto),
        ],
      ),
    );
  }

  Widget _buildChecklistStep(_GuidedStep step) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isTrailerStep = step.definition.code == 'coupling_connections';
    final stepSkipped = isTrailerStep && _trailerNotApplicable;
    final items = step.items;
    final instructionState = _instructionStateFor(step);
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _StepIntroCard(
            step: step,
            completedIndices: instructionState,
            enabled: !stepSkipped,
            onToggle: (index, value) => _onInstructionToggle(step, index, value),
          ),
          if (isTrailerStep) ...[
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: _trailerNotApplicable,
              onChanged: (value) => _handleTrailerSkipToggle(step, value),
              title: Text(l10n.trailerNotAttached),
              subtitle: Text(l10n.trailerNotAttachedSubtitle),
            ),
          ],
          const SizedBox(height: 16),
          if (stepSkipped)
            Card(
              color: theme.colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.stepMarkedNotApplicable,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.stepNoChecklistItems),
              ),
            )
          else
            ...items.map(
              (item) => _ChecklistItemEditor(
                key: ValueKey<int>(item.id),
                item: item,
                response: _responses[item.id]!,
                photos: _photoPaths[item.id] ?? const <String>[],
                onResultChanged: (result) => _updateResponse(item.id, result: result),
                onSeverityChanged: (severity) => _updateResponse(item.id, severity: severity.round()),
                onNotesChanged: (notes) => _updateResponse(item.id, notes: notes),
                onAddPhoto: () => _addPhotoForItem(step, item),
                onRemovePhoto: (path) => _removePhotoForItem(step, item, path),
              ),
            ),
          const SizedBox(height: 24),
          _buildGeneralPhotoSection(step, helperText: l10n.optionalAttachReferencePhotos),
          const SizedBox(height: 24),
          _buildChecklistPhotoSummary(step),
          if (!stepSkipped) ...[
            const SizedBox(height: 24),
            _buildStepNotesField(step, hintText: l10n.optionalAttachReferencePhotos),
          ],
        ],
      ),
    );
  }

  Widget _buildOperationalStep(_GuidedStep step) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final instructionState = _instructionStateFor(step);
    final instructions = _stepInstructions(context, step.definition.code);
    return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _StepIntroCard(
            step: step,
            completedIndices: instructionState,
            enabled: true,
            onToggle: (index, value) => _onInstructionToggle(step, index, value),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var i = 0; i < instructions.length; i += 1)
                    _OperationalCheckTile(
                      title: instructions[i],
                      subtitle: '',
                      value: _operationalChecks[_operationalKeyForIndex(i)]!,
                      onChanged: (value) => setState(() => _operationalChecks[_operationalKeyForIndex(i)] = value ?? false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGeneralPhotoSection(step, helperText: l10n.optionalAttachReferencePhotos),
          const SizedBox(height: 24),
          TextFormField(
            controller: _operationalNotesController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.notesFieldLabel,
              hintText: l10n.optionalAttachReferencePhotos,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _generalNotesController,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.submitInspectionLabel,
              hintText: l10n.optionalAttachReferencePhotos,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralPhotoSection(_GuidedStep step, {bool requiresPhoto = false, String? helperText}) {
    final l10n = context.l10n;
    final photos = _stepPhotos[step.definition.code] ?? const <String>[];
    return _PhotoGallery(
      title: l10n.stepEvidenceTitle,
      photos: photos,
      onAdd: () => _addStepPhoto(step),
      onRemove: (path) => _removeStepPhoto(step, path),
      requiresPhoto: requiresPhoto,
      helperText: helperText,
    );
  }

  Widget _buildChecklistPhotoSummary(_GuidedStep step) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final generalPhotos = _stepPhotos[step.definition.code] ?? const <String>[];
    final photoEntries = step.items
        .map((item) => MapEntry(item, _photoPaths[item.id] ?? const <String>[]))
        .where((entry) => entry.value.isNotEmpty)
        .toList();
    if (generalPhotos.isEmpty && photoEntries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.photoEvidenceLogTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (generalPhotos.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(l10n.photoEvidenceSectionStep, style: theme.textTheme.bodyLarge)),
                  const SizedBox(width: 12),
                  Chip(label: Text(l10n.photoCountLabel(generalPhotos.length))),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ...photoEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.title,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Chip(label: Text(l10n.photoCountLabel(entry.value.length))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNotesField(_GuidedStep step, {String? hintText}) {
    final l10n = context.l10n;
    final controller = _stepNotesControllers[step.definition.code]!;
    return TextFormField(
      controller: controller,
      minLines: 2,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: '${l10n.notesFieldLabel} — ${_stepTitle(context, step.definition.code)}',
        hintText: hintText,
      ),
    );
  }

  Widget _buildNavigationBar(_GuidedStep step, BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isFirst = _currentStepIndex == 0;
    final isLast = _currentStepIndex == _steps.length - 1;
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: isFirst || _isSubmitting ? null : _handlePrevious,
            child: Text(l10n.backLabel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _handleNext(step, isLast),
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.assignment_turned_in_outlined : Icons.arrow_forward),
              label: Text(isLast ? l10n.submitInspectionLabel : l10n.nextStepLabel),
            ),
          ),
        ],
      ),
    );
  }

  List<_GuidedStep> _buildSteps() {
    final categoriesByCode = <String, InspectionCategoryModel>{
      for (final category in widget.categories) category.code: category,
    };
    final steps = guidedInspectionSteps
        .map(
          (definition) => _GuidedStep(
            definition: definition,
            category: definition.categoryCode != null ? categoriesByCode[definition.categoryCode] : null,
          ),
        )
        .toList();
    steps.sort((a, b) => a.definition.order.compareTo(b.definition.order));
    return steps;
  }

  // Localization helpers for guided steps
  String _stepTitle(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'pre_trip_documentation':
        return l10n.stepPreTripDocumentationTitle;
      case 'exterior_structure':
        return l10n.stepExteriorStructureTitle;
      case 'tires_wheels_axles':
        return l10n.stepTiresWheelsAxlesTitle;
      case 'braking_system':
        return l10n.stepBrakingSystemTitle;
      case 'suspension_steering':
        return l10n.stepSuspensionSteeringTitle;
      case 'engine_powertrain':
        return l10n.stepEnginePowertrainTitle;
      case 'electrical_lighting':
        return l10n.stepElectricalLightingTitle;
      case 'cabin_interior':
        return l10n.stepCabinInteriorTitle;
      case 'coupling_connections':
        return l10n.stepCouplingConnectionsTitle;
      case 'safety_equipment':
        return l10n.stepSafetyEquipmentTitle;
      case 'operational_tests':
        return l10n.stepOperationalTestsTitle;
      default:
        return code;
    }
  }

  String _stepSummary(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'pre_trip_documentation':
        return l10n.stepPreTripDocumentationSummary;
      case 'exterior_structure':
        return l10n.stepExteriorStructureSummary;
      case 'tires_wheels_axles':
        return l10n.stepTiresWheelsAxlesSummary;
      case 'braking_system':
        return l10n.stepBrakingSystemSummary;
      case 'suspension_steering':
        return l10n.stepSuspensionSteeringSummary;
      case 'engine_powertrain':
        return l10n.stepEnginePowertrainSummary;
      case 'electrical_lighting':
        return l10n.stepElectricalLightingSummary;
      case 'cabin_interior':
        return l10n.stepCabinInteriorSummary;
      case 'coupling_connections':
        return l10n.stepCouplingConnectionsSummary;
      case 'safety_equipment':
        return l10n.stepSafetyEquipmentSummary;
      case 'operational_tests':
        return l10n.stepOperationalTestsSummary;
      default:
        return '';
    }
  }

  List<String> _stepInstructions(BuildContext context, String code) {
    final l10n = context.l10n;
    switch (code) {
      case 'pre_trip_documentation':
        return [
          l10n.stepPreTripDocumentationInstruction1,
          l10n.stepPreTripDocumentationInstruction2,
          l10n.stepPreTripDocumentationInstruction3,
          l10n.stepPreTripDocumentationInstruction4,
        ];
      case 'exterior_structure':
        return [
          l10n.stepExteriorStructureInstruction1,
          l10n.stepExteriorStructureInstruction2,
          l10n.stepExteriorStructureInstruction3,
          l10n.stepExteriorStructureInstruction4,
        ];
      case 'tires_wheels_axles':
        return [
          l10n.stepTiresWheelsAxlesInstruction1,
          l10n.stepTiresWheelsAxlesInstruction2,
          l10n.stepTiresWheelsAxlesInstruction3,
          l10n.stepTiresWheelsAxlesInstruction4,
        ];
      case 'braking_system':
        return [
          l10n.stepBrakingSystemInstruction1,
          l10n.stepBrakingSystemInstruction2,
          l10n.stepBrakingSystemInstruction3,
          l10n.stepBrakingSystemInstruction4,
        ];
      case 'suspension_steering':
        return [
          l10n.stepSuspensionSteeringInstruction1,
          l10n.stepSuspensionSteeringInstruction2,
          l10n.stepSuspensionSteeringInstruction3,
          l10n.stepSuspensionSteeringInstruction4,
        ];
      case 'engine_powertrain':
        return [
          l10n.stepEnginePowertrainInstruction1,
          l10n.stepEnginePowertrainInstruction2,
          l10n.stepEnginePowertrainInstruction3,
          l10n.stepEnginePowertrainInstruction4,
        ];
      case 'electrical_lighting':
        return [
          l10n.stepElectricalLightingInstruction1,
          l10n.stepElectricalLightingInstruction2,
          l10n.stepElectricalLightingInstruction3,
          l10n.stepElectricalLightingInstruction4,
        ];
      case 'cabin_interior':
        return [
          l10n.stepCabinInteriorInstruction1,
          l10n.stepCabinInteriorInstruction2,
          l10n.stepCabinInteriorInstruction3,
          l10n.stepCabinInteriorInstruction4,
        ];
      case 'coupling_connections':
        return [
          l10n.stepCouplingConnectionsInstruction1,
          l10n.stepCouplingConnectionsInstruction2,
          l10n.stepCouplingConnectionsInstruction3,
          l10n.stepCouplingConnectionsInstruction4,
        ];
      case 'safety_equipment':
        return [
          l10n.stepSafetyEquipmentInstruction1,
          l10n.stepSafetyEquipmentInstruction2,
          l10n.stepSafetyEquipmentInstruction3,
          l10n.stepSafetyEquipmentInstruction4,
        ];
      case 'operational_tests':
        return [
          l10n.stepOperationalTestsInstruction1,
          l10n.stepOperationalTestsInstruction2,
          l10n.stepOperationalTestsInstruction3,
          l10n.stepOperationalTestsInstruction4,
        ];
      default:
        return const <String>[];
    }
  }

  String _operationalKeyForIndex(int index) {
    const keys = ['brake_test', 'steering_check', 'engine_start', 'transmission_check'];
    if (index < 0 || index >= keys.length) return keys[0];
    return keys[index];
  }

  Future<void> _handleNext(_GuidedStep step, bool isLast) async {
    if (!_validateCurrentStep(step)) {
      return;
    }
    if (isLast) {
      await _submit();
      return;
    }
    setState(() => _currentStepIndex += 1);
    await _pageController.animateToPage(
      _currentStepIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handlePrevious() async {
    if (_currentStepIndex == 0) {
      return;
    }
    setState(() => _currentStepIndex -= 1);
    await _pageController.animateToPage(
      _currentStepIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep(_GuidedStep step) {
    final formValid = _formKey.currentState?.validate() ?? true;
    if (!formValid) {
      return false;
    }
    if (step.definition.code == 'pre_trip_documentation') {
      if (_selectedVehicle == null) {
        _showError('Select a vehicle before continuing.');
        return false;
      }
      if (_vinController.text.trim().isEmpty) {
        _showError('Scan or enter the VIN to continue.');
        return false;
      }
      if (_plateController.text.trim().isEmpty) {
        _showError('Capture the license plate to continue.');
        return false;
      }
      if (!_identificationVerified) {
        _showError('Confirm that vehicle identification has been verified.');
        return false;
      }
      if ((_stepPhotos[step.definition.code]?.isEmpty ?? true)) {
        _showError('Capture a baseline photo before proceeding.');
        return false;
      }
    }
    if (step.definition.code == 'operational_tests') {
      final incomplete = _operationalChecks.entries.where((entry) => !(entry.value)).map((entry) => entry.key).toList();
      if (incomplete.isNotEmpty) {
        _showError('Complete all operational tests before submitting.');
        return false;
      }
    }
    if (step.definition.requiresTrailer && _trailerNotApplicable) {
      return true;
    }
    if (!_areInstructionsComplete(step)) {
      _showError('Complete the guided actions for ${step.definition.title} before continuing.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final vehicle = _selectedVehicle;
    if (vehicle == null) {
      _showError('Select a vehicle before submitting.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final odometer = int.tryParse(_odometerController.text.replaceAll(',', '')) ?? 0;
      final items = _responses.values
          .map((response) => response.copyWith(photoUris: _photoPaths[response.checklistItemId]))
          .toList();
      final notes = _composeNotes();
      final draft = InspectionDraftModel(
        assignmentId: widget.assignment?.id,
        vehicleId: vehicle.id,
        inspectorId: widget.inspectorId,
        odometerReading: odometer,
        generalNotes: notes,
        items: items,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(draft);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _applyVehicleDefaults(VehicleModel vehicle) {
    _plateController.text = vehicle.licensePlate;
    _vinController.text = vehicle.vin;
    final isTrailer = _isTrailerVehicle(vehicle);
    _trailerNotApplicable = !isTrailer;
    _GuidedStep? couplingStep;
    for (final step in _steps) {
      if (step.definition.code == 'coupling_connections') {
        couplingStep = step;
        break;
      }
    }
    if (_trailerNotApplicable) {
      _skippedSteps.add('coupling_connections');
      if (couplingStep != null) {
        _setInstructionCompletion(couplingStep, true);
      }
    } else {
      _skippedSteps.remove('coupling_connections');
      if (couplingStep != null) {
        _setInstructionCompletion(couplingStep, false);
      }
    }
  }

  bool _isTrailerVehicle(VehicleModel? vehicle) {
    if (vehicle == null) {
      return false;
    }
    final type = vehicle.vehicleType.toLowerCase();
    return type.contains('trailer') || type.contains('semi') || type.contains('tanker') || type.contains('flatbed');
  }

  void _updateResponse(int itemId, {String? result, int? severity, String? notes}) {
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

  Future<void> _addPhotoForItem(_GuidedStep step, ChecklistItemModel item) async {
    final contextTitle = '${step.definition.title} • ${item.title}';
    final path = await _pickAnnotatedPhoto(contextTitle);
    if (path == null) {
      return;
    }
    setState(() {
      final photos = List<String>.from(_photoPaths[item.id] ?? const <String>[]);
      photos.add(path);
      _photoPaths[item.id] = photos;
      _responses[item.id] = _responses[item.id]!.copyWith(photoUris: photos);
    });
  }

  void _removePhotoForItem(_GuidedStep step, ChecklistItemModel item, String path) {
    setState(() {
      final photos = _photoPaths[item.id];
      if (photos == null) {
        return;
      }
      photos.remove(path);
      if (photos.isEmpty) {
        _photoPaths.remove(item.id);
      }
      _responses[item.id] = _responses[item.id]!.copyWith(photoUris: photos);
    });
  }

  Future<void> _addStepPhoto(_GuidedStep step) async {
    final contextTitle = '${step.definition.title} evidence';
    final path = await _pickAnnotatedPhoto(contextTitle);
    if (path == null) {
      return;
    }
    setState(() {
      final photos = List<String>.from(_stepPhotos[step.definition.code] ?? const <String>[]);
      photos.add(path);
      _stepPhotos[step.definition.code] = photos;
    });
  }

  void _removeStepPhoto(_GuidedStep step, String path) {
    setState(() {
      final photos = _stepPhotos[step.definition.code];
      if (photos == null) {
        return;
      }
      photos.remove(path);
      if (photos.isEmpty) {
        _stepPhotos.remove(step.definition.code);
      }
    });
  }

  ScrollController _scrollControllerFor(String stepCode) {
    return _stepScrollControllers.putIfAbsent(stepCode, () => ScrollController());
  }

  Set<int> _instructionStateFor(_GuidedStep step) {
    final completion = _instructionCompletion[step.definition.code];
    return completion == null ? <int>{} : Set<int>.from(completion);
  }

  void _onInstructionToggle(_GuidedStep step, int index, bool value) {
    setState(() {
      final completion = _instructionCompletion.putIfAbsent(step.definition.code, () => <int>{});
      if (value) {
        completion.add(index);
      } else {
        completion.remove(index);
      }
    });
  }

  void _setInstructionCompletion(_GuidedStep step, bool completed) {
    final completion = _instructionCompletion.putIfAbsent(step.definition.code, () => <int>{});
    completion.clear();
    if (completed) {
      for (var i = 0; i < step.definition.instructions.length; i += 1) {
        completion.add(i);
      }
    }
  }

  bool _shouldEnforceInstructions(_GuidedStep step) =>
      step.definition.enforceInstructionCompletion && step.definition.instructions.isNotEmpty;

  bool _areInstructionsComplete(_GuidedStep step) {
    if (!_shouldEnforceInstructions(step)) {
      return true;
    }
    final completion = _instructionCompletion[step.definition.code];
    return completion != null && completion.length == step.definition.instructions.length;
  }

  void _handleTrailerSkipToggle(_GuidedStep step, bool skip) {
    setState(() {
      _trailerNotApplicable = skip;
      if (skip) {
        _skippedSteps.add(step.definition.code);
      } else {
        _skippedSteps.remove(step.definition.code);
      }
      _setInstructionCompletion(step, skip);
    });
  }

  Future<String?> _pickAnnotatedPhoto(String contextTitle) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _PhotoSourceSheet(contextTitle: contextTitle),
    );
    if (source == null) {
      return null;
    }
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) {
      return null;
    }
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      final annotated = await PhotoAnnotationScreen.open(
        context,
        imageBytes: bytes,
        contextTitle: contextTitle,
      );
      return annotated;
    } else {
      final annotated = await PhotoAnnotationScreen.open(
        context,
        imageFile: File(picked.path),
        contextTitle: contextTitle,
      );
      return annotated;
    }
  }

  Future<void> _startScan({required String title, required ValueChanged<String> onValue}) async {
    final captured = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => _BarcodeScannerScreen(title: title)),
    );
    if (captured == null || captured.trim().isEmpty) {
      return;
    }
    onValue(captured.trim().toUpperCase());
  }

  int? _extractOdometer(String remarks) {
    final pattern = RegExp(r'ODO:(\d+)');
    final match = pattern.firstMatch(remarks);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  String _composeNotes() {
    final buffer = StringBuffer();
    buffer.writeln('VIN captured: ${_vinController.text.trim()}');
    buffer.writeln('License plate: ${_plateController.text.trim()}');
    buffer.writeln('Vehicle identification verified: ${_identificationVerified ? 'Yes' : 'No'}');
    if (_vehicleConditionController.text.trim().isNotEmpty) {
      buffer.writeln('\nVehicle condition:\n${_vehicleConditionController.text.trim()}');
    }
    if (_identificationNotesController.text.trim().isNotEmpty) {
      buffer.writeln('\nIdentification notes:\n${_identificationNotesController.text.trim()}');
    }
    for (final step in _steps) {
      if (step.definition.instructions.isNotEmpty) {
        buffer.writeln('\n${step.definition.title} guided actions:');
        final completion = _instructionCompletion[step.definition.code] ?? const <int>{};
        for (var i = 0; i < step.definition.instructions.length; i += 1) {
          final indicator = completion.contains(i) ? '✓' : '○';
          buffer.writeln('$indicator ${step.definition.instructions[i]}');
        }
      }
      final generalStepPhotos = _stepPhotos[step.definition.code] ?? const <String>[];
      if (generalStepPhotos.isNotEmpty) {
        buffer.writeln('Step evidence photos: ${generalStepPhotos.length}');
      }
      final checklistPhotoEntries = step.items
          .map((item) => MapEntry(item.title, _photoPaths[item.id] ?? const <String>[]))
          .where((entry) => entry.value.isNotEmpty)
          .toList();
      if (checklistPhotoEntries.isNotEmpty) {
        buffer.writeln('Checklist item photos:');
        for (final entry in checklistPhotoEntries) {
          buffer.writeln('• ${entry.key}: ${entry.value.length}');
        }
      }
      final note = _stepNotesControllers[step.definition.code]?.text.trim();
      if (note == null || note.isEmpty) {
        continue;
      }
      buffer.writeln('\n${step.definition.title} notes:\n$note');
    }
    buffer.writeln('\nOperational tests:');
    buffer.writeln('• Brake test: ${_operationalChecks['brake_test']! ? 'Completed' : 'Not completed'}');
    buffer.writeln('• Steering check: ${_operationalChecks['steering_check']! ? 'Completed' : 'Not completed'}');
    buffer.writeln('• Engine start & idle: ${_operationalChecks['engine_start']! ? 'Completed' : 'Not completed'}');
    buffer.writeln('• Transmission test: ${_operationalChecks['transmission_check']! ? 'Completed' : 'Not completed'}');
    if (_operationalNotesController.text.trim().isNotEmpty) {
      buffer.writeln('\nOperational observations:\n${_operationalNotesController.text.trim()}');
    }
    if (_generalNotesController.text.trim().isNotEmpty) {
      buffer.writeln('\nFinal summary:\n${_generalNotesController.text.trim()}');
    }
    return buffer.toString().trim();
  }
}

class _GuidedStep {
  _GuidedStep({required this.definition, required this.category});

  final GuidedInspectionStepDefinition definition;
  final InspectionCategoryModel? category;

  List<ChecklistItemModel> get items => category?.items ?? const <ChecklistItemModel>[];
}

class _StepIntroCard extends StatelessWidget {
  const _StepIntroCard({
    required this.step,
    required this.completedIndices,
    required this.onToggle,
    this.enabled = true,
  });

  final _GuidedStep step;
  final Set<int> completedIndices;
  final void Function(int index, bool value) onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instructions = _stepInstructions(context, step.definition.code);
    final completedCount = completedIndices.length.clamp(0, instructions.length).toInt();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_stepTitle(context, step.definition.code), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_stepSummary(context, step.definition.code), style: theme.textTheme.bodyMedium),
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(context.l10n.guidedActionsLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(context.l10n.guidedActionsProgress(completedCount, instructions.length), style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(
                instructions.length,
                (index) => CheckboxListTile(
                  value: completedIndices.contains(index),
                  onChanged: enabled
  ? (value) => onToggle(index, value ?? false)
  : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(instructions[index], style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
            if (!enabled) ...[
              const SizedBox(height: 12),
              Text(context.l10n.stepMarkedNotApplicable,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OperationalCheckTile extends StatelessWidget {
  const _OperationalCheckTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle),
      controlAffinity: ListTileControlAffinity.leading,
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
    super.key,
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
    final hasFailure = response.result == InspectionItemResponse.RESULT_FAIL;
    final severityLabel = _severityLabel(response.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  child: Text('Photo required', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: InspectionItemResponse.RESULT_PASS, label: Text('Pass'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment<String>(value: InspectionItemResponse.RESULT_FAIL, label: Text('Fail'), icon: Icon(Icons.error_outline)),
              ButtonSegment<String>(value: InspectionItemResponse.RESULT_NA, label: Text('N/A'), icon: Icon(Icons.help_outline)),
            ],
            selected: <String>{response.result},
            onSelectionChanged: (values) => onResultChanged(values.first),
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
              const SizedBox(width: 12),
              Icon(hasFailure ? Icons.warning_rounded : Icons.verified_outlined, color: hasFailure ? theme.colorScheme.error : theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: response.notes,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
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
            title: 'Photo evidence',
            photos: photos,
            onAdd: onAddPhoto,
            onRemove: onRemovePhoto,
            requiresPhoto: requiresPhoto,
            helperText: requiresPhoto
                ? 'Capture at least one annotated photo when recording a failure.'
                : 'Optional — attach reference photos for this checklist item.',
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
    required this.title,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.requiresPhoto,
    this.helperText,
  });

  final String title;
  final List<String> photos;
  final Future<void> Function() onAdd;
  final ValueChanged<String> onRemove;
  final bool requiresPhoto;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (requiresPhoto)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.star, size: 14, color: theme.colorScheme.error),
              ),
            const Spacer(),
            TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Add')),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text(
                helperText ??
                    (requiresPhoto
                        ? 'Capture at least one photo when documenting a defect.'
                        : 'Optional — attach supporting photos for this step.'),
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
                        child: path.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(path.split(',').last),
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
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
  const _PhotoSourceSheet({required this.contextTitle});

  final String contextTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          controller: PrimaryScrollController.of(context),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attach photo for "$contextTitle"', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ],
          ),
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

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen({required this.title});

  final String title;

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _captured = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(torchEnabled: false, facing: CameraFacing.back);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_captured) {
                return;
              }
              final codes = capture.barcodes;
              if (codes.isEmpty) {
                return;
              }
              final value = codes.first.rawValue;
              if (value == null || value.trim().isEmpty) {
                return;
              }
              _captured = true;
              Navigator.of(context).pop(value);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Align the barcode within the frame to capture.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
