from __future__ import annotations

from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, render

from .models import Customer, Inspection, InspectorProfile, VehicleAssignment
from .views_web import _require_admin


@login_required
def reports_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspections = (
        Inspection.objects.select_related(
            "vehicle",
            "customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        ).order_by("-created_at")[:200]
    )
    return render(request, "portal/pages/reports.html", {"profile": profile, "inspections": inspections, "active_tab": "reports"})


@login_required
def customer_detail(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    customer = get_object_or_404(Customer.objects.select_related("profile", "profile__user"), pk=pk)
    vehicles = customer.vehicles.all().order_by("license_plate")
    inspections = (
        Inspection.objects.select_related("vehicle", "inspector", "inspector__profile", "inspector__profile__user")
        .filter(customer=customer)
        .order_by("-created_at")[:100]
    )
    assignments = (
        VehicleAssignment.objects.select_related("vehicle", "inspector", "inspector__profile", "inspector__profile__user")
        .filter(vehicle__customer=customer)
        .order_by("-scheduled_for")[:100]
    )
    context = {
        "profile": profile,
        "customer": customer,
        "vehicles": vehicles,
        "inspections": inspections,
        "assignments": assignments,
        "active_tab": "customers",
    }
    return render(request, "portal/pages/customer_detail.html", context)


@login_required
def inspector_detail(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspector = get_object_or_404(InspectorProfile.objects.select_related("profile", "profile__user"), pk=pk)
    assignments = (
        VehicleAssignment.objects.select_related("vehicle", "vehicle__customer")
        .filter(inspector=inspector)
        .order_by("-scheduled_for")[:100]
    )
    inspections = (
        Inspection.objects.select_related("vehicle", "customer")
        .filter(inspector=inspector)
        .order_by("-created_at")[:100]
    )
    context = {
        "profile": profile,
        "inspector": inspector,
        "assignments": assignments,
        "inspections": inspections,
        "active_tab": "inspectors",
    }
    return render(request, "portal/pages/inspector_detail.html", context)


@login_required
def inspection_detail(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    
    # Get the inspection with all related data
    inspection = get_object_or_404(
        Inspection.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
            "customer",
            "customer_report",
            "assignment",
            "assignment__vehicle",
            "assignment__inspector",
        ).prefetch_related(
            "item_responses",
            "item_responses__checklist_item",
            "item_responses__checklist_item__category",
            "item_responses__photos",
        ),
        pk=pk
    )
    
    # Group responses by category for better organization
    responses_by_category = {}
    passed_count = 0
    failed_count = 0
    na_count = 0
    
    for response in inspection.item_responses.all():
        # Count results
        if response.result == 'pass':
            passed_count += 1
        elif response.result == 'fail':
            failed_count += 1
        elif response.result == 'not_applicable':
            na_count += 1
            
        # Group by category
        category = response.checklist_item.category
        if category not in responses_by_category:
            responses_by_category[category] = []
        responses_by_category[category].append(response)
    
    context = {
        "profile": profile,
        "inspection": inspection,
        "responses_by_category": responses_by_category,
        "passed_count": passed_count,
        "failed_count": failed_count,
        "na_count": na_count,
        "active_tab": "inspections",
    }
    return render(request, "portal/pages/inspection_detail.html", context)
