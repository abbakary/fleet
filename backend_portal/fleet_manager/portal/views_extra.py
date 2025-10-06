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
