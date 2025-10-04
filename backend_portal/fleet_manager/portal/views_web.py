from django.contrib.auth.decorators import login_required
from django.db.models import Count, Prefetch
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone

from .forms import (
    ChecklistItemForm,
    CustomerForm,
    InspectionCategoryForm,
    InspectionForm,
    InspectorProfileForm,
    PortalUserCreateForm,
    PortalUserUpdateForm,
    VehicleAssignmentForm,
    VehicleForm,
    VehicleMakeForm,
    VehicleModelNameForm,
)
from .models import (
    ChecklistItem,
    Customer,
    Inspection,
    InspectionCategory,
    InspectorProfile,
    PortalUser,
    Vehicle,
    VehicleAssignment,
    VehicleMake,
    VehicleModelName,
)
from .permissions import get_portal_profile


def _require_admin(request: HttpRequest) -> PortalUser | None:
    user = request.user
    if not user.is_authenticated:
        return None
    profile = get_portal_profile(user)
    # Allow Django superusers/staff. Auto-provision a PortalUser as admin if missing.
    if (not profile or profile.role != PortalUser.ROLE_ADMIN) and (user.is_superuser or user.is_staff):
        profile = profile or PortalUser.objects.filter(user=user).first()
        if not profile:
            profile = PortalUser.objects.create(user=user, role=PortalUser.ROLE_ADMIN)
        else:
            profile.role = PortalUser.ROLE_ADMIN
            profile.save(update_fields=["role", "updated_at"])  # type: ignore[attr-defined]
    if not profile or profile.role != PortalUser.ROLE_ADMIN:
        return None
    return profile


def _is_htmx(request: HttpRequest) -> bool:
    return request.headers.get("HX-Request") == "true"


def _dashboard_redirect(tab: str) -> HttpResponse:
    return redirect(f"{reverse('portal-admin')}?tab={tab}")


def _status_totals(manager, field: str = "status") -> dict[str, int]:
    return {row[field]: row["total"] for row in manager.values(field).annotate(total=Count("id"))}


def _render_form(
    request: HttpRequest,
    profile: PortalUser,
    form,
    *,
    tab: str,
    title: str,
    submit_label: str,
    is_create: bool,
    extra_context: dict | None = None,
) -> HttpResponse:
    context = {
        "profile": profile,
        "form": form,
        "form_title": title,
        "submit_label": submit_label,
        "cancel_url": f"{reverse('portal-admin')}?tab={tab}",
        "form_action": request.path,
        "is_create": is_create,
        "active_tab": tab,
        "is_htmx": _is_htmx(request),
    }
    if extra_context:
        context.update(extra_context)
    template = "portal/forms/form_partial.html" if context["is_htmx"] else "portal/forms/form_page.html"
    return render(request, template, context)


