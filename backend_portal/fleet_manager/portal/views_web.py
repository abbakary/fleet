from django.contrib.auth.decorators import login_required
from django.shortcuts import render, get_object_or_404
from django.http import HttpRequest, HttpResponse

from .models import (
    ChecklistItem,
    Customer,
    Inspection,
    InspectionCategory,
    InspectorProfile,
    PortalUser,
    Vehicle,
    VehicleAssignment,
)
from .permissions import get_portal_profile
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
)


def _require_admin(request: HttpRequest) -> PortalUser | None:
    user = request.user
    if not user.is_authenticated:
        return None
    profile = get_portal_profile(user)
    if not profile or profile.role != PortalUser.ROLE_ADMIN:
        return None
    return profile


@login_required
def app_shell(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    context = {
        "profile": profile,
        "kpi_customers": Customer.objects.count(),
        "kpi_users": PortalUser.objects.exclude(role=PortalUser.ROLE_ADMIN).count(),
        "kpi_vehicles": Vehicle.objects.count(),
        "kpi_inspectors": InspectorProfile.objects.count(),
        "kpi_inspections": Inspection.objects.count(),
    }
    return render(request, "portal/dashboard.html", context)


@login_required
def customers_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    customers = Customer.objects.select_related("profile", "profile__user").order_by("-id")[:200]
    return render(request, "portal/partials/customers.html", {"customers": customers})


@login_required
def vehicles_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    vehicles = Vehicle.objects.select_related("customer").order_by("-id")[:200]
    return render(request, "portal/partials/vehicles.html", {"vehicles": vehicles})


@login_required
def inspectors_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspectors = InspectorProfile.objects.select_related("profile", "profile__user").order_by("-id")[:200]
    return render(request, "portal/partials/inspectors.html", {"inspectors": inspectors})


@login_required
def assignments_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    assignments = (
        VehicleAssignment.objects.select_related(
            "vehicle", "vehicle__customer", "inspector", "inspector__profile", "inspector__profile__user"
        )
        .order_by("-scheduled_for")[:200]
    )
    return render(request, "portal/partials/assignments.html", {"assignments": assignments})


@login_required
def inspections_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    inspections = (
        Inspection.objects.select_related(
            "vehicle", "vehicle__customer", "inspector", "inspector__profile", "inspector__profile__user"
        )
        .order_by("-created_at")[:200]
    )
    return render(request, "portal/partials/inspections.html", {"inspections": inspections})


@login_required
def categories_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    categories = InspectionCategory.objects.prefetch_related("items").order_by("display_order")
    return render(request, "portal/partials/categories.html", {"categories": categories})


# ------- Portal users -------
@login_required
def users_view(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    users = PortalUser.objects.select_related("user").order_by("-created_at")[:200]
    return render(request, "portal/partials/users.html", {"users": users})


@login_required
def user_create(request: HttpRequest) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    if request.method == "POST":
        form = PortalUserCreateForm(request.POST)
        if form.is_valid():
            form.save()
            return users_view(request)
    else:
        form = PortalUserCreateForm()
    return render(request, "portal/forms/portal_user_form.html", {"form": form, "is_create": True})


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
            return users_view(request)
    else:
        form = PortalUserUpdateForm(instance=portal_user)
    return render(
        request,
        "portal/forms/portal_user_form.html",
        {"form": form, "object": portal_user, "is_create": False},
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
    return users_view(request)


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
            return customers_view(request)
    else:
        form = CustomerForm()
    return render(request, "portal/forms/customer_form.html", {"form": form})


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
            return customers_view(request)
    else:
        form = CustomerForm(instance=obj)
    return render(request, "portal/forms/customer_form.html", {"form": form, "object": obj})


@login_required
def customer_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Customer, pk=pk)
    if request.method == "POST":
        obj.delete()
    return customers_view(request)


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
            return vehicles_view(request)
    else:
        form = VehicleForm()
    return render(request, "portal/forms/vehicle_form.html", {"form": form})


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
            return vehicles_view(request)
    else:
        form = VehicleForm(instance=obj)
    return render(request, "portal/forms/vehicle_form.html", {"form": form, "object": obj})


@login_required
def vehicle_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Vehicle, pk=pk)
    if request.method == "POST":
        obj.delete()
    return vehicles_view(request)


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
            return inspectors_view(request)
    else:
        form = InspectorProfileForm()
    return render(request, "portal/forms/inspector_form.html", {"form": form})


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
            return inspectors_view(request)
    else:
        form = InspectorProfileForm(instance=obj)
    return render(request, "portal/forms/inspector_form.html", {"form": form, "object": obj})


@login_required
def inspector_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(InspectorProfile, pk=pk)
    if request.method == "POST":
        obj.delete()
    return inspectors_view(request)


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
            return assignments_view(request)
    else:
        form = VehicleAssignmentForm()
    return render(request, "portal/forms/assignment_form.html", {"form": form})


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
            return assignments_view(request)
    else:
        form = VehicleAssignmentForm(instance=obj)
    return render(request, "portal/forms/assignment_form.html", {"form": form, "object": obj})


@login_required
def assignment_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(VehicleAssignment, pk=pk)
    if request.method == "POST":
        obj.delete()
    return assignments_view(request)


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
            return inspections_view(request)
    else:
        form = InspectionForm()
    return render(request, "portal/forms/inspection_form.html", {"form": form})


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
            return inspections_view(request)
    else:
        form = InspectionForm(instance=obj)
    return render(request, "portal/forms/inspection_form.html", {"form": form, "object": obj})


@login_required
def inspection_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(Inspection, pk=pk)
    if request.method == "POST":
        obj.delete()
    return inspections_view(request)


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
            return categories_view(request)
    else:
        form = InspectionCategoryForm()
    return render(request, "portal/forms/category_form.html", {"form": form})


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
            return categories_view(request)
    else:
        form = InspectionCategoryForm(instance=obj)
    return render(request, "portal/forms/category_form.html", {"form": form, "object": obj})


@login_required
def category_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    obj = get_object_or_404(InspectionCategory, pk=pk)
    if request.method == "POST":
        obj.delete()
    return categories_view(request)


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
            return categories_view(request)
    else:
        form = ChecklistItemForm(initial=initial)
    return render(request, "portal/forms/checklist_item_form.html", {"form": form})


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
            return categories_view(request)
    else:
        form = ChecklistItemForm(instance=obj)
    return render(request, "portal/forms/checklist_item_form.html", {"form": form, "object": obj})


@login_required
def checklist_item_delete(request: HttpRequest, pk: int) -> HttpResponse:
    profile = _require_admin(request)
    if not profile:
        return render(request, "portal/forbidden.html", status=403)
    # Direct import to avoid circular import at module top
    from .models import ChecklistItem

    obj = get_object_or_404(ChecklistItem, pk=pk)
    if request.method == "POST":
        obj.delete()
    return categories_view(request)
