from __future__ import annotations

import json
from typing import Any, List, Tuple

from django.db.models import Prefetch
from django.http import QueryDict
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import (
    ChecklistItem,
    Customer,
    Inspection,
    InspectionCategory,
    InspectionItemResponse,
    InspectorProfile,
    PortalUser,
    Vehicle,
    VehicleAssignment,
    VehicleMake,
    VehicleModelName,
)
from .permissions import IsAdmin, IsInspectorOrAdmin, get_portal_profile
from .serializers import (
    ChecklistItemSerializer,
    CustomerSerializer,
    InspectionCategorySerializer,
    InspectionListSerializer,
    InspectionSerializer,
    InspectorProfileSerializer,
    PortalUserSerializer,
    VehicleAssignmentSerializer,
    VehicleSerializer,
    VehicleMakeSerializer,
    VehicleModelNameSerializer,
)
from .services import generate_customer_report


def _extract_data_pairs(data: Any) -> List[Tuple[str, List[Any]]]:
    if isinstance(data, QueryDict):
        return [(key, list(values)) for key, values in data.lists()]
    if isinstance(data, dict):
        pairs: List[Tuple[str, List[Any]]] = []
        for key, value in data.items():
            if isinstance(value, list):
                pairs.append((key, value))
            else:
                pairs.append((key, [value]))
        return pairs
    return []


def _assign_path(container: Any, path: List[str], values: List[Any]) -> None:
    segment = path[0]
    is_last = len(path) == 1
    value: Any = values if len(values) > 1 else values[0]

    if isinstance(container, list):
        if not segment.isdigit():
            return
        index = int(segment)
        while len(container) <= index:
            container.append(None)
        if is_last:
            container[index] = value
            return
        next_segment = path[1]
        child = container[index]
        if child is None or (next_segment.isdigit() and not isinstance(child, list)) or (not next_segment.isdigit() and not isinstance(child, dict)):
            container[index] = [] if next_segment.isdigit() else {}
        _assign_path(container[index], path[1:], values)
        return

    if is_last:
        container[segment] = value
        return

    next_segment = path[1]
    child = container.get(segment)
    if child is None or (next_segment.isdigit() and not isinstance(child, list)) or (not next_segment.isdigit() and not isinstance(child, dict)):
        container[segment] = [] if next_segment.isdigit() else {}
    _assign_path(container[segment], path[1:], values)


def _assign_nested_item(buckets: dict[int, dict[str, Any]], key: str, values: List[Any]) -> None:
    prefix = "item_responses["
    remainder = key[len(prefix) :]
    remainder = remainder.rstrip("]")
    if not remainder:
        return
    segments = remainder.split("][")
    try:
        index = int(segments[0])
    except ValueError:
        return
    path = segments[1:]
    if not path:
        return
    bucket = buckets.setdefault(index, {})
    _assign_path(bucket, path, values)


def _normalize_inspection_payload(data: Any) -> dict[str, Any]:
    base_payload: dict[str, Any] = {}
    nested_items: dict[int, dict[str, Any]] = {}

    for key, values in _extract_data_pairs(data):
        if key.startswith("item_responses["):
            _assign_nested_item(nested_items, key, values)
            continue
        if key == "item_responses" and len(values) == 1 and isinstance(values[0], str):
            try:
                base_payload[key] = json.loads(values[0])
            except json.JSONDecodeError:
                base_payload[key] = []
            continue
        base_payload[key] = values[0] if len(values) == 1 else values

    if "item_responses" not in base_payload:
        if nested_items:
            base_payload["item_responses"] = [nested_items[index] for index in sorted(nested_items)]
        else:
            base_payload["item_responses"] = []
    else:
        responses = base_payload["item_responses"]
        if isinstance(responses, str):
            try:
                base_payload["item_responses"] = json.loads(responses)
            except json.JSONDecodeError:
                base_payload["item_responses"] = []
        elif isinstance(responses, list):
            base_payload["item_responses"] = [item for item in responses if isinstance(item, dict)]

    return base_payload


class AuthTokenView(ObtainAuthToken):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _created = Token.objects.get_or_create(user=user)
        profile = get_portal_profile(user)
        profile_data = PortalUserSerializer(profile).data if profile else None
        return Response({"token": token.key, "profile": profile_data})


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.select_related("profile", "profile__user").all()
    serializer_class = CustomerSerializer
    permission_classes = [IsAuthenticated, IsAdmin]
    pagination_class = None


class InspectorProfileViewSet(viewsets.ModelViewSet):
    queryset = InspectorProfile.objects.select_related("profile", "profile__user").all()
    serializer_class = InspectorProfileSerializer
    permission_classes = [IsAuthenticated, IsAdmin]
    pagination_class = None


