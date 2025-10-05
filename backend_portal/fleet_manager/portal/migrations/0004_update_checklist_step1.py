from django.db import migrations


def ensure_step1_checklist(apps, schema_editor):
    InspectionCategory = apps.get_model('portal', 'InspectionCategory')
    ChecklistItem = apps.get_model('portal', 'ChecklistItem')

    cat_code = 'pre_trip_documentation'
    cat_defaults = {
        'name': 'Pre-Trip Documentation',
        'description': 'Capture identifiers, readings, and baseline condition before inspection starts.',
        'display_order': 1,
    }

    category, created = InspectionCategory.objects.get_or_create(
        code=cat_code,
        defaults=cat_defaults,
    )
    # Make sure metadata is up to date
    changed = False
    for key, value in cat_defaults.items():
        if getattr(category, key) != value:
            setattr(category, key, value)
            changed = True
    if changed:
        category.save()

    items = [
        {'code': 'vin_label', 'title': 'VIN label verified', 'description': 'Confirm VIN matches paperwork and tag.', 'requires_photo': False},
        {'code': 'plate_match', 'title': 'License plate recorded', 'description': 'Record plate and verify registration.', 'requires_photo': False},
        {'code': 'odo_capture', 'title': 'Odometer reading captured', 'description': 'Enter dash odometer and engine hours.', 'requires_photo': False},
        {'code': 'baseline_photos', 'title': 'Baseline condition photos', 'description': 'Panoramic photos showing exterior condition.', 'requires_photo': True},
    ]

    for item in items:
        obj, _ = ChecklistItem.objects.get_or_create(
            category=category,
            code=item['code'],
            defaults={
                'title': item['title'],
                'description': item['description'],
                'requires_photo': item['requires_photo'],
                'is_active': True,
            },
        )
        # Ensure fields are current
        updated = False
        if obj.title != item['title']:
            obj.title = item['title']
            updated = True
        if obj.description != item['description']:
            obj.description = item['description']
            updated = True
        if obj.requires_photo != item['requires_photo']:
            obj.requires_photo = item['requires_photo']
            updated = True
        if not obj.is_active:
            obj.is_active = True
            updated = True
        if updated:
            obj.save()


def noop_reverse(apps, schema_editor):
    # Intentionally no-op: do not delete data
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('portal', '0003_seed_checklist'),
    ]

    operations = [
        migrations.RunPython(ensure_step1_checklist, noop_reverse),
    ]
