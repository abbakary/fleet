from django.test import TestCase, Client
from django.contrib.auth.models import User
from portal.models import PortalUser

class DashboardViewTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(username='admin', password='testpass')
        self.user.is_staff = True
        self.user.save()
        # create portal user linked to this user and mark as admin
        self.portal_user = PortalUser.objects.create(user=self.user, role=PortalUser.ROLE_ADMIN)

    def test_dashboard_accessible_by_admin(self):
        self.client.force_login(self.user)
        resp = self.client.get('/admin/')
        self.assertEqual(resp.status_code, 200)
        # ensure KPI keys are present in response
        self.assertContains(resp, 'Inspections')

    def test_recent_inspections_partial(self):
        self.client.force_login(self.user)
        resp = self.client.get('/admin/recent-inspections/')
        self.assertEqual(resp.status_code, 200)