@login_required
def app_shell(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)

    today = timezone.now().date()
    inspection_totals = _status_totals(Inspection.objects)
    assignment_totals = _status_totals(VehicleAssignment.objects)
    inspection_total_count = Inspection.objects.count()
    assignment_total_count = VehicleAssignment.objects.count()
    inspection_percentages = {
        key: round((value / max(inspection_total_count, 1)) * 100, 1)
        for key, value in inspection_totals.items()
    }
    assignment_percentages = {
        key: round((value / max(assignment_total_count, 1)) * 100, 1)
        for key, value in assignment_totals.items()
    }
    inspection_status_cards = [
        {
            "key": Inspection.STATUS_DRAFT,
            "label": "Draft",
            "count": inspection_totals.get(Inspection.STATUS_DRAFT, 0),
            "percent": inspection_percentages.get(Inspection.STATUS_DRAFT, 0),
        },
        {
            "key": Inspection.STATUS_IN_PROGRESS,
            "label": "In Progress",
            "count": inspection_totals.get(Inspection.STATUS_IN_PROGRESS, 0),
            "percent": inspection_percentages.get(Inspection.STATUS_IN_PROGRESS, 0),
        },
        {
            "key": Inspection.STATUS_SUBMITTED,
            "label": "Submitted",
            "count": inspection_totals.get(Inspection.STATUS_SUBMITTED, 0),
            "percent": inspection_percentages.get(Inspection.STATUS_SUBMITTED, 0),
        },
        {
            "key": Inspection.STATUS_APPROVED,
            "label": "Approved",
            "count": inspection_totals.get(Inspection.STATUS_APPROVED, 0),
            "percent": inspection_percentages.get(Inspection.STATUS_APPROVED, 0),
        },
    ]
    assignment_status_cards = [
        {
            "key": VehicleAssignment.STATUS_ASSIGNED,
            "label": "Assigned",
            "count": assignment_totals.get(VehicleAssignment.STATUS_ASSIGNED, 0),
            "percent": assignment_percentages.get(VehicleAssignment.STATUS_ASSIGNED, 0),
        },
        {
            "key": VehicleAssignment.STATUS_IN_PROGRESS,
            "label": "In Progress",
            "count": assignment_totals.get(VehicleAssignment.STATUS_IN_PROGRESS, 0),
            "percent": assignment_percentages.get(VehicleAssignment.STATUS_IN_PROGRESS, 0),
        },
        {
            "key": VehicleAssignment.STATUS_COMPLETED,
            "label": "Completed",
            "count": assignment_totals.get(VehicleAssignment.STATUS_COMPLETED, 0),
            "percent": assignment_percentages.get(VehicleAssignment.STATUS_COMPLETED, 0),
        },
    ]
    recent_inspections = (
        Inspection.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        )
        .order_by("-created_at")[:6]
    )
    upcoming_assignments = (
        VehicleAssignment.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        )
        .filter(scheduled_for__gte=today)
        .order_by("scheduled_for")[:6]
    )
    recent_customers = (
        Customer.objects.select_related("profile", "profile__user")
        .order_by("-created_at")[:6]
    )

    context = {
        "profile": profile,
        "active_tab": request.GET.get("tab", "overview"),
        "kpi_customers": Customer.objects.count(),
        "kpi_users": PortalUser.objects.exclude(role=PortalUser.ROLE_ADMIN).count(),
        "kpi_vehicles": Vehicle.objects.count(),
        "kpi_inspectors": InspectorProfile.objects.count(),
        "kpi_inspections": inspection_total_count,
        "kpi_assignments": assignment_total_count,
        "kpi_pending_assignments": assignment_totals.get(VehicleAssignment.STATUS_ASSIGNED, 0),
        "kpi_in_progress_inspections": inspection_totals.get(Inspection.STATUS_IN_PROGRESS, 0),
        "inspection_status_totals": inspection_totals,
        "inspection_status_percentages": inspection_percentages,
        "inspection_status_cards": inspection_status_cards,
        "assignment_status_totals": assignment_totals,
        "assignment_status_percentages": assignment_percentages,
        "assignment_status_cards": assignment_status_cards,
        "recent_inspections": recent_inspections,
        "upcoming_assignments": upcoming_assignments,
        "recent_customers": recent_customers,
    }
    return render(request, "portal/dashboard-02.html", context)


@login_required
def customers_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    customers = Customer.objects.select_related("profile", "profile__user").order_by("-created_at")[:200]
    if _is_htmx(request):
        return render(request, "portal/partials/customers.html", {"customers": customers})
    return render(request, "portal/pages/customers.html", {"profile": profile, "customers": customers})


@login_required
def vehicles_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    vehicles = Vehicle.objects.select_related("customer", "customer__profile", "customer__profile__user").order_by(
        "-created_at"
    )[:200]
    if _is_htmx(request):
        return render(request, "portal/partials/vehicles.html", {"vehicles": vehicles})
    return render(request, "portal/pages/vehicles.html", {"profile": profile, "vehicles": vehicles})


