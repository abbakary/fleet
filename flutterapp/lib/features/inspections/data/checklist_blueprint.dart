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
    summary: 'Capture baseline vehicle information and confirm assignment details before any physical checks.',
    steps: <String>[
      'Verify that the VIN, license plate, and unit number match the assignment record.',
      'Record the current odometer and engine hours in the inspection form.',
      'Note overall vehicle condition and any pre-existing damage reported by the customer.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'exterior_structure',
    title: 'Exterior & Structure',
    summary: 'Walk the vehicle perimeter to identify structural issues that could compromise safety or compliance.',
    steps: <String>[
      'Inspect body panels, frame rails, and chassis cross-members for cracks, corrosion, or loose hardware.',
      'Check doors, hinges, and panels for proper alignment and secure latching.',
      'Capture photos of dents, rust areas, or structural concerns for evidence.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'tires_wheels_axles',
    title: 'Tires, Wheels, & Axles',
    summary: 'Confirm tires and axles are roadworthy and meet tread, pressure, and fastening standards.',
    steps: <String>[
      'Measure tire tread depth and confirm inflation levels match manufacturer specifications.',
      'Inspect sidewalls for cuts, bulges, or exposed cords.',
      'Check wheel studs, lug nuts, hubs, and seals for tightness and leaks.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'braking_system',
    title: 'Braking System',
    summary: 'Ensure the service, emergency, and parking brake systems meet operational requirements.',
    steps: <String>[
      'Inspect brake pads, drums, rotors, and slack adjusters for wear and damage.',
      'Verify air lines, hydraulic hoses, and fittings are secure and leak-free.',
      'Test ABS indicators and parking brake engagement.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'suspension_steering',
    title: 'Suspension & Steering',
    summary: 'Confirm steering response and suspension stability to maintain vehicle control.',
    steps: <String>[
      'Inspect springs, shocks, and air bags for leaks, cracks, or uneven ride height.',
      'Check steering linkage, tie rods, and kingpins for play or excessive wear.',
      'Verify alignment indicators, ensuring even tire wear patterns.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'engine_powertrain',
    title: 'Engine & Powertrain',
    summary: 'Review the engine bay for leaks, fluid levels, and drivetrain integrity before operation.',
    steps: <String>[
      'Check oil, coolant, transmission, and brake fluid levels; top up if authorized.',
      'Inspect belts, hoses, filters, and clamps for cracks or loose fits.',
      'Look for exhaust leaks and ensure drivetrain mounts are secure.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'electrical_lighting',
    title: 'Electrical & Lighting',
    summary: 'Verify signal, marker, and auxiliary lighting along with critical electrical systems.',
    steps: <String>[
      'Test headlights, turn signals, brake lights, reverse lights, and clearance lamps.',
      'Confirm battery connections are clean and secure; look for corrosion.',
      'Operate horn, warning buzzers, and auxiliary electrical equipment.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'cabin_interior',
    title: 'Cabin & Interior',
    summary: 'Assess driver comfort and safety equipment inside the cab or operator compartment.',
    steps: <String>[
      'Verify seat belts, seats, and mirrors adjust and lock correctly.',
      'Test windshield wipers, washers, defrosters, and interior lighting.',
      'Confirm gauges, diagnostic displays, and emergency switches function.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'coupling_connections',
    title: 'Coupling & Connections',
    summary: 'Review tractor-trailer connections to prevent separation or system failures on the road.',
    steps: <String>[
      'Inspect fifth wheel, kingpin, pintle, or gooseneck components for wear and secure locking.',
      'Verify safety chains, breakaway cables, and locking pins are present and undamaged.',
      'Check air and electrical lines for chafing, leaks, and proper support.',
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
    summary: 'Ensure required emergency and safety gear is stocked, inspected, and within service dates.',
    steps: <String>[
      'Verify fire extinguishers are charged, secured, and within inspection dates.',
      'Confirm warning triangles, flares, or cones are present and accessible.',
      'Check first-aid kits, PPE, and spill response gear when required.',
    ],
  ),
  ChecklistCategoryBlueprint(
    code: 'operational_tests',
    title: 'Operational Tests',
    summary: 'Conduct dynamic tests to validate vehicle performance and responsiveness.',
    steps: <String>[
      'Perform a brake test to confirm stopping distance and pedal feel.',
      'Cycle steering through full range and listen for abnormal noises.',
      'Start the engine and monitor for warning lights, vibrations, or smoke.',
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
