import 'package:flutter/widgets.dart';

enum AppLanguage { en, sw }

class AppStrings {
  AppStrings._();

  static AppLanguage _language = AppLanguage.en;
  static void setLanguageCode(String? code) {
    _language = code == 'sw' ? AppLanguage.sw : AppLanguage.en;
  }

  static AppStrings get current => AppStrings._();

  // General
  String get appTitle => 'Fleet Inspection';
  String get appTitleShort => 'Fleet Inspection';

  // Language menu
  String get languageMenuTooltip => 'Change language';
  String get languageMenuSystem => 'System default';
  String get languageMenuEnglish => 'English';
  String get languageMenuSwahili => 'Kiswahili';

  // Login
  String get loginTitle => 'Sign in to your account';
  String get loginSubtitle => 'Enter your credentials to continue';
  String get loginUsernameLabel => 'Username';
  String get loginUsernameRequired => 'Username is required';
  String get loginPasswordLabel => 'Password';
  String get loginPasswordRequired => 'Password is required';
  String get commonSignIn => 'Sign in';
  String get commonSignOut => 'Sign out';

  // Unsupported role
  String unsupportedGreeting(String name) => 'Hello $name';
  String get unsupportedMessage =>
      'Your account role is not supported in the mobile app. Please use the web portal.';

  // Guided inspection
  String get guidedInspectionTitle => 'Guided Inspection';
  String get discardTooltip => 'Discard';
  String stepProgress(int current, int total) => 'Step $current of $total';

  // Navigation labels
  String get backLabel => 'Back';
  String get submitInspectionLabel => 'Submit inspection';
  String get nextStepLabel => 'Next step';

  // Pre-check validations/messages
  String get selectVehicleBeforeContinuing => 'Select a vehicle before continuing.';
  String get scanOrEnterVin => 'Scan or enter the VIN to continue.';
  String get captureLicensePlateToContinue => 'Capture the license plate to continue.';
  String get confirmIdentificationVerified => 'Confirm that vehicle identification has been verified.';
  String get captureBaselinePhoto => 'Capture a baseline photo before proceeding.';
  String get completeOperationalTests => 'Complete all operational tests before submitting.';
  String completeGuidedActions(String step) => 'Complete the guided actions for $step before continuing.';
  String get selectVehicleBeforeSubmitting => 'Select a vehicle before submitting.';

  // Results
  String get inspectionSubmitted => 'Inspection submitted successfully.';
  String get inspectionSavedOffline => 'Inspection saved offline and will sync when online.';

  // Quick actions
  String get quickActionsNewInspection => 'New inspection';
  String get quickActionsSyncOffline => 'Sync offline';
  String get quickActionsRefresh => 'Refresh';
  String get syncingShort => 'Syncing…';
  String syncedCount(int count) => 'Synced $count inspection(s).';
  String get syncedNone => 'No inspections waiting for sync.';

  // Add vehicle dialog
  String get addVehicleTitle => 'Add vehicle';
  String get licensePlateLabelShort => 'License plate';
  String get vinLabelShort => 'VIN';
  String get yearLabel => 'Year';
  String get vehicleTypeLabel => 'Vehicle type';
  String get mileageLabel => 'Mileage';
  String get notesLabel => 'Notes';
  String get cancelLabel => 'Cancel';
  String get saveLabel => 'Save';
  String get vehicleAdded => 'Vehicle added.';

  // Photo annotation
  String photoAnnotateTitle(String contextTitle) => 'Annotate $contextTitle';
  String get clearAllTooltip => 'Clear all';
  String get undoTooltip => 'Undo';
  String get unableToLoadImage => 'Unable to load image.';
  String strokeWidthLabel(int width) => 'Stroke width: $width';
  String get saveLabelShort => 'Save';
  String get unableToSaveAnnotatedPhoto => 'Unable to save annotated photo.';

  // Photo attach sheet
  String attachPhotoFor(String contextTitle) => 'Attach photo for "$contextTitle"';
  String get useCamera => 'Use camera';
  String get useCameraSubtitle => 'Capture real-time evidence';
  String get uploadFromGallery => 'Upload from gallery';
  String get uploadFromGallerySubtitle => 'Select from existing photos';

  // Guided actions
  String get guidedActionsLabel => 'Guided actions';
  String guidedActionsProgress(int completed, int total) => '$completed of $total completed';
  String get stepMarkedNotApplicable => 'Step marked as not applicable for this inspection.';
  String get photoRequiredLabel => 'Photo required';