@login_required
def inspectors_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspectors = InspectorProfile.objects.select_related("profile", "profile__user").order_by("-created_at")[:200]
    if _is_htmx(request):
        return render(request, "portal/partials/inspectors.html", {"inspectors": inspectors})
    return render(request, "portal/pages/inspectors.html", {"profile": profile, "inspectors": inspectors})


@login_required
def assignments_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    assignments = (
        VehicleAssignment.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        )
        .order_by("-scheduled_for")[:200]
    )
    if _is_htmx(request):
        return render(request, "portal/partials/assignments.html", {"assignments": assignments})
    return render(request, "portal/pages/assignments.html", {"profile": profile, "assignments": assignments})


@login_required
def inspections_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspections = (
        Inspection.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        )
        .order_by("-created_at")[:200]
    )
    if _is_htmx(request):
        return render(request, "portal/partials/inspections.html", {"inspections": inspections})
    return render(request, "portal/pages/inspections.html", {"profile": profile, "inspections": inspections})


@login_required
def categories_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    categories = InspectionCategory.objects.prefetch_related("items").order_by("display_order", "name")
    if _is_htmx(request):
        return render(request, "portal/partials/categories.html", {"categories": categories})
    return render(request, "portal/pages/categories.html", {"profile": profile, "categories": categories})


@login_required
def users_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    users = PortalUser.objects.select_related("user").order_by("-created_at")[:200]
    if _is_htmx(request):
        return render(request, "portal/partials/users.html", {"users": users})
    return render(request, "portal/pages/users.html", {"profile": profile, "users": users})


# ------- Portal users -------
@login_required
def user_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = PortalUserCreateForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return users_view(request)
            return _dashboard_redirect("users")
    else:
        form = PortalUserCreateForm()
    return _render_form(
        request,
        profile,
        form,
        tab="users",
        title="Create Portal User",
        submit_label="Create User",
        is_create=True,
    )


@login_required
def user_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    portal_user = get_object_or_404(PortalUser.objects.select_related("user"), pk=pk)
    if request.method == "POST":
        form = PortalUserUpdateForm(request.POST, instance=portal_user)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return users_view(request)
            return _dashboard_redirect("users")
    else:
        form = PortalUserUpdateForm(instance=portal_user)
    return _render_form(
        request,
        profile,
        form,
        tab="users",
        title="Update Portal User",
        submit_label="Save Changes",
        is_create=False,
        extra_context={"object": portal_user},
    )


@login_required
def user_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    portal_user = get_object_or_404(PortalUser.objects.select_related("user"), pk=pk)
    if request.method == "POST":
        user = portal_user.user
        portal_user.delete()
        user.delete()
        if _is_htmx(request):
            return users_view(request)
        return _dashboard_redirect("users")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("users")


# ------- Customers -------
@login_required
def customer_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = CustomerForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return customers_view(request)
            return _dashboard_redirect("customers")
    else:
        form = CustomerForm()
    return _render_form(
        request,
        profile,
        form,
        tab="customers",
        title="Add Customer",
        submit_label="Create Customer",
        is_create=True,
    )


@login_required
def customer_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Customer, pk=pk)
    if request.method == "POST":
        form = CustomerForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return customers_view(request)
            return _dashboard_redirect("customers")
    else:
        form = CustomerForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="customers",
        title="Edit Customer",
        submit_label="Save Customer",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def customer_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Customer, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return customers_view(request)
        return _dashboard_redirect("customers")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("customers")


# ------- Vehicles -------
@login_required
def vehicle_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = VehicleForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return vehicles_view(request)
            return _dashboard_redirect("vehicles")
    else:
        form = VehicleForm()
    return _render_form(
        request,
        profile,
        form,
        tab="vehicles",
        title="Add Vehicle",
        submit_label="Create Vehicle",
        is_create=True,
    )


