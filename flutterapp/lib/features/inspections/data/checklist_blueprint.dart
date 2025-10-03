import 'models.dart';

class ChecklistGuidePoint {
  const ChecklistGuidePoint({
    required this.label,
    this.description = '',
    this.requiresPhoto = false,
  });

  final String label;
  final String description;
  final bool requiresPhoto;
}

class ChecklistGuideEntry {
  const ChecklistGuideEntry({
    required this.code,
    required this.title,
    required this.summary,
    required this.steps,
    required this.points,
  });

  final String code;
  final String title;
  final String summary;
  final List<String> steps;
  final List<ChecklistGuidePoint> points;
}

class ChecklistCategoryBlueprint {
  const ChecklistCategoryBlueprint({
    required this.code,
    required this.title,
    required this.summary,
    required this.steps,
  });

  final String code;
  final String title;
  final String summary;
  final List<String> steps;
}

const List<ChecklistCategoryBlueprint> fleetChecklistBlueprint = <ChecklistCategoryBlueprint>[
  ChecklistCategoryBlueprint(
    code: 'pre_trip_documentation',
    title: 'Pre-Trip Documentation',
    summary: 'Collect identifiers, readings, and baseline condition evidence before touching the vehicle.',
    steps: <String>[
      'Scan the VIN or license plate using the in-app scanner to capture identifiers.',
      'Enter odometer and engine hour readings directly from the dashboard.',
      'Capture panoramic baseline photos and describe the vehicle condition.',
      'Verify paperwork and assignment records match the vehicle on-site.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'exterior_structure',
    title: 'Exterior & Structure',
    summary: 'Use the guided walk-around to document structural integrity and exterior condition.',
    steps: <String>[
      'Follow the on-screen walk-around path covering front, sides, roofline, and rear.',
      'Capture dents, cracks, corrosion, or loose panels with annotated photo evidence.',
      'Inspect frame rails, crossmembers, and chassis mounts for structural damage.',
      'Log every defect with supporting notes before progressing to the next area.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'tires_wheels_axles',
    title: 'Tires, Wheels, & Axles',
    summary: 'Capture tire health, wheel security, and axle condition for every position.',
    steps: <String>[
      'Measure and record tire pressure and tread depth for each wheel position.',
      'Inspect sidewalls for cuts, bulges, exposed cords, or irregular wear.',
      'Check wheel rims, lug torque indicators, hubs, and seals for looseness or leaks.',
      'Document axle housings and bearings, noting leaks or abnormal noises.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'braking_system',
    title: 'Braking System',
    summary: 'Validate stopping components, lines, and controls before drive testing.',
    steps: <String>[
      'Inspect brake pads or shoes, drums, rotors, and adjusters for wear or glazing.',
      'Document the condition of hydraulic or air brake components, hoses, and fittings.',
      'Check supply lines, reservoirs, and valves for leaks, chafing, or loose clamps.',
      'Test parking brake hold strength and ABS indicator behavior.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'suspension_steering',
    title: 'Suspension & Steering',
    summary: 'Ensure steering precision and suspension stability for safe operation.',
    steps: <String>[
      'Check springs, shock absorbers, and air bags for leaks, cracks, or uneven ride height.',
      'Inspect steering linkage, tie rods, drag links, and kingpins for free play.',
      'Document bushings, torque arms, and mounting hardware for wear or looseness.',
      'Confirm alignment indicators and steering wheel centering during a short roll.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'engine_powertrain',
    title: 'Engine & Powertrain',
    summary: 'Document fluid health, component wear, and drivetrain integrity.',
    steps: <String>[
      'Verify oil, coolant, transmission, DEF, and hydraulic fluid levels are within limits.',
      'Inspect belts, hoses, clamps, and filters for cracking, fraying, or loose fittings.',
      'Document exhaust routing, mounts, and any evidence of leaks or soot trails.',
      'Review drivetrain components, seals, and housings for leaks or abnormal noise.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'electrical_lighting',
    title: 'Electrical & Lighting',
    summary: 'Run the systematic lighting test and inspect core electrical components.',
    steps: <String>[
      'Use the guided lighting test to cycle headlights, tail lamps, brake lights, and markers.',
      'Verify turn signals, hazards, and marker lights synchronize correctly.',
      'Inspect interior lighting, dash indicators, warning chimes, and gauges.',
      'Check batteries, harnesses, and connectors for corrosion, damage, or loose terminals.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'cabin_interior',
    title: 'Cabin & Interior',
    summary: 'Validate occupant safety, visibility, and control readiness.',
    steps: <String>[
      'Verify seat belts, seat tracks, headrests, and airbags for secure operation.',
      'Inspect mirrors, windshield, wipers, washers, and defrosters for clear visibility.',
      'Test dashboard controls, gauges, HVAC, and infotainment responsiveness.',
      'Confirm emergency equipment, logbooks, and permits are accessible inside the cab.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'coupling_connections',
    title: 'Coupling & Connections',
    summary: 'Confirm safe trailer attachment, safety devices, and service lines.',
    steps: <String>[
      'Inspect fifth wheel, kingpin, pintle, or gooseneck assemblies for wear and secure locking.',
      'Verify safety chains, breakaway cables, and locking pins are present and functional.',
      'Check electrical connectors, glad hands, and airlines for leaks, abrasion, or misalignment.',
      'Capture photo evidence of any coupling or connection wear before departure.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'trailer_equipment',
    title: 'Trailer-Specific Equipment',
    summary: 'Confirm trailer hardware and specialized systems operate safely for loading and operation.',
    steps: <String>[
      'Inspect cargo doors, hinges, and seals for smooth operation and security.',
      'Test landing gear, stabilizers, and support legs for full range of motion.',
      'Verify refrigeration or auxiliary systems function where applicable.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'safety_equipment',
    title: 'Safety Equipment',
    summary: 'Audit all emergency and compliance gear to ensure readiness.',
    steps: <String>[
      'Check fire extinguisher charge status, inspection tag, and mounting hardware.',
      'Verify warning triangles, flares, reflective vests, and cones are complete.',
      'Confirm first-aid kit, spill response gear, and PPE inventories are stocked.',
      'Document missing or expired equipment with annotated photos before sign-off.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'operational_tests',
    title: 'Operational Tests',
    summary: 'Run functional checks to confirm the vehicle is drive-ready.',
    steps: <String>[
      'Perform brake responsiveness test noting pedal feel and stopping distance.',
      'Cycle steering lock-to-lock monitoring for binding, noise, or pulling.',
      'Start the engine, observe idle stability, warning lights, and vibrations.',
      'Shift through gears verifying transmission engagement and abnormal feedback.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'under_vehicle',
    title: 'Under-Vehicle Inspection',
    summary: 'Inspect undercarriage components for leaks, structural damage, or loose fasteners.',
    steps: <String>[
      'Check fuel tanks, lines, and DEF systems for leaks or abrasion.',
      'Inspect driveline, u-joints, and differential housings for damage.',
      'Verify crossmembers and mounting brackets are intact and rust-free.',
    ],
  ),
];

List<ChecklistGuideEntry> buildChecklistGuide(List<InspectionCategoryModel> remoteCategories) {
  final Map<String, InspectionCategoryModel> remoteByCode = <String, InspectionCategoryModel>{
    for (final category in remoteCategories) category.code: category,
  };

  final List<ChecklistGuideEntry> entries = <ChecklistGuideEntry>[];

  for (final blueprint in fleetChecklistBlueprint) {
    final InspectionCategoryModel? remote = remoteByCode[blueprint.code];
    final String title = (remote?.name.trim().isNotEmpty ?? false) ? remote!.name : blueprint.title;
    final String summary = (remote?.description.trim().isNotEmpty ?? false) ? remote!.description : blueprint.summary;
    final List<ChecklistGuidePoint> points = remote?.items
            .map(
              (item) => ChecklistGuidePoint(
                label: item.title,
                description: item.description,
                requiresPhoto: item.requiresPhoto,
              ),
            )
            .toList(growable: false) ??
        const <ChecklistGuidePoint>[];
    entries.add(
      ChecklistGuideEntry(
        code: blueprint.code,
        title: title,
        summary: summary,
        steps: blueprint.steps,
        points: points,
      ),
    );
  }

  for (final category in remoteCategories) {
    if (fleetChecklistBlueprint.any((blueprint) => blueprint.code == category.code)) {
      continue;
    }
    entries.add(
      ChecklistGuideEntry(
        code: category.code,
        title: category.name,
        summary: category.description,
        steps: const <String>[],
        points: category.items
            .map(
              (item) => ChecklistGuidePoint(
                label: item.title,
                description: item.description,
                requiresPhoto: item.requiresPhoto,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  return entries;
}
