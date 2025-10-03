from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from django.db import transaction

from .models import ChecklistItem, CustomerReport, Inspection, InspectionCategory


@dataclass
class ChecklistSeed:
    code: str
    name: str
    description: str


CHECKLIST_SECTIONS: list[ChecklistSeed] = [
    ChecklistSeed("pre_trip", "Pre-Trip Documentation", "Vehicle identification, odometer, and preliminary condition checks."),
    ChecklistSeed("exterior_structure", "Exterior & Structure", "Body, frame, and chassis observations."),
    ChecklistSeed("tires_wheels_axles", "Tires, Wheels, Axles", "Pressure, tread, and wheel assembly."),
    ChecklistSeed("braking_system", "Braking System", "Service brakes, parking brake, and lines."),
    ChecklistSeed("suspension_steering", "Suspension & Steering", "Springs, shocks, linkage, and alignment."),
    ChecklistSeed("engine_powertrain", "Engine & Powertrain", "Fluids, belts, filters, exhaust, and drivetrain."),
    ChecklistSeed("electrical_lighting", "Electrical & Lighting", "Lights, wiring, battery, horn."),
    ChecklistSeed("cabin_interior", "Cabin & Interior", "Seat belts, mirrors, wipers, gauges, emergency gear."),
    ChecklistSeed("coupling_connections", "Coupling & Connections", "Fifth wheel, kingpin, chains, air/electrical lines."),
    ChecklistSeed("trailer_equipment", "Trailer-Specific Equipment", "Doors, landing gear, refrigeration, load devices."),
    ChecklistSeed("safety_equipment", "Safety Equipment", "Extinguishers, triangles, first aid kits."),
    ChecklistSeed("operational_tests", "Operational Tests", "Functional checks for brakes, steering, engine."),
    ChecklistSeed("under_vehicle", "Under-Vehicle Inspection", "Fuel tanks, lines, and structural integrity."),
]


@transaction.atomic
def seed_checklist_structure(items: Iterable[tuple[str, str, str, bool]] | None = None) -> None:
    for index, section in enumerate(CHECKLIST_SECTIONS, start=1):
        category, _ = InspectionCategory.objects.update_or_create(
            code=section.code,
            defaults={
                "name": section.name,
                "description": section.description,
                "display_order": index,
            },
        )
        if items:
            for code, title, description, requires_photo in [entry for entry in items if entry[0].startswith(section.code)]:
                ChecklistItem.objects.update_or_create(
                    category=category,
                    code=code,
                    defaults={
                        "title": title,
                        "description": description,
                        "requires_photo": requires_photo,
                        "is_active": True,
                    },
                )


def generate_customer_report(inspection: Inspection) -> CustomerReport:
    findings = inspection.item_responses.select_related("checklist_item", "checklist_item__category")
    failed = [finding for finding in findings if finding.result == finding.RESULT_FAIL]
    summary_lines: list[str] = []
    if failed:
        summary_lines.append("Critical issues detected:")
        for finding in failed:
            summary_lines.append(
                f"- {finding.checklist_item.title} (Severity {finding.severity})"
            )
    else:
        summary_lines.append("No critical issues recorded during this inspection.")

    recommended: list[str] = []
    for finding in failed:
        recommended.append(f"Inspect and service {finding.checklist_item.title}. Notes: {finding.notes}")

    report, _ = CustomerReport.objects.update_or_create(
        inspection=inspection,
        defaults={
            "summary": "\n".join(summary_lines),
            "recommended_actions": "\n".join(recommended),
        },
    )
    return report
