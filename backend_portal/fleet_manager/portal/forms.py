from __future__ import annotations

from django import forms
from django.contrib.auth import get_user_model

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

User = get_user_model()


class StyledFormMixin:
    def _apply_widget_styles(self):
        for field in self.fields.values():
            css = field.widget.attrs.get("class", "").strip()
            base = "input"
            if isinstance(field.widget, (forms.Textarea,)):
                base = "textarea"
            elif isinstance(field.widget, (forms.Select, forms.SelectMultiple)):
                base = "select"
            elif isinstance(field.widget, forms.CheckboxInput):
                base = "checkbox"
            field.widget.attrs["class"] = (css + " " + base).strip()


class PortalUserCreateForm(forms.Form, StyledFormMixin):
    first_name = forms.CharField(label="First name", max_length=150)
    last_name = forms.CharField(label="Last name", max_length=150, required=False)
    username = forms.CharField(label="Username", max_length=150)
    email = forms.EmailField(label="Email address")
    role = forms.ChoiceField(label="Role", choices=PortalUser.ROLE_CHOICES)
    phone_number = forms.CharField(label="Phone number", max_length=32, required=False)
    organization = forms.CharField(label="Organization", max_length=255, required=False)
    job_title = forms.CharField(label="Job title", max_length=255, required=False)
    password1 = forms.CharField(label="Password", widget=forms.PasswordInput)
    password2 = forms.CharField(label="Confirm password", widget=forms.PasswordInput)
    is_active = forms.BooleanField(label="Active", required=False, initial=True)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._apply_widget_styles()

    def clean_username(self):
        username = self.cleaned_data["username"].strip()
        if User.objects.filter(username__iexact=username).exists():
            raise forms.ValidationError("A user with this username already exists.")
        return username

    def clean_email(self):
        email = self.cleaned_data["email"].strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise forms.ValidationError("A user with this email already exists.")
        return email

    def clean(self):
        data = super().clean()
        password1 = data.get("password1")
        password2 = data.get("password2")
        if password1 and password2 and password1 != password2:
            raise forms.ValidationError("Passwords do not match.")
        return data

    def save(self) -> PortalUser:
        data = self.cleaned_data
        user = User.objects.create_user(
            username=data["username"],
            email=data["email"],
            password=data["password1"],
            first_name=data["first_name"],
            last_name=data.get("last_name", ""),
        )
        user.is_active = data.get("is_active", False)
        user.save(update_fields=["is_active"])
        portal_user = PortalUser.objects.create(
            user=user,
            role=data["role"],
            phone_number=data.get("phone_number", ""),
            organization=data.get("organization", ""),
            job_title=data.get("job_title", ""),
        )
        return portal_user


class PortalUserUpdateForm(forms.ModelForm, StyledFormMixin):
    first_name = forms.CharField(label="First name", max_length=150)
    last_name = forms.CharField(label="Last name", max_length=150, required=False)
    email = forms.EmailField(label="Email address")
    username = forms.CharField(label="Username", max_length=150, disabled=True)
    is_active = forms.BooleanField(label="Active", required=False)

    class Meta:
        model = PortalUser
        fields = ["role", "phone_number", "organization", "job_title"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._apply_widget_styles()
        user = self.instance.user if self.instance else None
        if user:
            self.fields["first_name"].initial = user.first_name
            self.fields["last_name"].initial = user.last_name
            self.fields["email"].initial = user.email
            self.fields["username"].initial = user.username
            self.fields["is_active"].initial = user.is_active

    def save(self, commit=True):
        portal_user = super().save(commit=False)
        user = portal_user.user
        user.first_name = self.cleaned_data["first_name"]
        user.last_name = self.cleaned_data.get("last_name", "")
        user.email = self.cleaned_data["email"]
        user.is_active = self.cleaned_data.get("is_active", False)
        if commit:
            user.save()
            portal_user.save()
        return portal_user


class BaseForm(forms.ModelForm, StyledFormMixin):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._apply_widget_styles()


class CustomerForm(BaseForm):
    class Meta:
        model = Customer
        fields = [
            "profile",
            "legal_name",
            "contact_email",
            "contact_phone",
            "address_line1",
            "address_line2",
            "city",
            "state",
            "postal_code",
            "country",
            "notes",
        ]


class InspectorProfileForm(BaseForm):
    class Meta:
        model = InspectorProfile
        fields = [
            "profile",
            "badge_id",
            "certifications",
            "is_active",
            "max_daily_inspections",
        ]


class VehicleForm(BaseForm):
    class Meta:
        model = Vehicle
        fields = [
            "customer",
            "vin",
            "license_plate",
            "make",
            "model",
            "year",
            "vehicle_type",
            "axle_configuration",
            "mileage",
            "notes",
        ]


class VehicleAssignmentForm(BaseForm):
    scheduled_for = forms.DateField(widget=forms.DateInput(attrs={"type": "date"}))

    class Meta:
        model = VehicleAssignment
        fields = [
            "vehicle",
            "inspector",
            "scheduled_for",
            "status",
            "remarks",
        ]


class InspectionForm(BaseForm):
    started_at = forms.DateTimeField(required=False, widget=forms.DateTimeInput(attrs={"type": "datetime-local"}))
    completed_at = forms.DateTimeField(required=False, widget=forms.DateTimeInput(attrs={"type": "datetime-local"}))

    class Meta:
        model = Inspection
        fields = [
            "assignment",
            "vehicle",
            "customer",
            "inspector",
            "status",
            "started_at",
            "completed_at",
            "odometer_reading",
            "general_notes",
        ]


class InspectionCategoryForm(BaseForm):
    class Meta:
        model = InspectionCategory
        fields = [
            "code",
            "name",
            "description",
            "display_order",
        ]


class ChecklistItemForm(BaseForm):
    class Meta:
        model = ChecklistItem
        fields = [
            "category",
            "code",
            "title",
            "description",
            "requires_photo",
            "is_active",
        ]
