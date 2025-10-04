from django.db import migrations


def seed_checklist(apps, schema_editor):
    InspectionCategory = apps.get_model('portal', 'InspectionCategory')
    ChecklistItem = apps.get_model('portal', 'ChecklistItem')

    categories = [
        {
            'code': 'pre_trip_documentation',
            'name': 'Pre-Trip Documentation',
            'description': 'Capture identifiers, readings, and baseline condition before inspection starts.',
            'items': [
                {'code': 'vin_label', 'title': 'VIN label verified', 'description': 'Confirm VIN matches paperwork and tag.', 'requires_photo': False},
                {'code': 'plate_match', 'title': 'License plate recorded', 'description': 'Record plate and verify registration.', 'requires_photo': False},
                {'code': 'odo_capture', 'title': 'Odometer reading captured', 'description': 'Enter dash odometer and engine hours.', 'requires_photo': False},
                {'code': 'baseline_photos', 'title': 'Baseline condition photos', 'description': 'Panoramic photos showing exterior condition.', 'requires_photo': True},
            ],
        },
        {
            'code': 'exterior_structure',
            'name': 'Exterior & Structure',
            'description': 'Walk-around inspection of body, frame, and exterior components.',
            'items': [
                {'code': 'body_panels', 'title': 'Body panels condition', 'description': 'Dents, cracks, corrosion, loose panels.', 'requires_photo': True},
                {'code': 'frame_rails', 'title': 'Frame rails & crossmembers', 'description': 'Inspect for damage, rust, or deformation.', 'requires_photo': True},
                {'code': 'glass_mirrors', 'title': 'Glass and mirrors', 'description': 'Windshield, side glass, mirrors free of cracks.', 'requires_photo': False},
                {'code': 'bumpers_mounts', 'title': 'Bumpers & mounts', 'description': 'Securely mounted, no sharp edges.', 'requires_photo': False},
            ],
        },
        {
            'code': 'tires_wheels_axles',
            'name': 'Tires, Wheels, & Axles',
            'description': 'Tire health, wheel hardware, hubs, and axle integrity.',
            'items': [
                {'code': 'tire_pressure', 'title': 'Tire pressure', 'description': 'Record PSI for each position.', 'requires_photo': False},
                {'code': 'tread_depth', 'title': 'Tread depth', 'description': 'Measure depth and irregular wear.', 'requires_photo': False},
                {'code': 'wheel_hardware', 'title': 'Wheel hardware', 'description': 'Rims, lugs, indicators secure and intact.', 'requires_photo': True},
                {'code': 'hubs_seals', 'title': 'Hubs & seals', 'description': 'Check for leaks or overheating.', 'requires_photo': True},
            ],
        },
        {
            'code': 'braking_system',
            'name': 'Braking System',
            'description': 'Service, emergency, and parking brake components.',
            'items': [
                {'code': 'pads_rotors', 'title': 'Pads/shoes & rotors/drums', 'description': 'Thickness, glazing, heat checking.', 'requires_photo': True},
                {'code': 'hyd_air_lines', 'title': 'Hydraulic/air lines', 'description': 'Leaks, chafing, routing, fittings.', 'requires_photo': True},
                {'code': 'reservoirs_valves', 'title': 'Reservoirs & valves', 'description': 'Proper level, leaks, secure mounts.', 'requires_photo': False},
                {'code': 'parking_brake', 'title': 'Parking brake hold', 'description': 'Application strength and response.', 'requires_photo': False},
            ],
        },
        {
            'code': 'suspension_steering',
            'name': 'Suspension & Steering',
            'description': 'Ride stability and steering precision components.',
            'items': [
                {'code': 'springs_shocks', 'title': 'Springs & shocks/air bags', 'description': 'Leaks, cracks, uneven height.', 'requires_photo': True},
                {'code': 'steering_linkage', 'title': 'Steering linkage', 'description': 'Tie rods, drag links, kingpins free play.', 'requires_photo': True},
                {'code': 'bushings_mounts', 'title': 'Bushings & mounts', 'description': 'Wear, looseness, damaged hardware.', 'requires_photo': False},
                {'code': 'alignment', 'title': 'Alignment indicators', 'description': 'Wheel centering and tracking.', 'requires_photo': False},
            ],
        },
        {
            'code': 'engine_powertrain',
            'name': 'Engine & Powertrain',
            'description': 'Fluids, belts/hoses, exhaust, and drivetrain.',
            'items': [
                {'code': 'fluid_levels', 'title': 'Fluid levels', 'description': 'Oil, coolant, transmission, DEF, hydraulics.', 'requires_photo': False},
                {'code': 'belts_hoses', 'title': 'Belts & hoses', 'description': 'Cracks, frays, clamps and filters.', 'requires_photo': True},
                {'code': 'exhaust_system', 'title': 'Exhaust system', 'description': 'Routing, mounts, leaks, soot trails.', 'requires_photo': True},
                {'code': 'drivetrain', 'title': 'Drivetrain & seals', 'description': 'Leaks, noise, damaged housings.', 'requires_photo': True},
            ],
        },
        {
            'code': 'electrical_lighting',
            'name': 'Electrical & Lighting',
            'description': 'Lighting circuits and electrical components.',
            'items': [
                {'code': 'exterior_lights', 'title': 'Exterior lighting', 'description': 'Head/tail/marker/brake lights functional.', 'requires_photo': False},
                {'code': 'signals_hazards', 'title': 'Signals & hazards', 'description': 'Turn signals and hazards synchronized.', 'requires_photo': False},
                {'code': 'interior_gauges', 'title': 'Interior & gauges', 'description': 'Dash indicators and chimes.', 'requires_photo': False},
                {'code': 'battery_wiring', 'title': 'Battery & wiring', 'description': 'Corrosion, damage, loose terminals.', 'requires_photo': True},
            ],
        },
        {
            'code': 'cabin_interior',
            'name': 'Cabin & Interior',
            'description': 'Occupant safety, visibility, and controls.',
            'items': [
                {'code': 'restraints', 'title': 'Seat belts & restraints', 'description': 'Secure, undamaged, functional.', 'requires_photo': False},
                {'code': 'visibility', 'title': 'Visibility systems', 'description': 'Mirrors, windshield, wipers/washers.', 'requires_photo': False},
                {'code': 'controls_hvac', 'title': 'Controls & HVAC', 'description': 'Switches, gauges, infotainment.', 'requires_photo': False},
                {'code': 'emergency_gear', 'title': 'Emergency equipment', 'description': 'Logbooks, permits, safety signage.', 'requires_photo': False},
            ],
        },
        {
            'code': 'coupling_connections',
            'name': 'Coupling & Connections',
            'description': 'Trailer coupling devices and service lines.',
            'items': [
                {'code': 'locking_components', 'title': 'Locking components', 'description': 'Fifth wheel/kingpin/pintle secure.', 'requires_photo': True},
                {'code': 'safety_devices', 'title': 'Safety chains & pins', 'description': 'Present and undamaged.', 'requires_photo': False},
                {'code': 'service_lines', 'title': 'Electrical & air lines', 'description': 'No leaks, abrasion, or misalignment.', 'requires_photo': True},
            ],
        },
        {
            'code': 'safety_equipment',
            'name': 'Safety Equipment',
            'description': 'Emergency preparedness and compliance items.',
            'items': [
                {'code': 'extinguisher', 'title': 'Fire extinguisher', 'description': 'Charge status and inspection tag.', 'requires_photo': False},
                {'code': 'triangles', 'title': 'Warning triangles/flares', 'description': 'Present and serviceable.', 'requires_photo': False},
                {'code': 'first_aid_ppe', 'title': 'First-aid & PPE', 'description': 'Stocked and accessible.', 'requires_photo': False},
            ],
        },
        {
            'code': 'operational_tests',
            'name': 'Operational Tests',
            'description': 'Dynamic checks prior to releasing the vehicle.',
            'items': [
                {'code': 'brake_test', 'title': 'Brake responsiveness', 'description': 'Stopping distance and pedal feel.', 'requires_photo': False},
                {'code': 'steering_check', 'title': 'Steering operation', 'description': 'Lock-to-lock, no binding/noise.', 'requires_photo': False},
                {'code': 'engine_start', 'title': 'Engine start & idle', 'description': 'Idle quality and warning lights.', 'requires_photo': False},
                {'code': 'transmission_test', 'title': 'Transmission shifting', 'description': 'Smooth engagement in all ranges.', 'requires_photo': False},
            ],
        },
    ]

    for order, cat in enumerate(categories, start=1):
        category, _ = InspectionCategory.objects.get_or_create(
            code=cat['code'],
            defaults={
                'name': cat['name'],
                'description': cat['description'],
                'display_order': order,
            },
        )
        # Update name/description/order if changed
        changed = False
        if category.name != cat['name']:
            category.name = cat['name']
            changed = True
        if category.description != cat['description']:
            category.description = cat['description']
            changed = True
        if category.display_order != order:
            category.display_order = order
            changed = True
        if changed:
            category.save()
        for item in cat['items']:
            ChecklistItem.objects.get_or_create(
                category=category,
                code=item['code'],
                defaults={
                    'title': item['title'],
                    'description': item['description'],
                    'requires_photo': item['requires_photo'],
                    'is_active': True,
                },
            )


def noop_reverse(apps, schema_editor):
    # Intentionally do nothing to avoid deleting user data
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('portal', '0002_vehicle_make_model'),
    ]

    operations = [
        migrations.RunPython(seed_checklist, noop_reverse),
    ]
