from django.contrib.gis.geos import Point
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from rest_framework import status
from rest_framework.test import APIClient

from ai_pipeline.orchestrator import run_pipeline
from incidents.models import AICredibilityScore, IncidentCluster
from reports.models import Report, WitnessReport
from users.models import User

# Damascus, Syria — inside the OSRM-routable demo map area.
DAMASCUS_LAT = 33.5138
DAMASCUS_LNG = 36.2765


@override_settings(RATELIMIT_ENABLE=False)
class TestReportFlow(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User(email='reporter@example.com', username='reporter', is_verified=True, otp_verified=True)
        self.user.set_password('Citizen1234!')
        self.user.save()

        login = self.client.post('/api/v1/users/login/', {
            'identifier': 'reporter@example.com',
            'password': 'Citizen1234!',
        }, format='json')
        self.token = login.data['tokens']['access']
        self.headers = {'HTTP_AUTHORIZATION': f'Bearer {self.token}'}

    def test_get_report_types(self):
        response = self.client.get('/api/v1/reports/types/', **self.headers)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 7)

    def _report_payload(self, idempotency_key='report-test-001', **overrides):
        payload = {
            'latitude': DAMASCUS_LAT,
            'longitude': DAMASCUS_LNG,
            'reported_severity': 3,
            'victims_count': 1,
            'description': 'Integration test report',
            'submission_method': 'form',
            'idempotency_key': idempotency_key,
        }
        payload.update(overrides)
        return payload

    def test_create_report_success(self):
        response = self.client.post('/api/v1/reports/', self._report_payload(), format='json', **self.headers)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        report = Report.objects.get(id=response.data['id'])
        self.assertEqual(report.status, 'received')

    def test_create_report_invalid_coords(self):
        response = self.client.post(
            '/api/v1/reports/',
            self._report_payload(idempotency_key='bad-coords', latitude=999, longitude=999),
            format='json', **self.headers,
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_sos_creates_critical_report(self):
        response = self.client.post('/api/v1/reports/sos/', {
            'latitude': DAMASCUS_LAT,
            'longitude': DAMASCUS_LNG,
            'idempotency_key': 'sos-test-001',
        }, format='json', **self.headers)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        report = Report.objects.get(id=response.data['id'])
        self.assertEqual(report.submission_method, 'sos')
        self.assertEqual(report.report_type, 'sos')
        self.assertEqual(report.reported_severity, 5)

    def test_duplicate_idempotency_rejected(self):
        payload = self._report_payload(idempotency_key='dup-key-001')
        first = self.client.post('/api/v1/reports/', payload, format='json', **self.headers)
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)

        second = self.client.post('/api/v1/reports/', payload, format='json', **self.headers)
        self.assertEqual(second.status_code, status.HTTP_409_CONFLICT)

    def test_witness_report_created(self):
        response = self.client.post('/api/v1/reports/witness/', {
            'latitude': DAMASCUS_LAT,
            'longitude': DAMASCUS_LNG,
        }, format='json', **self.headers)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        parent_report = Report.objects.get(id=response.data['id'])
        self.assertTrue(WitnessReport.objects.filter(report=parent_report).exists())

    def test_my_reports_list(self):
        for i in range(3):
            self.client.post(
                '/api/v1/reports/', self._report_payload(idempotency_key=f'my-reports-{i}'),
                format='json', **self.headers,
            )

        response = self.client.get('/api/v1/reports/my/', **self.headers)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 3)

    def test_report_detail_owner_only(self):
        created = self.client.post(
            '/api/v1/reports/', self._report_payload(idempotency_key='owner-only'), format='json', **self.headers,
        )
        report_id = created.data['id']

        other_user = User(email='otheruser@example.com', username='otheruser', is_verified=True, otp_verified=True)
        other_user.set_password('Citizen1234!')
        other_user.save()
        other_login = self.client.post('/api/v1/users/login/', {
            'identifier': 'otheruser@example.com',
            'password': 'Citizen1234!',
        }, format='json')
        other_headers = {'HTTP_AUTHORIZATION': f'Bearer {other_login.data["tokens"]["access"]}'}

        response = self.client.get(f'/api/v1/reports/{report_id}/', **other_headers)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_report_status_endpoint(self):
        created = self.client.post(
            '/api/v1/reports/', self._report_payload(idempotency_key='status-endpoint'), format='json', **self.headers,
        )
        report_id = created.data['id']

        response = self.client.get(f'/api/v1/reports/{report_id}/status/', **self.headers)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'received')

    def test_ai_pipeline_runs(self):
        report = Report.objects.create(
            reporter=self.user, report_type='fire', description='Pipeline test fire',
            reported_severity=3, victims_count=1, status='received',
            latitude=DAMASCUS_LAT, longitude=DAMASCUS_LNG,
            location=Point(DAMASCUS_LNG, DAMASCUS_LAT), submission_method='form',
        )

        result = run_pipeline(str(report.id))
        self.assertNotEqual(result['pipeline_status'], 'failed')

        report.refresh_from_db()
        self.assertIsNotNone(report.cluster)
        self.assertTrue(AICredibilityScore.objects.filter(incident=report.cluster).exists())

    def test_second_report_joins_cluster(self):
        report1 = Report.objects.create(
            reporter=self.user, report_type='fire', description='First report',
            reported_severity=3, victims_count=1, status='received',
            latitude=33.5138, longitude=36.2765,
            location=Point(36.2765, 33.5138), submission_method='form',
        )
        run_pipeline(str(report1.id))

        report2 = Report.objects.create(
            reporter=self.user, report_type='fire', description='Second nearby report',
            reported_severity=3, victims_count=1, status='received',
            latitude=33.5140, longitude=36.2767,
            location=Point(36.2767, 33.5140), submission_method='form',
        )
        run_pipeline(str(report2.id))

        self.assertEqual(IncidentCluster.objects.count(), 1)
        cluster = IncidentCluster.objects.first()
        self.assertEqual(cluster.report_count, 2)

    def test_voice_report_no_whisper(self):
        audio_file = SimpleUploadedFile('test.wav', b'fake-audio-bytes', content_type='audio/wav')
        response = self.client.post(
            '/api/v1/reports/voice/', {'audio': audio_file}, format='multipart', **self.headers,
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'pending_transcription')
        self.assertIsNone(response.data['transcript'])
        self.assertTrue(response.data['audio_url'])
