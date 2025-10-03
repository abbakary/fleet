from __future__ import annotations

import uuid

from django.contrib.auth import get_user_model
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone

User = get_user_model()


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class PortalUser(TimeStampedModel):
    ROLE_ADMIN = "admin"
    ROLE_INSPECTOR = "inspector"
    ROLE_CUSTOMER = "customer"

    ROLE_CHOICES = [
        (ROLE_ADMIN, "Admin"),
        (ROLE_INSPECTOR, "Inspector"),
        (ROLE_CUSTOMER, "Customer"),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="portal_profile")
    role = models.CharField(max_length=24, choices=ROLE_CHOICES)
    phone_number = models.CharField(max_length=32, blank=True)
    organization = models.CharField(max_length=255, blank=True)
    job_title = models.CharField(max_length=255, blank=True)

    class Meta:
        verbose_name = "Portal User"
        verbose_name_plural = "Portal Users"
        indexes = [
            models.Index(fields=["role"]),
        ]

    def __str__(self) -> str:
        return f"{self.user.get_full_name() or self.user.username} ({self.get_role_display()})"


class Customer(TimeStampedModel):
    profile = models.OneToOneField(
        PortalUser,
        on_delete=models.CASCADE,
        related_name="customer_profile",
        limit_choices_to={"role": PortalUser.ROLE_CUSTOMER},
    )
    legal_name = models.CharField(max_length=255)
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=32, blank=True)
    address_line1 = models.CharField(max_length=255, blank=True)
    address_line2 = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=80, blank=True)
    state = models.CharField(max_length=80, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)
    country = models.CharField(max_length=80, default="USA")
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["legal_name"]

    def __str__(self) -> str:
        return self.legal_name


class InspectorProfile(TimeStampedModel):
    profile = models.OneToOneField(
        PortalUser,
        on_delete=models.CASCADE,
        related_name="inspector_profile",
        limit_choices_to={"role": PortalUser.ROLE_INSPECTOR},
    )
    badge_id = models.CharField(max_length=64, unique=True)
    certifications = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    max_daily_inspections = models.PositiveIntegerField(default=8)

    class Meta:
        ordering = ["badge_id"]

    def __str__(self) -> str:
        return f"{self.profile}"


class Vehicle(TimeStampedModel):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name="vehicles")
    vin = models.CharField(max_length=32, unique=True)
    license_plate = models.CharField(max_length=20)
    make = models.CharField(max_length=120)
    model = models.CharField(max_length=120)
    year = models.PositiveIntegerField(validators=[MinValueValidator(1900), MaxValueValidator(timezone.now().year + 1)])
    vehicle_type = models.CharField(max_length=120)
    axle_configuration = models.CharField(max_length=120, blank=True)
    mileage = models.PositiveIntegerField(default=0)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["customer", "license_plate"]
        indexes = [
            models.Index(fields=["customer", "vehicle_type"]),
        ]

    def __str__(self) -> str:
        return f"{self.license_plate} ({self.vin})"


class VehicleAssignment(TimeStampedModel):
    STATUS_ASSIGNED = "assigned"
    STATUS_IN_PROGRESS = "in_progress"
    STATUS_COMPLETED = "completed"

    STATUS_CHOICES = [
        (STATUS_ASSIGNED, "Assigned"),
        (STATUS_IN_PROGRESS, "In Progress"),
        (STATUS_COMPLETED, "Completed"),
    ]

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="assignments")
    inspector = models.ForeignKey(InspectorProfile, on_delete=models.CASCADE, related_name="assignments")
    assigned_by = models.ForeignKey(
        PortalUser,
        on_delete=models.SET_NULL,
        null=True,
        related_name="assigned_inspections",
        limit_choices_to={"role": PortalUser.ROLE_ADMIN},
    )
    scheduled_for = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_ASSIGNED)
    remarks = models.TextField(blank=True)

    class Meta:
        unique_together = ("vehicle", "inspector", "scheduled_for")
        ordering = ["-scheduled_for"]

    def __str__(self) -> str:
        return f"{self.vehicle} -> {self.inspector} on {self.scheduled_for}"


class InspectionCategory(TimeStampedModel):
    code = models.CharField(max_length=64, unique=True)
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    display_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["display_order", "name"]

    def __str__(self) -> str:
        return f"{self.name}"


class ChecklistItem(TimeStampedModel):
    category = models.ForeignKey(InspectionCategory, on_delete=models.CASCADE, related_name="items")
    code = models.CharField(max_length=64)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    requires_photo = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("category", "code")
        ordering = ["category", "code"]

    def __str__(self) -> str:
        return f"{self.category.name} - {self.title}"


class Inspection(TimeStampedModel):
    STATUS_DRAFT = "draft"
    STATUS_IN_PROGRESS = "in_progress"
    STATUS_SUBMITTED = "submitted"
    STATUS_APPROVED = "approved"

    STATUS_CHOICES = [
        (STATUS_DRAFT, "Draft"),
        (STATUS_IN_PROGRESS, "In Progress"),
        (STATUS_SUBMITTED, "Submitted"),
        (STATUS_APPROVED, "Approved"),
    ]

    reference = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    assignment = models.ForeignKey(
        VehicleAssignment,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="inspections",
    )
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="inspections")
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name="inspections")
    inspector = models.ForeignKey(InspectorProfile, on_delete=models.CASCADE, related_name="inspections")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_DRAFT)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    odometer_reading = models.PositiveIntegerField(default=0)
    general_notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["customer", "created_at"]),
        ]

    def __str__(self) -> str:
        return f"Inspection {self.reference}"


class InspectionItemResponse(TimeStampedModel):
    RESULT_PASS = "pass"
    RESULT_FAIL = "fail"
    RESULT_NA = "not_applicable"

    RESULT_CHOICES = [
        (RESULT_PASS, "Pass"),
        (RESULT_FAIL, "Fail"),
        (RESULT_NA, "Not Applicable"),
    ]

    inspection = models.ForeignKey(Inspection, on_delete=models.CASCADE, related_name="item_responses")
    checklist_item = models.ForeignKey(ChecklistItem, on_delete=models.CASCADE, related_name="responses")
    result = models.CharField(max_length=16, choices=RESULT_CHOICES)
    severity = models.PositiveSmallIntegerField(default=1, validators=[MinValueValidator(1), MaxValueValidator(5)])
    notes = models.TextField(blank=True)

    class Meta:
        unique_together = ("inspection", "checklist_item")
        ordering = ["checklist_item__category__display_order", "checklist_item__code"]

    def __str__(self) -> str:
        return f"{self.inspection.reference} - {self.checklist_item.title}"


class InspectionPhoto(TimeStampedModel):
    response = models.ForeignKey(InspectionItemResponse, on_delete=models.CASCADE, related_name="photos")
    image = models.ImageField(upload_to="inspection_photos/%Y/%m/%d")
    caption = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self) -> str:
        return f"Photo for {self.response}"


class CustomerReport(TimeStampedModel):
    inspection = models.OneToOneField(Inspection, on_delete=models.CASCADE, related_name="customer_report")
    summary = models.TextField()
    recommended_actions = models.TextField(blank=True)
    published_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-published_at"]

    def __str__(self) -> str:
        return f"Customer report for {self.inspection.reference}"
