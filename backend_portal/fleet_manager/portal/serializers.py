from __future__ import annotations

from django.contrib.auth import get_user_model
from django.db import transaction
from rest_framework import serializers

from .models import (
    ChecklistItem,
    Customer,
    CustomerReport,
    Inspection,
    InspectionCategory,
    InspectionItemResponse,
    InspectionPhoto,
    InspectorProfile,
    PortalUser,
    Vehicle,
    VehicleAssignment,
)

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ["id", "username", "first_name", "last_name", "email", "password", "is_active"]
        read_only_fields = ["id", "is_active"]

    def create(self, validated_data):
        password = validated_data.pop("password", None) or User.objects.make_random_password()
        user = User.objects.create_user(password=password, **validated_data)
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class PortalUserSerializer(serializers.ModelSerializer):
    user = UserSerializer()

    class Meta:
        model = PortalUser
        fields = [
            "id",
            "user",
            "role",
            "phone_number",
            "organization",
            "job_title",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def create(self, validated_data):
        user_data = validated_data.pop("user")
        user = UserSerializer().create(user_data)
        return PortalUser.objects.create(user=user, **validated_data)

    def update(self, instance, validated_data):
        user_data = validated_data.pop("user", None)
        if user_data:
            UserSerializer().update(instance.user, user_data)
        return super().update(instance, validated_data)


class CustomerSerializer(serializers.ModelSerializer):
    profile = PortalUserSerializer()

    class Meta:
        model = Customer
        fields = [
            "id",
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
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    @transaction.atomic
    def create(self, validated_data):
        profile_data = validated_data.pop("profile")
        portal_user = PortalUserSerializer().create({**profile_data, "role": PortalUser.ROLE_CUSTOMER})
        return Customer.objects.create(profile=portal_user, **validated_data)

    @transaction.atomic
    def update(self, instance, validated_data):
        profile_data = validated_data.pop("profile", None)
        if profile_data:
            PortalUserSerializer().update(instance.profile, profile_data)
        return super().update(instance, validated_data)


class InspectorProfileSerializer(serializers.ModelSerializer):
    profile = PortalUserSerializer()

    class Meta:
        model = InspectorProfile
        fields = [
            "id",
            "profile",
            "badge_id",
            "certifications",
            "is_active",
            "max_daily_inspections",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    @transaction.atomic
    def create(self, validated_data):
        profile_data = validated_data.pop("profile")
        portal_user = PortalUserSerializer().create({**profile_data, "role": PortalUser.ROLE_INSPECTOR})
        return InspectorProfile.objects.create(profile=portal_user, **validated_data)

    @transaction.atomic
    def update(self, instance, validated_data):
        profile_data = validated_data.pop("profile", None)
        if profile_data:
            PortalUserSerializer().update(instance.profile, profile_data)
        return super().update(instance, validated_data)


class VehicleSerializer(serializers.ModelSerializer):
    customer = serializers.PrimaryKeyRelatedField(queryset=Customer.objects.all())
    customer_display = serializers.SerializerMethodField()

    class Meta:
        model = Vehicle
        fields = [
            "id",
            "customer",
            "customer_display",
            "vin",
            "license_plate",
            "make",
            "model",
            "year",
            "vehicle_type",
            "axle_configuration",
            "mileage",
            "notes",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "customer_display", "created_at", "updated_at"]

    def get_customer_display(self, obj):
        return obj.customer.legal_name


class VehicleAssignmentSerializer(serializers.ModelSerializer):
    vehicle = serializers.PrimaryKeyRelatedField(queryset=Vehicle.objects.all())
    inspector = serializers.PrimaryKeyRelatedField(queryset=InspectorProfile.objects.filter(is_active=True))
    assigned_by = serializers.PrimaryKeyRelatedField(queryset=PortalUser.objects.filter(role=PortalUser.ROLE_ADMIN))

    class Meta:
        model = VehicleAssignment
        fields = [
            "id",
            "vehicle",
            "inspector",
            "assigned_by",
            "scheduled_for",
            "status",
            "remarks",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class InspectionPhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = InspectionPhoto
        fields = ["id", "image", "caption", "created_at"]
        read_only_fields = ["id", "created_at"]


class ChecklistItemSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(queryset=InspectionCategory.objects.all())
    category_name = serializers.CharField(source="category.name", read_only=True)

    class Meta:
        model = ChecklistItem
        fields = [
            "id",
            "category",
            "category_name",
            "code",
            "title",
            "description",
            "requires_photo",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "category_name", "created_at", "updated_at"]


class InspectionItemResponseSerializer(serializers.ModelSerializer):
    checklist_item_detail = ChecklistItemSerializer(source="checklist_item", read_only=True)
    photos = InspectionPhotoSerializer(many=True, required=False)

    class Meta:
        model = InspectionItemResponse
        fields = [
            "id",
            "checklist_item",
            "checklist_item_detail",
            "result",
            "severity",
            "notes",
            "photos",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "checklist_item_detail", "created_at", "updated_at"]

    def create(self, validated_data):
        photos_data = validated_data.pop("photos", [])
        response = InspectionItemResponse.objects.create(**validated_data)
        for photo_data in photos_data:
            InspectionPhoto.objects.create(response=response, **photo_data)
        return response

    def update(self, instance, validated_data):
        photos_data = validated_data.pop("photos", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if photos_data is not None:
            instance.photos.all().delete()
            for photo_data in photos_data:
                InspectionPhoto.objects.create(response=instance, **photo_data)
        return instance


class CustomerReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerReport
        fields = ["summary", "recommended_actions", "published_at"]
        read_only_fields = ["published_at"]


class InspectionSerializer(serializers.ModelSerializer):
    item_responses = InspectionItemResponseSerializer(many=True)
    inspector = serializers.PrimaryKeyRelatedField(queryset=InspectorProfile.objects.filter(is_active=True))
    vehicle = serializers.PrimaryKeyRelatedField(queryset=Vehicle.objects.all())
    customer = serializers.PrimaryKeyRelatedField(queryset=Customer.objects.all(), required=False)
    customer_report = CustomerReportSerializer(read_only=True)

    class Meta:
        model = Inspection
        fields = [
            "id",
            "reference",
            "assignment",
            "vehicle",
            "customer",
            "inspector",
            "status",
            "started_at",
            "completed_at",
            "odometer_reading",
            "general_notes",
            "item_responses",
            "customer_report",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "reference", "created_at", "updated_at", "customer", "customer_report"]

    def validate(self, attrs):
        vehicle = attrs.get("vehicle")
        inspector = attrs.get("inspector")
        assignment = attrs.get("assignment")
        if assignment and assignment.vehicle != vehicle:
            raise serializers.ValidationError("Assignment vehicle does not match the selected vehicle.")
        if assignment and assignment.inspector != inspector:
            raise serializers.ValidationError("Assignment inspector does not match the selected inspector.")
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        responses_data = validated_data.pop("item_responses", [])
        vehicle = validated_data["vehicle"]
        validated_data["customer"] = vehicle.customer
        inspection = Inspection.objects.create(**validated_data)
        for response_data in responses_data:
            response_serializer = InspectionItemResponseSerializer(data=response_data)
            response_serializer.is_valid(raise_exception=True)
            response_serializer.save(inspection=inspection)
        return inspection

    @transaction.atomic
    def update(self, instance, validated_data):
        responses_data = validated_data.pop("item_responses", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if responses_data is not None:
            instance.item_responses.all().delete()
            for response_data in responses_data:
                response_serializer = InspectionItemResponseSerializer(data=response_data)
                response_serializer.is_valid(raise_exception=True)
                response_serializer.save(inspection=instance)
        return instance


class InspectionListSerializer(serializers.ModelSerializer):
    vehicle = VehicleSerializer(read_only=True)
    inspector = InspectorProfileSerializer(read_only=True)
    customer = CustomerSerializer(read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = Inspection
        fields = [
            "id",
            "reference",
            "vehicle",
            "customer",
            "inspector",
            "status",
            "status_display",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class InspectionCategorySerializer(serializers.ModelSerializer):
    items = ChecklistItemSerializer(many=True, read_only=True)

    class Meta:
        model = InspectionCategory
        fields = ["id", "code", "name", "description", "display_order", "items"]
        read_only_fields = ["id", "display_order", "items"]
