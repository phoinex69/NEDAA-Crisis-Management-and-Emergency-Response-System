import bcrypt
from django.contrib.gis.geos import Point
from django.test import TestCase, override_settings
from rest_framework import status
from rest_framework.test import APIClient

from ai_pipeline.orchestrator import run_pipeline
from dispatch.models import ResourceAssignment
from incidents.models import IncidentCluster
from reports.models import Report
from resources.models import AccessRole, FieldUnit, OfficialAccount, Organization, UnitType
from users.models import User

DAMASCUS_LAT = 33.5138
DAMASCUS_LNG = 36.2765


@override_settings(RATELIMIT_ENABLE=False)
class TestDispatchFlow(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.citizen = User(email='dispatchcitizen@example.com', username='dispatchcitizen', is_verified=True, otp_verified=True)
        self.citizen.set_password('Citizen1234!')
        self.citizen.save()
        citizen_login = self.client.post('/api/v1/users/login/', {
            'identifier': 'dispatchcitizen@example.com',
            'password': 'Citizen1234!',
        }, format='json')
        self.citizen_headers = {'HTTP_AUTHORIZATION': f'Bearer {citizen_login.data["tokens"]["access"]}'}

        self.organization = Organization.objects.create(name='Test Civil Defense', organization_type='government')
        self.operator_role, _ = AccessRole.objects.get_or_create(
            name='operator', defaults={'permissions': {'dispatch': True, 'view': True}}
        )
        self.official_account = OfficialAccount.objects.create(
            email='dispatchofficial@example.com',
            password_hash=bcrypt.hashpw(b'Operator1234!', bcrypt.gensalt()).decode('utf-8'),
            full_name='Test Operator', organization=self.organization, role=self.operator_role, is_active=True,
        )
        official_login = self.client.post('/api/v1/resources/auth/login/', {
            'email': 'dispatchofficial@example.com',
            'password': 'Operator1234!',
        }, format='json')
        self.official_headers = {'HTTP_AUTHORIZATION': f'Bearer {official_login.data["tokens"]["access"]}'}

        self.unit_type = UnitType.objects.get(name='ambulance')
        self.unit = FieldUnit.objects.create(
            call_sign='TEST-AMB-01', unit_type=self.unit_type, organization=self.organization,
            status='available', current_latitude=DAMASCUS_LAT, current_longitude=DAMASCUS_LNG,
            current_location=Point(DAMASCUS_LNG, DAMASCUS_LAT, srid=4326),
        )

        self.report = Report.objects.create(
            reporter=self.citizen, report_type='medical', description='Dispatch test emergency',
            reported_severity=3, victims_count=1, status='received',
            latitude=DAMASCUS_LAT, longitude=DAMASCUS_LNG, submission_method='form',
        )
        run_pipeline(str(self.report.id))
        self.report.refresh_from_db()
        self.cluster = self.report.cluster
        self.assignment = ResourceAssignment.objects.filter(cluster=self.cluster, status='suggested').first()

    def test_get_suggestion(self):
        response = self.client.get(
            f'/api/v1/dispatch/incidents/{self.cluster.id}/suggestion/', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('unit_call_sign', response.data)
        self.assertIsNotNone(response.data['eta_minutes'])
        self.assertTrue(response.data['justification'])

    def test_available_units_list(self):
        response = self.client.get(
            f'/api/v1/dispatch/incidents/{self.cluster.id}/units/', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_confirm_dispatch(self):
        response = self.client.post(
            f'/api/v1/dispatch/assignments/{self.assignment.id}/confirm/', {}, format='json', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.assignment.refresh_from_db()
        self.assertEqual(self.assignment.status, 'confirmed')

        self.unit.refresh_from_db()
        self.assertEqual(self.unit.status, 'busy')

    def test_double_confirm_rejected(self):
        self.client.post(
            f'/api/v1/dispatch/assignments/{self.assignment.id}/confirm/', {}, format='json', **self.official_headers,
        )
        response = self.client.post(
            f'/api/v1/dispatch/assignments/{self.assignment.id}/confirm/', {}, format='json', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_complete_assignment(self):
        self.client.post(
            f'/api/v1/dispatch/assignments/{self.assignment.id}/confirm/', {}, format='json', **self.official_headers,
        )
        response = self.client.post(
            f'/api/v1/dispatch/assignments/{self.assignment.id}/complete/', {}, format='json', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.assignment.refresh_from_db()
        self.assertEqual(self.assignment.status, 'completed')

        self.unit.refresh_from_db()
        self.assertEqual(self.unit.status, 'available')

    def test_override_dispatch(self):
        second_unit = FieldUnit.objects.create(
            call_sign='TEST-AMB-02', unit_type=self.unit_type, organization=self.organization,
            status='available', current_latitude=DAMASCUS_LAT + 0.01, current_longitude=DAMASCUS_LNG + 0.01,
            current_location=Point(DAMASCUS_LNG + 0.01, DAMASCUS_LAT + 0.01, srid=4326),
        )

        response = self.client.post(
            f'/api/v1/dispatch/assignments/{self.assignment.id}/override/',
            {'unit_id': second_unit.id}, format='json', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.assignment.refresh_from_db()
        self.assertEqual(self.assignment.status, 'overridden')

        new_assignment = ResourceAssignment.objects.filter(cluster=self.cluster, status='confirmed').first()
        self.assertIsNotNone(new_assignment)
        self.assertEqual(new_assignment.unit_id, second_unit.id)

    def test_close_incident_creates_summary(self):
        response = self.client.post(
            f'/api/v1/incidents/{self.cluster.id}/close/',
            {'actual_severity': 3, 'note': 'Resolved'}, format='json', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.cluster.refresh_from_db()
        self.assertEqual(self.cluster.status, 'closed')

        from analytics.models import IncidentReportSummary
        self.assertTrue(IncidentReportSummary.objects.filter(incident=self.cluster).exists())

    def test_citizen_cannot_access_dispatch(self):
        response = self.client.get('/api/v1/dispatch/assignments/', **self.citizen_headers)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_assignment_list_filtered_by_status(self):
        response = self.client.get(
            '/api/v1/dispatch/assignments/?status=suggested', **self.official_headers,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data['results'] if 'results' in response.data else response.data
        for item in results:
            self.assertEqual(item['status'], 'suggested')
