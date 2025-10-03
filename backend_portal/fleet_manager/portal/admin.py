from django.contrib import admin

from . import models


@admin.register(models.PortalUser)
class PortalUserAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "phone_number", "organization", "job_title", "created_at")
    search_fields = ("user__username", "user__first_name", "user__last_name", "phone_number", "organization")
    list_filter = ("role",)


@admin.register(models.Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ("legal_name", "contact_email", "contact_phone", "city", "country", "created_at")
    search_fields = ("legal_name", "contact_email", "contact_phone", "city")
    autocomplete_fields = ("profile",)


@admin.register(models.InspectorProfile)
class InspectorProfileAdmin(admin.ModelAdmin):
    list_display = ("profile", "badge_id", "is_active", "max_daily_inspections")
    list_filter = ("is_active",)
    search_fields = ("badge_id", "profile__user__username", "profile__user__first_name", "profile__user__last_name")
    autocomplete_fields = ("profile",)


@admin.register(models.Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = (
        "license_plate",
        "vin",
        "customer",
        "make",
        "model",
        "year",
        "vehicle_type",
        "mileage",
    )
    search_fields = ("license_plate", "vin", "customer__legal_name", "make", "model")
    list_filter = ("vehicle_type", "customer")
    autocomplete_fields = ("customer",)


@admin.register(models.VehicleAssignment)
class VehicleAssignmentAdmin(admin.ModelAdmin):
    list_display = ("vehicle", "inspector", "scheduled_for", "status", "assigned_by")
    search_fields = (
        "vehicle__license_plate",
        "vehicle__vin",
        "inspector__badge_id",
        "inspector__profile__user__username",
        "assigned_by__user__username",
        "status",
    )
    autocomplete_fields = ("vehicle", "inspector", "assigned_by")
    list_filter = ("status", "scheduled_for")


@admin.register(models.InspectionCategory)
class InspectionCategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "code", "display_order")
    ordering = ("display_order",)
    search_fields = ("name", "code")


@admin.register(models.ChecklistItem)
class ChecklistItemAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "code", "requires_photo", "is_active")
    list_filter = ("category", "requires_photo", "is_active")
    search_fields = ("title", "code", "category__name")
    autocomplete_fields = ("category",)


class InspectionPhotoInline(admin.TabularInline):
    model = models.InspectionPhoto
    extra = 0


class InspectionItemResponseInline(admin.TabularInline):
    model = models.InspectionItemResponse
    extra = 0


@admin.register(models.Inspection)
class InspectionAdmin(admin.ModelAdmin):
    list_display = ("reference", "customer", "vehicle", "inspector", "status", "created_at")
    autocomplete_fields = ("assignment", "vehicle", "customer", "inspector")
    list_filter = ("status", "created_at", "vehicle__customer")
    search_fields = ("reference", "vehicle__license_plate", "vehicle__vin", "inspector__profile__user__username")
    inlines = [InspectionItemResponseInline]


@admin.register(models.InspectionItemResponse)
class InspectionItemResponseAdmin(admin.ModelAdmin):
    list_display = ("inspection", "checklist_item", "result", "severity", "updated_at")
    list_filter = ("result", "checklist_item__category")
    search_fields = ("inspection__reference", "checklist_item__title")
    autocomplete_fields = ("inspection", "checklist_item")
    inlines = [InspectionPhotoInline]


@admin.register(models.InspectionPhoto)
class InspectionPhotoAdmin(admin.ModelAdmin):
    list_display = ("response", "caption", "created_at")
    autocomplete_fields = ("response",)


@admin.register(models.CustomerReport)
class CustomerReportAdmin(admin.ModelAdmin):
    list_display = ("inspection", "published_at")
    autocomplete_fields = ("inspection",)
