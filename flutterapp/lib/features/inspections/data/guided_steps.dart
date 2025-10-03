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
    this.enforceInstructionCompletion = true,
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
  final bool enforceInstructionCompletion;
}

class GuidedInspectionStepLookup {
  GuidedInspectionStepLookup(this.steps);

  final List<GuidedInspectionStepDefinition> steps;

  GuidedInspectionStepDefinition? operator [](String code) {
    for (final definition in steps) {
      if (definition.code == code) {
        return definition;
      }
    }
    return null;
  }
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
      'Scan the VIN or license plate using the guided scanner overlay.',
      'Input the odometer and engine hours directly from the dashboard.',
      'Document the overall vehicle condition with baseline photos and notes.',
      'Verify vehicle identification against assignment paperwork before proceeding.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 2,
    code: 'exterior_structure',
    title: 'Exterior & Structural Inspection',
    summary: 'Complete a clockwise walk-around, logging any structural defects with annotated photo proof.',
    categoryCode: 'exterior_structure',
    instructions: <String>[
      'Follow the guided walk-around indicators to cover front, sides, roofline, and rear.',
      'Document dents, cracks, rust, or loose body panels with annotated photo evidence.',
      'Check frame rails, crossmembers, and chassis mounting points for structural damage.',
      'Attach photo evidence for any exterior or structural defect before continuing.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 3,
    code: 'tires_wheels_axles',
    title: 'Tires, Wheels, & Axles',
    summary: 'Measure and record tire health, wheel hardware, and axle condition for every wheel position.',
    categoryCode: 'tires_wheels_axles',
    instructions: <String>[
      'Measure and record tire pressure for every wheel position.',
      'Capture tread depth readings and note irregular wear patterns.',
      'Inspect sidewalls for cuts, bulges, or exposed cords and document defects.',
      'Check wheel rims, lug torque indicators, axles, and bearings for looseness or leaks.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 4,
    code: 'braking_system',
    title: 'Braking System',
    summary: 'Assess service, emergency, and parking brake components with evidence of wear conditions.',
    categoryCode: 'braking_system',
    instructions: <String>[
      'Inspect brake pads or shoes, drums, and rotors for thickness and heat checking.',
      'Document hydraulic or air brake components, hoses, and fittings for leaks or wear.',
      'Check supply lines, reservoirs, and valves for chafing or improper routing.',
      'Test parking brake application and record responsiveness.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 5,
    code: 'suspension_steering',
    title: 'Suspension & Steering',
    summary: 'Evaluate stability and alignment components, ensuring safe handling performance.',
    categoryCode: 'suspension_steering',
    instructions: <String>[
      'Check springs, shock absorbers, and air bags for leaks, cracks, or uneven ride height.',
      'Inspect steering linkage, tie rods, and kingpins for free play or damage.',
      'Document suspension mounts, bushings, torque arms, and u-bolts for wear.',
      'Confirm alignment indicators and steering wheel centering.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 6,
    code: 'engine_powertrain',
    title: 'Engine & Powertrain',
    summary: 'Capture engine bay health including fluids, belts, and drivetrain integrity.',
    categoryCode: 'engine_powertrain',
    instructions: <String>[
      'Verify oil, coolant, transmission, DEF, and hydraulic fluid levels are within range.',
      'Inspect belts, hoses, clamps, and air filters for cracking or looseness.',
      'Document exhaust system condition, mounts, and evidence of leaks.',
      'Check drivetrain components, seals, and housings for leaks or abnormal noise.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 7,
    code: 'electrical_lighting',
    title: 'Electrical & Lighting',
    summary: 'Systematically test all lighting circuits and core electrical systems.',
    categoryCode: 'electrical_lighting',
    instructions: <String>[
      'Run the systematic lighting test covering headlights, tail lights, and brake lights.',
      'Cycle turn signals, marker lights, and hazard flashers verifying synchronization.',
      'Inspect interior lighting, dashboard instruments, and warning indicators.',
      'Check batteries, wiring harnesses, and connectors for corrosion or loose terminals.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 8,
    code: 'cabin_interior',
    title: 'Cabin & Interior',
    summary: 'Validate driver safety equipment, visibility systems, and control panel readiness.',
    categoryCode: 'cabin_interior',
    instructions: <String>[
      'Verify seat belts, seat tracks, and headrests for secure operation.',
      'Inspect mirrors, windshield, wipers, washers, and defrosters for visibility.',
      'Test dashboard instruments, controls, HVAC, and infotainment systems.',
      'Confirm emergency equipment, paperwork, and safety signage are accessible.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 9,
    code: 'coupling_connections',
    title: 'Coupling & Connections',
    summary: 'Verify trailer coupling, lines, and safety connections where applicable.',
    categoryCode: 'coupling_connections',
    instructions: <String>[
      'Inspect fifth wheel, kingpin, pintle, or gooseneck components for secure locking and wear.',
      'Verify safety chains, breakaway cables, and locking pins are present and undamaged.',
      'Check electrical connectors, glad hands, and air lines for leaks or abrasion.',
      'Capture supporting photos for any missing or worn coupling hardware.',
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
      'Check fire extinguisher charge level, inspection tag, and security seal.',
      'Verify warning triangles, flares, and reflective devices are present and serviceable.',
      'Confirm first aid kit, spill kit, and PPE inventory is complete.',
      'Document any missing or deficient safety equipment with photos.',
    ],
  ),
  GuidedInspectionStepDefinition(
    order: 11,
    code: 'operational_tests',
    title: 'Operational Tests',
    summary: 'Close the inspection with dynamic operational checks before releasing the vehicle.',
    categoryCode: 'operational_tests',
    instructions: <String>[
      'Conduct brake responsiveness test noting pedal feel and stopping distance.',
      'Cycle steering lock-to-lock listening for abnormal noises or resistance.',
      'Start the engine, observe idle quality, warning lights, and vibrations.',
      'Perform transmission shifting test verifying smooth engagement in all ranges.',
    ],
  ),
];

final GuidedInspectionStepLookup guidedStepLookup = GuidedInspectionStepLookup(guidedInspectionSteps);