@login_required
def vehicle_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Vehicle, pk=pk)
    if request.method == "POST":
        form = VehicleForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return vehicles_view(request)
            return _dashboard_redirect("vehicles")
    else:
        form = VehicleForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="vehicles",
        title="Edit Vehicle",
        submit_label="Save Vehicle",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def vehicle_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Vehicle, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return vehicles_view(request)
        return _dashboard_redirect("vehicles")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("vehicles")


# ------- Vehicle catalog -------
@login_required
def vehicle_catalog_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    makes = (
        VehicleMake.objects.order_by("name")
        .prefetch_related(Prefetch("models", queryset=VehicleModelName.objects.order_by("name")))
    )
    context = {"makes": makes}
    if _is_htmx(request):
        return render(request, "portal/partials/vehicle_catalog.html", context)
    context.update({"profile": profile, "active_tab": "catalog"})
    return render(request, "portal/pages/vehicle_catalog.html", context)


@login_required
def vehicle_make_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = VehicleMakeForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return vehicle_catalog_view(request)
            return _dashboard_redirect("catalog")
    else:
        form = VehicleMakeForm()
    return _render_form(
        request,
        profile,
        form,
        tab="catalog",
        title="Add Vehicle Make",
        submit_label="Create Make",
        is_create=True,
    )


@login_required
def vehicle_make_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleMake, pk=pk)
    if request.method == "POST":
        form = VehicleMakeForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return vehicle_catalog_view(request)
            return _dashboard_redirect("catalog")
    else:
        form = VehicleMakeForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="catalog",
        title="Edit Vehicle Make",
        submit_label="Save Changes",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def vehicle_make_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleMake, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return vehicle_catalog_view(request)
        return _dashboard_redirect("catalog")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("catalog")


@login_required
def vehicle_model_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    initial_make = request.GET.get("make")
    if request.method == "POST":
        form = VehicleModelNameForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return vehicle_catalog_view(request)
            return _dashboard_redirect("catalog")
    else:
        initial = {}
        if initial_make:
            try:
                initial["make"] = VehicleMake.objects.get(pk=int(initial_make))
            except (VehicleMake.DoesNotExist, ValueError, TypeError):
                pass
        form = VehicleModelNameForm(initial=initial)
    return _render_form(
        request,
        profile,
        form,
        tab="catalog",
        title="Add Vehicle Model",
        submit_label="Create Model",
        is_create=True,
    )


@login_required
def vehicle_model_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleModelName, pk=pk)
    if request.method == "POST":
        form = VehicleModelNameForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return vehicle_catalog_view(request)
            return _dashboard_redirect("catalog")
    else:
        form = VehicleModelNameForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="catalog",
        title="Edit Vehicle Model",
        submit_label="Save Changes",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def vehicle_model_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleModelName, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return vehicle_catalog_view(request)
        return _dashboard_redirect("catalog")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("catalog")


# ------- Inspectors -------
@login_required
def inspector_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = InspectorProfileForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return inspectors_view(request)
            return _dashboard_redirect("inspectors")
    else:
        form = InspectorProfileForm()
    return _render_form(
        request,
        profile,
        form,
        tab="inspectors",
        title="Add Inspector",
        submit_label="Create Inspector",
        is_create=True,
    )