  // Segmented control
  String get segmentedPass => 'Pass';
  String get segmentedFail => 'Fail';
  String get segmentedNA => 'N/A';

  // Severity
  String get severityLabel => 'Severity';
  String get severityMinor => 'Minor';
  String get severityLow => 'Low';
  String get severityModerate => 'Moderate';
  String get severityHigh => 'High';
  String get severityCritical => 'Critical';
  String get severityUnknown => 'Unknown';

  // Notes/photos
  String get notesFieldLabel => 'Notes';
  String get photoEvidenceRequiredForFailure => 'Photo evidence is required for failures.';
  String get captureAtLeastOneAnnotatedPhoto => 'Capture at least one annotated photo when recording a failure.';
  String get optionalAttachReferencePhotos => 'Optional — attach reference photos for this checklist item.';
  String get photoEvidenceLabel => 'Photo evidence';
  String get alignBarcodeHint => 'Align the barcode within the frame to capture.';

  // Step titles, summaries, and instructions
  String get stepPreTripDocumentationTitle => 'Pre-Trip Documentation';
  String get stepPreTripDocumentationSummary =>
      'Confirm vehicle identity, capture baseline readings, and note any pre-existing conditions before physical checks begin.';
  String get stepPreTripDocumentationInstruction1 =>
      'Scan the VIN or license plate using the guided scanner overlay.';
  String get stepPreTripDocumentationInstruction2 =>
      'Input the odometer and engine hours directly from the dashboard.';
  String get stepPreTripDocumentationInstruction3 =>
      'Document the overall vehicle condition with baseline photos and notes.';
  String get stepPreTripDocumentationInstruction4 =>
      'Verify vehicle identification against assignment paperwork before proceeding.';

  String get stepExteriorStructureTitle => 'Exterior & Structural Inspection';
  String get stepExteriorStructureSummary =>
      'Complete a clockwise walk-around, logging any structural defects with annotated photo proof.';
  String get stepExteriorStructureInstruction1 =>
      'Follow the guided walk-around indicators to cover front, sides, roofline, and rear.';
  String get stepExteriorStructureInstruction2 =>
      'Document dents, cracks, rust, or loose body panels with annotated photo evidence.';
  String get stepExteriorStructureInstruction3 =>
      'Check frame rails, crossmembers, and chassis mounting points for structural damage.';
  String get stepExteriorStructureInstruction4 =>
      'Attach photo evidence for any exterior or structural defect before continuing.';

  String get stepTiresWheelsAxlesTitle => 'Tires, Wheels, & Axles';
  String get stepTiresWheelsAxlesSummary =>
      'Measure and record tire health, wheel hardware, and axle condition for every wheel position.';
  String get stepTiresWheelsAxlesInstruction1 =>
      'Measure and record tire pressure for every wheel position.';
  String get stepTiresWheelsAxlesInstruction2 =>
      'Capture tread depth readings and note irregular wear patterns.';
  String get stepTiresWheelsAxlesInstruction3 =>
      'Inspect sidewalls for cuts, bulges, or exposed cords and document defects.';
  String get stepTiresWheelsAxlesInstruction4 =>
      'Check wheel rims, lug torque indicators, axles, and bearings for looseness or leaks.';

  String get stepBrakingSystemTitle => 'Braking System';
  String get stepBrakingSystemSummary =>
      'Assess service, emergency, and parking brake components with evidence of wear conditions.';
  String get stepBrakingSystemInstruction1 =>
      'Inspect brake pads or shoes, drums, and rotors for thickness and heat checking.';
  String get stepBrakingSystemInstruction2 =>
      'Document hydraulic or air brake components, hoses, and fittings for leaks or wear.';
  String get stepBrakingSystemInstruction3 =>
      'Check supply lines, reservoirs, and valves for chafing or improper routing.';
  String get stepBrakingSystemInstruction4 =>
      'Test parking brake application and record responsiveness.';

  String get stepSuspensionSteeringTitle => 'Suspension & Steering';
  String get stepSuspensionSteeringSummary =>
      'Evaluate stability and alignment components, ensuring safe handling performance.';
  String get stepSuspensionSteeringInstruction1 =>
      'Check springs, shock absorbers, and air bags for leaks, cracks, or uneven ride height.';
  String get stepSuspensionSteeringInstruction2 =>
      'Inspect steering linkage, tie rods, and kingpins for free play or damage.';
  String get stepSuspensionSteeringInstruction3 =>
      'Document suspension mounts, bushings, torque arms, and u-bolts for wear.';
  String get stepSuspensionSteeringInstruction4 =>
      'Confirm alignment indicators and steering wheel centering.';

