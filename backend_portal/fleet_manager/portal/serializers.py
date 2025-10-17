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
    VehicleMake,
    VehicleModelName,
)

User = get_user_model()


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()

    def validate(self, attrs):
        username = attrs.get("username")
        password = attrs.get("password")
        if not username or not password:
            raise serializers.ValidationError('Must include "username" and "password".')

        from django.contrib.auth import authenticate

        user = None
        # Try username directly first
        user = authenticate(username=username, password=password)
        if user is None and "@" in username:
            # Fallback: try email -> username mapping
            try:
                user_obj = User.objects.get(email__iexact=username)
                user = authenticate(username=user_obj.username, password=password)
            except User.DoesNotExist:
                user = None
        if user is None:
            raise serializers.ValidationError("Unable to log in with provided credentials.")
        if not user.is_active:
            raise serializers.ValidationError("User account is disabled.")
        attrs["user"] = user
        return attrs


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


class VehicleModelNameSerializer(serializers.ModelSerializer):
    make_name = serializers.CharField(source="make.name", read_only=True)

    class Meta:
        model = VehicleModelName
        fields = ["id", "make", "make_name", "name", "created_at", "updated_at"]
        read_only_fields = ["id", "make_name", "created_at", "updated_at"]


class VehicleMakeSerializer(serializers.ModelSerializer):
    models = VehicleModelNameSerializer(many=True, read_only=True)

    class Meta:
        model = VehicleMake
        fields = ["id", "name", "models", "created_at", "updated_at"]
        read_only_fields = ["id", "models", "created_at", "updated_at"]


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

    @transaction.atomic
    def create(self, validated_data):
        instance = Vehicle.objects.create(**validated_data)
        _ensure_make_model_catalog(instance.make, instance.model)
        return instance

    @transaction.atomic
    def update(self, instance, validated_data):
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        _ensure_make_model_catalog(instance.make, instance.model)
        return instance


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


def _ensure_make_model_catalog(make_name: str, model_name: str) -> None:
    make_name = (make_name or "").strip()
    model_name = (model_name or "").strip()
    if not make_name:
        return
    make, _ = VehicleMake.objects.get_or_create(name=make_name)
    if model_name:
        VehicleModelName.objects.get_or_create(make=make, name=model_name)


class InspectionPhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = InspectionPhoto
        fields = ["id", "image", "caption", "created_at"]
        read_only_fields = ["id", "created_at"]

    def to_representation(self, instance):
        # Ensure the image URL is properly formatted for the frontend
        representation = super().to_representation(instance)
        if instance.image:
            # Get the full URL for the image
            request = self.context.get('request')
            if request:
                representation['image'] = request.build_absolute_uri(instance.image.url)
            else:
                representation['image'] = instance.image.url
        return representation

    def validate_image(self, value):
        # Handle case where value might be a string (file path or base64)
        if isinstance(value, str):
            # If it's a data URL, we might need to process it differently
            # For now, we'll just pass it through and let the model handle it
            return value
        return value

    def create(self, validated_data):
        # Handle file uploads properly
        image_data = validated_data.get('image')
        
        # Handle multipart file uploads (from Flutter app)
        if hasattr(image_data, 'name') and hasattr(image_data, 'read'):
            # This is already a file object, use it directly
            return super().create(validated_data)
        
        # Handle base64 encoded images
        if isinstance(image_data, str) and image_data.startswith('data:image'):
            from django.core.files.base import ContentFile
            import base64
            import uuid
            
            # Extract the base64 data
            format, imgstr = image_data.split(';base64,')
            ext = format.split('/')[-1]
            
            # Create a file-like object
            image_file = ContentFile(base64.b64decode(imgstr), name=f"photo_{uuid.uuid4()}.{ext}")
            validated_data['image'] = image_file
            return super().create(validated_data)
        
        # Handle string paths/URLs
        if isinstance(image_data, str):
            # For now, we'll just pass it through
            return super().create(validated_data)
        
        return super().create(validated_data)

    def update(self, instance, validated_data):
        # Handle file uploads properly
        image_data = validated_data.get('image')
        
        # Handle multipart file uploads (from Flutter app)
        if hasattr(image_data, 'name') and hasattr(image_data, 'read'):
            # This is already a file object, use it directly
            instance.image = image_data
            instance.save()
            return instance
        
        # Handle base64 encoded images
        if isinstance(image_data, str) and image_data.startswith('data:image'):
            from django.core.files.base import ContentFile
            import base64
            import uuid
            
            # Extract the base64 data
            format, imgstr = image_data.split(';base64,')
            ext = format.split('/')[-1]
            
            # Create a file-like object
            image_file = ContentFile(base64.b64decode(imgstr), name=f"photo_{uuid.uuid4()}.{ext}")
            validated_data['image'] = image_file
            return super().update(instance, validated_data)
        
        # Handle string paths/URLs
        if isinstance(image_data, str):
            # For now, we'll just pass it through
            return super().update(instance, validated_data)
        
        return super().update(instance, validated_data)


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
    checklist_item = serializers.PrimaryKeyRelatedField(queryset=ChecklistItem.objects.all())
    severity = serializers.IntegerField(required=False, default=1)

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

    def validate_checklist_item(self, value):
        # Handle case where value might be a string
        if isinstance(value, str):
            try:
                value = int(value)
            except (ValueError, TypeError):
                raise serializers.ValidationError("Invalid checklist item ID")
        return value

    def validate_severity(self, value):
        # Handle case where value might be a string
        if isinstance(value, str):
            try:
                value = int(value)
            except (ValueError, TypeError):
                value = 1
        # Ensure value is within valid range
        if value < 1:
            value = 1
        elif value > 5:
            value = 5
        return value

    def validate_result(self, value):
        # Ensure result is one of the valid choices
        valid_results = [InspectionItemResponse.RESULT_PASS, 
                        InspectionItemResponse.RESULT_FAIL, 
                        InspectionItemResponse.RESULT_NA]
        if value not in valid_results:
            # Default to pass if invalid
            return InspectionItemResponse.RESULT_PASS
        return value

    def validate(self, attrs):
        checklist_item = attrs.get("checklist_item")
        result = attrs.get("result", InspectionItemResponse.RESULT_PASS)
        photos = attrs.get("photos", [])
        
        # Convert checklist_item to proper object if it's an ID
        if isinstance(checklist_item, (str, int)):
            try:
                attrs["checklist_item"] = ChecklistItem.objects.get(pk=checklist_item)
                checklist_item = attrs["checklist_item"]
            except ChecklistItem.DoesNotExist:
                raise serializers.ValidationError({"checklist_item": "Invalid checklist item ID"})
        
        if result == InspectionItemResponse.RESULT_FAIL and checklist_item and getattr(checklist_item, "requires_photo", False):
            if not photos or (isinstance(photos, list) and len(photos) == 0):
                raise serializers.ValidationError("Photo evidence is required for failed items that require a photo.")
        return attrs

    def create(self, validated_data):
        photos_data = validated_data.pop("photos", [])
        response = InspectionItemResponse.objects.create(**validated_data)
        
        # Handle file uploads from Flutter multipart form
        request = self.context.get('request')
        
        # Check if this is a multipart form request with files
        if request and hasattr(request, 'FILES'):
            # Get all files sent under the 'photos' field (can contain multiple)
            # Fallback to all FILES values if the specific key isn't used
            uploaded_files = request.FILES.getlist('photos') or list(request.FILES.values())
            file_index = 0
            
            for photo_data in photos_data:
                if isinstance(photo_data, dict) and photo_data.get('is_local_file'):
                    # This corresponds to a file uploaded via multipart
                    if file_index < len(uploaded_files):
                        photo_file = uploaded_files[file_index]
                        try:
                            photo_serializer = InspectionPhotoSerializer(
                                data={'image': photo_file}, 
                                context=self.context
                            )
                            if photo_serializer.is_valid():
                                photo_serializer.save(response=response)
                            else:
                                # Log validation errors but continue
                                import logging
                                logger = logging.getLogger(__name__)
                                logger.error(f"Photo validation error: {photo_serializer.errors}")
                            file_index += 1
                        except Exception as e:
                            # Log error but continue processing other photos
                            import logging
                            logger = logging.getLogger(__name__)
                            logger.error(f"Error creating photo: {str(e)}")
                else:
                    # Handle other photo data formats (URLs, base64, etc.)
                    try:
                        photo_serializer = InspectionPhotoSerializer(
                            data=photo_data, 
                            context=self.context
                        )
                        if photo_serializer.is_valid():
                            photo_serializer.save(response=response)
                        else:
                            # Log validation errors but continue
                            import logging
                            logger = logging.getLogger(__name__)
                            logger.error(f"Photo validation error: {photo_serializer.errors}")
                    except Exception as e:
                        # Log error but continue processing other photos
                        import logging
                        logger = logging.getLogger(__name__)
                        logger.error(f"Error creating photo: {str(e)}")
        else:
            # Handle photo data that might be in different formats
            processed_photos = []
            if isinstance(photos_data, list):
                for photo_data in photos_data:
                    if isinstance(photo_data, dict):
                        # Handle dict with image data
                        if "image" in photo_data:
                            processed_photos.append(photo_data)
                        # Handle MultipartFile objects directly
                        elif "file" in photo_data:
                            processed_photos.append({"image": photo_data["file"]})
                        # Handle inspection photo objects directly
                        elif hasattr(photo_data, 'image'):
                            processed_photos.append({"image": photo_data.image})
                    elif isinstance(photo_data, str):
                        # Handle string photo data (likely file paths or base64)
                        processed_photos.append({"image": photo_data})
                    elif hasattr(photo_data, 'image'):
                        # Handle inspection photo objects directly
                        processed_photos.append({"image": photo_data.image})
            elif isinstance(photos_data, dict):
                # Handle single photo object
                if "image" in photos_data:
                    processed_photos.append(photos_data)
                elif "file" in photos_data:
                    processed_photos.append({"image": photos_data["file"]})
                elif hasattr(photos_data, 'image'):
                    processed_photos.append({"image": photos_data.image})
            elif isinstance(photos_data, str):
                # Handle single string photo data
                processed_photos.append({"image": photos_data})
            
            for photo_data in processed_photos:
                # Skip if image field is missing
                if "image" in photo_data:
                    try:
                        photo_serializer = InspectionPhotoSerializer(data=photo_data, context=self.context)
                        if photo_serializer.is_valid():
                            photo_serializer.save(response=response)
                        else:
                            # Log validation errors but continue
                            import logging
                            logger = logging.getLogger(__name__)
                            logger.error(f"Photo validation error: {photo_serializer.errors}")
                    except Exception as e:
                        # Log error but continue processing other photos
                        import logging
                        logger = logging.getLogger(__name__)
                        logger.error(f"Error creating photo: {str(e)}")
        
        return response

    def update(self, instance, validated_data):
        photos_data = validated_data.pop("photos", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if photos_data is not None:
            instance.photos.all().delete()
            
            # Handle file uploads from Flutter multipart form
            request = self.context.get('request')
            
            # Check if this is a multipart form request with files
            if request and hasattr(request, 'FILES'):
                # Get all files sent under the 'photos' field (can contain multiple)
                # Fallback to all FILES values if the specific key isn't used
                uploaded_files = request.FILES.getlist('photos') or list(request.FILES.values())
                file_index = 0
                
                for photo_data in photos_data:
                    if isinstance(photo_data, dict) and photo_data.get('is_local_file'):
                        # This corresponds to a file uploaded via multipart
                        if file_index < len(uploaded_files):
                            photo_file = uploaded_files[file_index]
                            try:
                                photo_serializer = InspectionPhotoSerializer(
                                    data={'image': photo_file}, 
                                    context=self.context
                                )
                                if photo_serializer.is_valid():
                                    photo_serializer.save(response=instance)
                                else:
                                    # Log validation errors but continue
                                    import logging
                                    logger = logging.getLogger(__name__)
                                    logger.error(f"Photo validation error: {photo_serializer.errors}")
                                file_index += 1
                            except Exception as e:
                                # Log error but continue processing other photos
                                import logging
                                logger = logging.getLogger(__name__)
                                logger.error(f"Error creating photo: {str(e)}")
                    else:
                        # Handle other photo data formats (URLs, base64, etc.)
                        try:
                            photo_serializer = InspectionPhotoSerializer(
                                data=photo_data, 
                                context=self.context
                            )
                            if photo_serializer.is_valid():
                                photo_serializer.save(response=instance)
                            else:
                                # Log validation errors but continue
                                import logging
                                logger = logging.getLogger(__name__)
                                logger.error(f"Photo validation error: {photo_serializer.errors}")
                        except Exception as e:
                            # Log error but continue processing other photos
                            import logging
                            logger = logging.getLogger(__name__)
                            logger.error(f"Error creating photo: {str(e)}")
            else:
                # Handle photo data that might be in different formats
                processed_photos = []
                if isinstance(photos_data, list):
                    for photo_data in photos_data:
                        if isinstance(photo_data, dict):
                            # Handle dict with image data
                            if "image" in photo_data:
                                processed_photos.append(photo_data)
                            # Handle MultipartFile objects directly
                            elif "file" in photo_data:
                                processed_photos.append({"image": photo_data["file"]})
                            # Handle inspection photo objects directly
                            elif hasattr(photo_data, 'image'):
                                processed_photos.append({"image": photo_data.image})
                        elif isinstance(photo_data, str):
                            # Handle string photo data (likely file paths or base64)
                            processed_photos.append({"image": photo_data})
                        elif hasattr(photo_data, 'image'):
                            # Handle inspection photo objects directly
                            processed_photos.append({"image": photo_data.image})
                elif isinstance(photos_data, dict):
                    # Handle single photo object
                    if "image" in photos_data:
                        processed_photos.append(photos_data)
                    elif "file" in photos_data:
                        processed_photos.append({"image": photos_data["file"]})
                    elif hasattr(photos_data, 'image'):
                        processed_photos.append({"image": photos_data.image})
                elif isinstance(photos_data, str):
                    # Handle single string photo data
                    processed_photos.append({"image": photos_data})
                
                for photo_data in processed_photos:
                    # Skip if image field is missing
                    if "image" in photo_data:
                        try:
                            photo_serializer = InspectionPhotoSerializer(data=photo_data, context=self.context)
                            if photo_serializer.is_valid():
                                photo_serializer.save(response=instance)
                            else:
                                # Log validation errors but continue
                                import logging
                                logger = logging.getLogger(__name__)
                                logger.error(f"Photo validation error: {photo_serializer.errors}")
                        except Exception as e:
                            # Log error but continue processing other photos
                            import logging
                            logger = logging.getLogger(__name__)
                            logger.error(f"Error creating photo: {str(e)}")
        
        return instance


class CustomerReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerReport
        fields = ["summary", "recommended_actions", "published_at"]
        read_only_fields = ["published_at"]


class InspectionSerializer(serializers.ModelSerializer):
    item_responses = InspectionItemResponseSerializer(many=True)
    inspector = serializers.PrimaryKeyRelatedField(queryset=InspectorProfile.objects.filter(is_active=True), required=False)
    vehicle = serializers.PrimaryKeyRelatedField(queryset=Vehicle.objects.all())
    customer = serializers.PrimaryKeyRelatedField(queryset=Customer.objects.all(), required=False)
    customer_report = CustomerReportSerializer(read_only=True)
    odometer_reading = serializers.IntegerField(required=False, default=0)
    assignment = serializers.PrimaryKeyRelatedField(queryset=VehicleAssignment.objects.all(), required=False, allow_null=True)

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

    def validate_odometer_reading(self, value):
        # Handle case where value might be a string
        if isinstance(value, str):
            try:
                value = int(value)
            except (ValueError, TypeError):
                value = 0
        return max(0, value)  # Ensure non-negative value

    def validate_assignment(self, value):
        # Handle case where value might be a string
        if isinstance(value, str):
            try:
                value = int(value)
                return VehicleAssignment.objects.get(pk=value)
            except (ValueError, TypeError, VehicleAssignment.DoesNotExist):
                return None
        return value

    def validate_vehicle(self, value):
        # Handle case where value might be a string
        if isinstance(value, str):
            try:
                value = int(value)
                return Vehicle.objects.get(pk=value)
            except (ValueError, TypeError, Vehicle.DoesNotExist):
                raise serializers.ValidationError("Invalid vehicle ID")
        return value

    def validate_inspector(self, value):
        # Handle case where value might be a string
        if isinstance(value, str):
            try:
                value = int(value)
                return InspectorProfile.objects.get(pk=value)
            except (ValueError, TypeError, InspectorProfile.DoesNotExist):
                return None
        return value

    def validate(self, attrs):
        request = self.context.get("request")
        # Handle inspector from authenticated user if not provided in payload
        if "inspector" not in attrs or attrs["inspector"] is None:
            if request is not None:
                try:
                    portal = getattr(request.user, "portal_profile", None)
                    inferred = getattr(portal, "inspector_profile", None)
                    if inferred is not None:
                        attrs["inspector"] = inferred
                except Exception:
                    pass  # Will be handled by regular validation
        
        # If we still don't have an inspector, raise validation error
        if "inspector" not in attrs or attrs["inspector"] is None:
            raise serializers.ValidationError({
                "inspector": "Inspector is required."
            })
            
        # Ensure vehicle is provided
        if "vehicle" not in attrs or attrs["vehicle"] is None:
            raise serializers.ValidationError({
                "vehicle": "Vehicle is required."
            })
            
        vehicle = attrs.get("vehicle")
        inspector = attrs.get("inspector")
        assignment = attrs.get("assignment")

        if assignment and assignment.vehicle != vehicle:
            raise serializers.ValidationError({
                "assignment": "Assignment vehicle does not match the selected vehicle.",
                "vehicle": f"Expected vehicle {assignment.vehicle.id}, but got {vehicle.id if vehicle else 'None'}."
            })
        if assignment and assignment.inspector != inspector:
            raise serializers.ValidationError({
                "assignment": "Assignment inspector does not match the selected inspector.",
                "inspector": f"Expected inspector {assignment.inspector.id}, but got {inspector.id if inspector else 'None'}."
            })
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        responses_data = validated_data.pop("item_responses", [])
        vehicle = validated_data["vehicle"]
        # Automatically set customer from vehicle
        validated_data["customer"] = vehicle.customer
        inspection = Inspection.objects.create(**validated_data)
        for response_data in responses_data:
            # Make sure checklist_item is provided and valid
            if "checklist_item" not in response_data:
                continue  # Skip invalid responses
            
            # Handle photo data that might be in different formats
            if "photos" in response_data:
                photos_data = response_data.pop("photos", [])
                # Process photos data to ensure it's in the correct format
                processed_photos = []
                if isinstance(photos_data, list):
                    for photo in photos_data:
                        if isinstance(photo, dict) and "image" in photo:
                            processed_photos.append(photo)
                        elif isinstance(photo, str):
                            # Handle string photo data
                            processed_photos.append({"image": photo})
                elif isinstance(photos_data, dict) and "image" in photos_data:
                    processed_photos.append(photos_data)
                
                response_data["photos"] = processed_photos
            
            # Pass the request context to ensure proper URL generation for photos
            context = getattr(self, 'context', {})
            response_serializer = InspectionItemResponseSerializer(data=response_data, context=context)
            if response_serializer.is_valid():
                response_serializer.save(inspection=inspection)
            else:
                # Log validation errors for debugging but don't fail the entire inspection
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Item response validation error: {response_serializer.errors}")
                # Continue with other responses rather than failing completely
        return inspection

    def update(self, instance, validated_data):
        responses_data = validated_data.pop("item_responses", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if responses_data is not None:
            instance.item_responses.all().delete()
            for response_data in responses_data:
                # Make sure checklist_item is provided and valid
                if "checklist_item" not in response_data:
                    continue  # Skip invalid responses
                    
                # Handle photo data that might be in different formats
                if "photos" in response_data:
                    photos_data = response_data.pop("photos", [])
                    # Process photos data to ensure it's in the correct format
                    processed_photos = []
                    if isinstance(photos_data, list):
                        for photo in photos_data:
                            if isinstance(photo, dict) and "image" in photo:
                                processed_photos.append(photo)
                            elif isinstance(photo, str):
                                # Handle string photo data
                                processed_photos.append({"image": photo})
                    elif isinstance(photos_data, dict) and "image" in photos_data:
                        processed_photos.append(photos_data)
                    
                    response_data["photos"] = processed_photos
                
                # Pass the request context to ensure proper URL generation for photos
                context = getattr(self, 'context', {})
                response_serializer = InspectionItemResponseSerializer(data=response_data, context=context)
                # Provide better error messages for response validation
                if response_serializer.is_valid():
                    response_serializer.save(inspection=instance)
                else:
                    # Log validation errors for debugging but don't fail the entire inspection
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Item response validation error: {response_serializer.errors}")
                    # Continue with other responses rather than failing completely
        return instance


class InspectionListSerializer(serializers.ModelSerializer):
    vehicle = VehicleSerializer(read_only=True)
    inspector = InspectorProfileSerializer(read_only=True)
    customer = CustomerSerializer(read_only=True)
    customer_report = CustomerReportSerializer(read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    critical_issue_count = serializers.SerializerMethodField()

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
            "critical_issue_count",
            "customer_report",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_critical_issue_count(self, obj: Inspection) -> int:
        responses = getattr(obj, "item_responses", None)
        if responses is None:
            return 0
        iterable = responses.all() if hasattr(responses, "all") else responses
        return sum(1 for response in iterable if response.result == InspectionItemResponse.RESULT_FAIL)


class InspectionCategorySerializer(serializers.ModelSerializer):
    items = ChecklistItemSerializer(many=True, read_only=True)

    class Meta:
        model = InspectionCategory
        fields = ["id", "code", "name", "description", "display_order", "items"]
        read_only_fields = ["id", "display_order", "items"]