@login_required
def inspector_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(InspectorProfile, pk=pk)
    if request.method == "POST":
        form = InspectorProfileForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return inspectors_view(request)
            return _dashboard_redirect("inspectors")
    else:
        form = InspectorProfileForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="inspectors",
        title="Edit Inspector",
        submit_label="Save Inspector",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def inspector_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(InspectorProfile, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return inspectors_view(request)
        return _dashboard_redirect("inspectors")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("inspectors")


# ------- Assignments -------
@login_required
def assignment_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = VehicleAssignmentForm(request.POST)
        if form.is_valid():
            assignment = form.save(commit=False)
            assignment.assigned_by = profile
            assignment.save()
            if _is_htmx(request):
                return assignments_view(request)
            return _dashboard_redirect("assignments")
    else:
        form = VehicleAssignmentForm()
    return _render_form(
        request,
        profile,
        form,
        tab="assignments",
        title="Create Assignment",
        submit_label="Create Assignment",
        is_create=True,
    )


@login_required
def assignment_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleAssignment, pk=pk)
    if request.method == "POST":
        form = VehicleAssignmentForm(request.POST, instance=obj)
        if form.is_valid():
            assignment = form.save(commit=False)
            assignment.assigned_by = assignment.assigned_by or profile
            assignment.save()
            if _is_htmx(request):
                return assignments_view(request)
            return _dashboard_redirect("assignments")
    else:
        form = VehicleAssignmentForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="assignments",
        title="Edit Assignment",
        submit_label="Save Assignment",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def assignment_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleAssignment, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return assignments_view(request)
        return _dashboard_redirect("assignments")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("assignments")


# ------- Inspections -------
@login_required
def inspection_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = InspectionForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return inspections_view(request)
            return _dashboard_redirect("inspections")
    else:
        form = InspectionForm()
    return _render_form(
        request,
        profile,
        form,
        tab="inspections",
        title="Log Inspection",
        submit_label="Create Inspection",
        is_create=True,
    )


@login_required
def inspection_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Inspection, pk=pk)
    if request.method == "POST":
        form = InspectionForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return inspections_view(request)
            return _dashboard_redirect("inspections")
    else:
        form = InspectionForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="inspections",
        title="Edit Inspection",
        submit_label="Save Inspection",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def inspection_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Inspection, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return inspections_view(request)
        return _dashboard_redirect("inspections")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("inspections")


# ------- Categories & Items -------
@login_required
def category_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = InspectionCategoryForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return categories_view(request)
            return _dashboard_redirect("categories")
    else:
        form = InspectionCategoryForm()
    return _render_form(
        request,
        profile,
        form,
        tab="categories",
        title="Add Inspection Category",
        submit_label="Create Category",
        is_create=True,
    )


@login_required
def category_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(InspectionCategory, pk=pk)
    if request.method == "POST":
        form = InspectionCategoryForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return categories_view(request)
            return _dashboard_redirect("categories")
    else:
        form = InspectionCategoryForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="categories",
        title="Edit Inspection Category",
        submit_label="Save Category",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def category_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(InspectionCategory, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return categories_view(request)
        return _dashboard_redirect("categories")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("categories")


@login_required
def checklist_item_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    initial = {}
    if request.method == "GET":
        cat_id = request.GET.get("category")
        if cat_id:
            initial["category"] = cat_id
    if request.method == "POST":
        form = ChecklistItemForm(request.POST)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return categories_view(request)
            return _dashboard_redirect("categories")
    else:
        form = ChecklistItemForm(initial=initial)
    return _render_form(
        request,
        profile,
        form,
        tab="categories",
        title="Add Checklist Item",
        submit_label="Create Item",
        is_create=True,
    )


@login_required
def checklist_item_edit(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(ChecklistItem, pk=pk)
    if request.method == "POST":
        form = ChecklistItemForm(request.POST, instance=obj)
        if form.is_valid():
            form.save()
            if _is_htmx(request):
                return categories_view(request)
            return _dashboard_redirect("categories")
    else:
        form = ChecklistItemForm(instance=obj)
    return _render_form(
        request,
        profile,
        form,
        tab="categories",
        title="Edit Checklist Item",
        submit_label="Save Item",
        is_create=False,
        extra_context={"object": obj},
    )


@login_required
def checklist_item_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(ChecklistItem, pk=pk)
    if request.method == "POST":
        obj.delete()
        if _is_htmx(request):
            return categories_view(request)
        return _dashboard_redirect("categories")
    if _is_htmx(request):
        return HttpResponse(status=405)
    return _dashboard_redirect("categories")