  String get stepEnginePowertrainTitle => 'Engine & Powertrain';
  String get stepEnginePowertrainSummary =>
      'Capture engine bay health including fluids, belts, and drivetrain integrity.';
  String get stepEnginePowertrainInstruction1 =>
      'Verify oil, coolant, transmission, DEF, and hydraulic fluid levels are within range.';
  String get stepEnginePowertrainInstruction2 =>
      'Inspect belts, hoses, clamps, and air filters for cracking or looseness.';
  String get stepEnginePowertrainInstruction3 =>
      'Document exhaust system condition, mounts, and evidence of leaks.';
  String get stepEnginePowertrainInstruction4 =>
      'Check drivetrain components, seals, and housings for leaks or abnormal noise.';

  String get stepElectricalLightingTitle => 'Electrical & Lighting';
  String get stepElectricalLightingSummary =>
      'Systematically test all lighting circuits and core electrical systems.';
  String get stepElectricalLightingInstruction1 =>
      'Run the systematic lighting test covering headlights, tail lights, and brake lights.';
  String get stepElectricalLightingInstruction2 =>
      'Cycle turn signals, marker lights, and hazard flashers verifying synchronization.';
  String get stepElectricalLightingInstruction3 =>
      'Inspect interior lighting, dashboard instruments, and warning indicators.';
  String get stepElectricalLightingInstruction4 =>
      'Check batteries, wiring harnesses, and connectors for corrosion or loose terminals.';

  String get stepCabinInteriorTitle => 'Cabin & Interior';
  String get stepCabinInteriorSummary =>
      'Validate driver safety equipment, visibility systems, and control panel readiness.';
  String get stepCabinInteriorInstruction1 =>
      'Verify seat belts, seat tracks, and headrests for secure operation.';
  String get stepCabinInteriorInstruction2 =>
      'Inspect mirrors, windshield, wipers, washers, and defrosters for visibility.';
  String get stepCabinInteriorInstruction3 =>
      'Test dashboard instruments, controls, HVAC, and infotainment systems.';
  String get stepCabinInteriorInstruction4 =>
      'Confirm emergency equipment, paperwork, and safety signage are accessible.';

  String get stepCouplingConnectionsTitle => 'Coupling & Connections';
  String get stepCouplingConnectionsSummary =>
      'Verify trailer coupling, lines, and safety connections where applicable.';
  String get stepCouplingConnectionsInstruction1 =>
      'Inspect fifth wheel, kingpin, pintle, or gooseneck components for secure locking and wear.';
  String get stepCouplingConnectionsInstruction2 =>
      'Verify safety chains, breakaway cables, and locking pins are present and undamaged.';
  String get stepCouplingConnectionsInstruction3 =>
      'Check electrical connectors, glad hands, and air lines for leaks or abrasion.';
  String get stepCouplingConnectionsInstruction4 =>
      'Capture supporting photos for any missing or worn coupling hardware.';

  String get stepSafetyEquipmentTitle => 'Safety Equipment';
  String get stepSafetyEquipmentSummary =>
      'Confirm emergency preparedness equipment is present, charged, and within service dates.';
  String get stepSafetyEquipmentInstruction1 =>
      'Check fire extinguisher charge level, inspection tag, and security seal.';
  String get stepSafetyEquipmentInstruction2 =>
      'Verify warning triangles, flares, and reflective devices are present and serviceable.';
  String get stepSafetyEquipmentInstruction3 =>
      'Confirm first aid kit, spill kit, and PPE inventory is complete.';
  String get stepSafetyEquipmentInstruction4 =>
      'Document any missing or deficient safety equipment with photos.';

  String get stepOperationalTestsTitle => 'Operational Tests';
  String get stepOperationalTestsSummary =>
      'Close the inspection with dynamic operational checks before releasing the vehicle.';
  String get stepOperationalTestsInstruction1 =>
      'Conduct brake responsiveness test noting pedal feel and stopping distance.';
  String get stepOperationalTestsInstruction2 =>
      'Cycle steering lock-to-lock listening for abnormal noises or resistance.';
  String get stepOperationalTestsInstruction3 =>
      'Start the engine, observe idle quality, warning lights, and vibrations.';
  String get stepOperationalTestsInstruction4 =>
      'Perform transmission shifting test verifying smooth engagement in all ranges.';
}