class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        profile = get_portal_profile(self.request.user)
        queryset = Vehicle.objects.select_related("customer", "customer__profile", "customer__profile__user").all()
        if not profile:
            return queryset.none()
        if profile.role == PortalUser.ROLE_ADMIN:
            return queryset
        customer_profile = getattr(profile, "customer_profile", None)
        if customer_profile:
            return queryset.filter(customer=customer_profile)
        inspector_profile = getattr(profile, "inspector_profile", None)
        if inspector_profile:
            return queryset.filter(assignments__inspector=inspector_profile).distinct()
        return queryset.none()

    def get_permissions(self):
        if self.action == "create":
            return [IsAuthenticated(), IsInspectorOrAdmin()]
        if self.action in ["update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsAdmin()]
        return super().get_permissions()


class VehicleAssignmentViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleAssignmentSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        profile = get_portal_profile(self.request.user)
        queryset = VehicleAssignment.objects.select_related(
            "vehicle",
            "vehicle__customer",
            "inspector",
            "inspector__profile",
            "inspector__profile__user",
        )
        if not profile:
            return queryset.none()
        if profile.role == PortalUser.ROLE_ADMIN:
            return queryset
        inspector_profile = getattr(profile, "inspector_profile", None)
        if inspector_profile:
            return queryset.filter(inspector=inspector_profile)
        return queryset.none()

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated(), IsInspectorOrAdmin()]


class VehicleMakeViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleMakeSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        queryset = VehicleMake.objects.prefetch_related("models").order_by("name")
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(name__icontains=search)
        return queryset

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsInspectorOrAdmin()]
        return [IsAuthenticated()]


class VehicleModelNameViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleModelNameSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        queryset = VehicleModelName.objects.select_related("make").order_by("name")
        make_id = self.request.query_params.get("make")
        make_name = self.request.query_params.get("make_name")
        search = self.request.query_params.get("search")
        if make_id:
            queryset = queryset.filter(make_id=make_id)
        elif make_name:
            queryset = queryset.filter(make__name__iexact=make_name)
        if search:
            queryset = queryset.filter(name__icontains=search)
        return queryset

    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsInspectorOrAdmin()]
        return [IsAuthenticated()]


class InspectionViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    pagination_class = None
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    queryset = Inspection.objects.select_related(
        "vehicle",
        "vehicle__customer",
        "vehicle__customer__profile",
        "inspector",
        "inspector__profile",
        "inspector__profile__user",
        "customer",
    ).prefetch_related(
        Prefetch(
            "item_responses",
            queryset=InspectionItemResponse.objects.select_related("checklist_item", "checklist_item__category").prefetch_related("photos"),
        )
    )

    def get_serializer_class(self):
        if self.action == "list":
            return InspectionListSerializer
        return InspectionSerializer

    def get_queryset(self):
        profile = get_portal_profile(self.request.user)
        if not profile:
            return Inspection.objects.none()
        queryset = super().get_queryset()
        if profile.role == PortalUser.ROLE_ADMIN:
            return queryset
        inspector_profile = getattr(profile, "inspector_profile", None)
        if inspector_profile:
            return queryset.filter(inspector=inspector_profile)
        customer_profile = getattr(profile, "customer_profile", None)
        if customer_profile:
            return queryset.filter(customer=customer_profile)
        return queryset.none()

    def _prepare_payload(self, request):
        return _normalize_inspection_payload(request.data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=self._prepare_payload(request))
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=self._prepare_payload(request), partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        kwargs["partial"] = True
        return self.update(request, *args, **kwargs)

    def perform_create(self, serializer):
        profile = get_portal_profile(self.request.user)
        inspector_profile = getattr(profile, "inspector_profile", None) if profile else None
        if inspector_profile:
            serializer.save(inspector=inspector_profile)
        else:
            serializer.save()

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsInspectorOrAdmin])
    def submit(self, request, pk=None):
        inspection = self.get_object()
        inspection.status = Inspection.STATUS_SUBMITTED
        inspection.completed_at = inspection.completed_at or inspection.updated_at
        inspection.save(update_fields=["status", "completed_at", "updated_at"])
        generate_customer_report(inspection)
        return Response(InspectionSerializer(inspection).data)

    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated, IsAdmin])
    def approve(self, request, pk=None):
        inspection = self.get_object()
        inspection.status = Inspection.STATUS_APPROVED
        inspection.save(update_fields=["status", "updated_at"])
        report = generate_customer_report(inspection)
        return Response({"status": inspection.status, "report": report.summary})


class InspectionCategoryViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    queryset = InspectionCategory.objects.prefetch_related("items")
    serializer_class = InspectionCategorySerializer
    permission_classes = [AllowAny]
    pagination_class = None


class ChecklistItemViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ChecklistItem.objects.filter(is_active=True).select_related("category")
    serializer_class = ChecklistItemSerializer
    permission_classes = [AllowAny]
    pagination_class = None
