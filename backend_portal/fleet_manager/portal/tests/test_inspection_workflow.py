from __future__ import annotations

from datetime import date
from io import BytesIO

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.test import APITestCase

from portal.models import (
    ChecklistItem,
    Customer,
    Inspection,
    InspectionCategory,
    InspectionItemResponse,
    InspectionPhoto,
    InspectorProfile,
    PortalUser,
)
from portal.services import seed_checklist_structure

User = get_user_model()


class InspectionWorkflowTests(APITestCase):
    def setUp(self):
        self.admin_user = User.objects.create_user(username="admin", password="pass1234", email="admin@example.com")
        self.admin_profile = PortalUser.objects.create(user=self.admin_user, role=PortalUser.ROLE_ADMIN)

        self.customer_user = User.objects.create_user(username="customer", password="pass1234", email="customer@example.com")
        customer_portal = PortalUser.objects.create(user=self.customer_user, role=PortalUser.ROLE_CUSTOMER)
        self.customer = Customer.objects.create(
            profile=customer_portal,
            legal_name="Acme Logistics",
            contact_email="fleet@acme.com",
            contact_phone="555-0100",
            city="Denver",
            country="USA",
        )

        self.inspector_user = User.objects.create_user(username="inspector", password="pass1234", email="inspector@example.com")
        inspector_portal = PortalUser.objects.create(user=self.inspector_user, role=PortalUser.ROLE_INSPECTOR)
        self.inspector_profile = InspectorProfile.objects.create(profile=inspector_portal, badge_id="INS-1001")

        seed_checklist_structure()
        self.category = InspectionCategory.objects.get(code="pre_trip")
        self.checklist_item = ChecklistItem.objects.create(
            category=self.category,
            code="pre_trip_vehicle_id",
            title="Confirm vehicle identification",
            description="Validate VIN and license plate",
            requires_photo=False,
        )

    def authenticate(self, user):
        self.client.force_authenticate(user=user)

    def test_admin_can_create_vehicle_assignment_and_approve_inspection(self):
        self.authenticate(self.admin_user)
        vehicle_response = self.client.post(
            reverse("vehicle-list"),
            {
                "customer": self.customer.id,
                "vin": "1HGBH41JXMN109186",
                "license_plate": "FLEET01",
                "make": "Volvo",
                "model": "VNL 860",
                "year": 2023,
                "vehicle_type": "Tractor",
                "axle_configuration": "6x4",
                "mileage": 120000,
                "notes": "Primary long-haul tractor",
            },
            format="json",
        )
        self.assertEqual(vehicle_response.status_code, status.HTTP_201_CREATED)
        vehicle_id = vehicle_response.data["id"]

        assignment_response = self.client.post(
            reverse("assignment-list"),
            {
                "vehicle": vehicle_id,
                "inspector": self.inspector_profile.id,
                "assigned_by": self.admin_profile.id,
                "scheduled_for": date.today().isoformat(),
                "remarks": "Quarterly inspection",
            },
            format="json",
        )
        self.assertEqual(assignment_response.status_code, status.HTTP_201_CREATED)
        assignment_id = assignment_response.data["id"]

        self.client.force_authenticate(user=self.inspector_user)
        inspection_payload = {
            "assignment": assignment_id,
            "vehicle": vehicle_id,
            "inspector": self.inspector_profile.id,
            "status": Inspection.STATUS_IN_PROGRESS,
            "started_at": "2024-01-01T10:00:00Z",
            "odometer_reading": 125000,
            "general_notes": "Initial checks complete",
            "item_responses": [
                {
                    "checklist_item": self.checklist_item.id,
                    "result": "pass",
                    "severity": 1,
                    "notes": "All identifiers verified",
                }
            ],
        }
        inspection_response = self.client.post(reverse("inspection-list"), inspection_payload, format="json")
        self.assertEqual(inspection_response.status_code, status.HTTP_201_CREATED)
        inspection_id = inspection_response.data["id"]

        submit_response = self.client.post(reverse("inspection-submit", args=[inspection_id]), format="json")
        self.assertEqual(submit_response.status_code, status.HTTP_200_OK)
        self.assertEqual(submit_response.data["status"], Inspection.STATUS_SUBMITTED)

        self.client.force_authenticate(user=self.admin_user)
        approve_response = self.client.post(reverse("inspection-approve", args=[inspection_id]), format="json")
        self.assertEqual(approve_response.status_code, status.HTTP_200_OK)
        self.assertEqual(approve_response.data["status"], Inspection.STATUS_APPROVED)
        self.assertIn("report", approve_response.data)

        inspection = Inspection.objects.get(id=inspection_id)
        self.assertTrue(hasattr(inspection, "customer_report"))
        self.assertIn("No critical issues", inspection.customer_report.summary)

    def test_inspector_sees_only_assigned_vehicles(self):
        self.authenticate(self.admin_user)
        vehicle_a = self.client.post(
            reverse("vehicle-list"),
            {
                "customer": self.customer.id,
                "vin": "1N6AD0EV5KN717111",
                "license_plate": "FLEET02",
                "make": "Ford",
                "model": "F-750",
                "year": 2022,
                "vehicle_type": "Truck",
                "mileage": 80000,
            },
            format="json",
        ).data

        vehicle_b = self.client.post(
            reverse("vehicle-list"),
            {
                "customer": self.customer.id,
                "vin": "1N4AL3AP2JC123456",
                "license_plate": "POOL01",
                "make": "Nissan",
                "model": "Altima",
                "year": 2021,
                "vehicle_type": "Sedan",
                "mileage": 45000,
            },
            format="json",
        ).data

        self.client.post(
            reverse("assignment-list"),
            {
                "vehicle": vehicle_a["id"],
                "inspector": self.inspector_profile.id,
                "assigned_by": self.admin_profile.id,
                "scheduled_for": date.today().isoformat(),
            },
            format="json",
        )

        self.client.force_authenticate(user=self.inspector_user)
        response = self.client.get(reverse("vehicle-list"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        plates = {vehicle["license_plate"] for vehicle in response.data["results"]}
        self.assertIn("FLEET02", plates)
        self.assertNotIn("POOL01", plates)

    def test_inspector_can_create_inspection_with_photo_multipart(self):
        self.authenticate(self.admin_user)
        vehicle = self.client.post(
            reverse("vehicle-list"),
            {
                "customer": self.customer.id,
                "vin": "1FTFW1E89JFA00001",
                "license_plate": "TEST123",
                "make": "Ford",
                "model": "F-150",
                "year": 2022,
                "vehicle_type": "Truck",
            },
            format="json",
        ).data
        assignment = self.client.post(
            reverse("assignment-list"),
            {
                "vehicle": vehicle["id"],
                "inspector": self.inspector_profile.id,
                "assigned_by": self.admin_profile.id,
                "scheduled_for": date.today().isoformat(),
            },
            format="json",
        ).data

        # Build an in-memory PNG
        img_bytes = BytesIO()
        Image.new("RGB", (10, 10), color=(255, 0, 0)).save(img_bytes, format="PNG")
        img_bytes.seek(0)
        upload = SimpleUploadedFile("evidence.png", img_bytes.read(), content_type="image/png")

        self.client.force_authenticate(user=self.inspector_user)
        payload = {
            "assignment": str(assignment["id"]),
            "vehicle": str(vehicle["id"]),
            "inspector": str(self.inspector_profile.id),
            "status": Inspection.STATUS_IN_PROGRESS,
            "odometer_reading": "100",
            "general_notes": "Found issues",
            "item_responses[0][checklist_item]": str(self.checklist_item.id),
            "item_responses[0][result]": InspectionItemResponse.RESULT_FAIL,
            "item_responses[0][severity]": "3",
            "item_responses[0][notes]": "Crack on panel",
            "item_responses[0][photos][0][image]": upload,
        }
        response = self.client.post(reverse("inspection-list"), data=payload, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        inspection_id = response.data["id"]
        # Ensure photo persisted
        self.assertTrue(InspectionPhoto.objects.filter(response__inspection_id=inspection_id).exists())

    def test_requires_photo_enforced_for_failed_items(self):
        # mark item as requires photo
        self.checklist_item.requires_photo = True
        self.checklist_item.save(update_fields=["requires_photo"])

        self.authenticate(self.admin_user)
        vehicle = self.client.post(
            reverse("vehicle-list"),
            {
                "customer": self.customer.id,
                "vin": "1GCHK23114F000001",
                "license_plate": "REQ001",
                "make": "Chevrolet",
                "model": "Silverado",
                "year": 2020,
                "vehicle_type": "Truck",
            },
            format="json",
        ).data

        self.client.force_authenticate(user=self.inspector_user)
        bad_payload = {
            "vehicle": vehicle["id"],
            "inspector": self.inspector_profile.id,
            "status": Inspection.STATUS_IN_PROGRESS,
            "odometer_reading": 5,
            "general_notes": "",
            "item_responses": [
                {
                    "checklist_item": self.checklist_item.id,
                    "result": InspectionItemResponse.RESULT_FAIL,
                    "severity": 2,
                    "notes": "",
                    "photos": [],
                }
            ],
        }
        resp = self.client.post(reverse("inspection-list"), bad_payload, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("photo", str(resp.data).lower())
