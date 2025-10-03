import 'package:collection/collection.dart';

class GuidedInspectionStepDefinition {
  const GuidedInspectionStepDefinition({
    required this.order,
    required this.code,
    required this.title,
    required this.summary,
    this.categoryCode,
    this.instructions = const <String>[],
    this.requiresVehicleSelection = false,
    this.optional = false,
    this.requiresTrailer = false,
  });

  final int order;
  final String code;
  final String title;
  final String summary;
  final String? categoryCode;
  final List<String> instructions;
  final bool requiresVehicleSelection;
  final bool optional;
  final bool requiresTrailer;
}

class GuidedInspectionStepLookup {
  GuidedInspectionStepLookup(this.steps);

  final List<GuidedInspectionStepDefinition> steps;

  GuidedInspectionStepDefinition? operator [](String code) =>
      steps.firstWhereOrNull((definition) => definition.code == code);
}

const List<GuidedInspectionStepDefinition> guidedInspectionSteps = <GuidedInspectionStepDefinition>[
  GuidedInspectionStepDefinition(
    order: 1,
    code: 'pre_trip_documentation',
    title: 'Pre-Trip Documentation',
    summary:
        'Confirm vehicle identity, capture baseline readings, and note any pre-existing conditions before physical checks begin.',
    categoryCode: 'pre_trip_documentation',
    requiresVehicleSelection: true,
    instructions: <String>[
      'Scan the VIN or license plate to automatically capture identifiers.',
      'Input current odometer and engine hour readings manually if scanning is unavailable.',
      'Capture a panoramic photo of the vehicle to document pre-inspection condition.',
      'Verify assignment details and match them with the vehicle tag or paperwork.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 2,
    code: 'exterior_structure',
    title: 'Exterior & Structural Inspection',
    summary: 'Complete a clockwise walk-around, logging any structural defects with annotated photo proof.',
    categoryCode: 'exterior_structure',
    instructions: <String>[
      'Follow on-screen hotspots to cover bumpers, doors, roofline, and undercarriage points.',
      'Document dents, cracks, corrosion, or loose panels with annotated photos.',
      'Check frame rails, crossmembers, and chassis mounting points for damage.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 3,
    code: 'tires_wheels_axles',
    title: 'Tires, Wheels, & Axles',
    summary: 'Measure and record tire health, wheel hardware, and axle condition for every wheel position.',
    categoryCode: 'tires_wheels_axles',
    instructions: <String>[
      'Record tread depth and tire pressure readings for inner and outer tires.',
      'Inspect sidewalls for bulges, cuts, or exposed cords and photograph issues.',
      'Check hub seals, axle housings, and lug torque indicators.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 4,
    code: 'braking_system',
    title: 'Braking System',
    summary: 'Assess service, emergency, and parking brake components with evidence of wear conditions.',
    categoryCode: 'braking_system',
    instructions: <String>[
      'Capture lining thickness where visible and document any heat checking or glazing.',
      'Verify hydraulic or air lines for leaks, securing clips, and chafing.',
      'Test parking brake application and record response.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 5,
    code: 'suspension_steering',
    title: 'Suspension & Steering',
    summary: 'Evaluate stability and alignment components, ensuring safe handling performance.',
    categoryCode: 'suspension_steering',
    instructions: <String>[
      'Inspect springs, shocks, and air bags for leaks or uneven ride height.',
      'Check steering linkage, tie rods, and kingpins for play, wear, or damage.',
      'Document mounting hardware, bushings, and torque arms.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 6,
    code: 'engine_powertrain',
    title: 'Engine & Powertrain',
    summary: 'Capture engine bay health including fluids, belts, and drivetrain integrity.',
    categoryCode: 'engine_powertrain',
    instructions: <String>[
      'Verify oil, coolant, transmission, DEF, and hydraulic fluid levels.',
      'Check belts, hoses, and filters for cracking or loose clamps.',
      'Document exhaust leaks, mounts, and drivetrain connections.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 7,
    code: 'electrical_lighting',
    title: 'Electrical & Lighting',
    summary: 'Systematically test all lighting circuits and core electrical systems.',
    categoryCode: 'electrical_lighting',
    instructions: <String>[
      'Use assisted testing to step through headlights, turn signals, and marker lights.',
      'Verify brake lights and ABS indicators with a brake application check.',
      'Inspect batteries, cables, and harnesses for corrosion or loose connections.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 8,
    code: 'cabin_interior',
    title: 'Cabin & Interior',
    summary: 'Validate driver safety equipment, visibility systems, and control panel readiness.',
    categoryCode: 'cabin_interior',
    instructions: <String>[
      'Test seat belts, seats, and mirrors for secure operation.',
      'Check windshield, wipers, washers, and defrosters for full coverage.',
      'Confirm gauges, warning lights, and control switches operate.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 9,
    code: 'coupling_connections',
    title: 'Coupling & Connections',
    summary: 'Verify trailer coupling, lines, and safety connections where applicable.',
    categoryCode: 'coupling_connections',
    instructions: <String>[
      'Inspect fifth wheel or kingpin components for secure locking and wear.',
      'Verify safety chains, breakaway cables, and locking pins are present.',
      'Check glad hands, airlines, and electrical cords for leaks and abrasion.',
    ],
    optional: true,
    requiresTrailer: true,
  ),
  GuidedInspectionStepDefinition(
    order: 10,
    code: 'safety_equipment',
    title: 'Safety Equipment',
    summary: 'Confirm emergency preparedness equipment is present, charged, and within service dates.',
    categoryCode: 'safety_equipment',
    instructions: <String>[
      'Inspect fire extinguishers for charge, seal, and inspection date.',
      'Verify triangles, flares, first-aid, and PPE are stocked and accessible.',
      'Capture photos of missing or deficient equipment.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 11,
    code: 'operational_tests',
    title: 'Operational Tests',
    summary: 'Close the inspection with dynamic operational checks before releasing the vehicle.',
    categoryCode: 'operational_tests',
    instructions: <String>[
      'Conduct brake responsiveness tests in a safe area and record pedal feel.',
      'Cycle steering lock-to-lock listening for abnormal noises or resistance.',
      'Start the engine, observe idle, warning lights, and note any vibration.',
    ],
  ),
];

final GuidedInspectionStepLookup guidedStepLookup = GuidedInspectionStepLookup(guidedInspectionSteps);
