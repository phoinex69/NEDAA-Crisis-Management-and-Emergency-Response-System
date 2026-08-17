import statistics
import time

import bcrypt
import requests
from django.core.management.base import BaseCommand

BASE_URL = 'http://localhost:8000'
TARGET_MS = 3000
REQUESTS_PER_ENDPOINT = 5


class Command(BaseCommand):
    help = 'Measures API and AI pipeline response times against the < 3000ms NFR target.'

    def handle(self, *args, **options):
        citizen_email, citizen_password = self._create_test_citizen()
        official_email, official_password = self._create_test_official()

        try:
            login_times, citizen_token = self._time_login(citizen_email, citizen_password)
            citizen_headers = {'Authorization': f'Bearer {citizen_token}'}

            report_types_times = self._time_endpoint('GET', '/api/v1/reports/types/', headers=citizen_headers)

            official_token = self._login_official(official_email, official_password)
            official_headers = {'Authorization': f'Bearer {official_token}'}

            incidents_times = self._time_endpoint('GET', '/api/v1/incidents/', headers=official_headers)
            stats_times = self._time_endpoint('GET', '/api/v1/analytics/stats/', headers=official_headers)
            heatmap_times = self._time_endpoint('GET', '/api/v1/analytics/heatmap/', headers=official_headers)

            pipeline_times = self._time_ai_pipeline(citizen_email)

            self._print_report({
                'Login': login_times,
                'Report types': report_types_times,
                'Incidents list': incidents_times,
                'Analytics stats': stats_times,
                'Heatmap': heatmap_times,
                'AI Pipeline': pipeline_times,
            })
        finally:
            self._cleanup(citizen_email, official_email)

    # ------------------------------------------------------------------
    def _create_test_citizen(self):
        from users.models import User

        email = 'perftest_citizen@example.com'
        password = 'PerfTest1234!'
        User.objects.filter(email=email).delete()
        user = User(email=email, username='perftest_citizen', is_verified=True, otp_verified=True)
        user.set_password(password)
        user.save()
        return email, password

    def _create_test_official(self):
        from resources.models import AccessRole, OfficialAccount, Organization

        email = 'perftest_official@example.com'
        password = 'PerfTest1234!'
        OfficialAccount.objects.filter(email=email).delete()
        org, _ = Organization.objects.get_or_create(
            name='Perf Test Org', defaults={'organization_type': 'government'}
        )
        role, _ = AccessRole.objects.get_or_create(name='admin', defaults={'permissions': {'all': True}})
        OfficialAccount.objects.create(
            email=email, password_hash=bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
            full_name='Perf Test Official', organization=org, role=role, is_active=True,
        )
        return email, password

    def _cleanup(self, citizen_email, official_email):
        from resources.models import OfficialAccount
        from users.models import User

        User.objects.filter(email=citizen_email).delete()
        OfficialAccount.objects.filter(email=official_email).delete()

    # ------------------------------------------------------------------
    def _time_endpoint(self, method, path, headers=None, json=None, count=REQUESTS_PER_ENDPOINT):
        times = []
        for _ in range(count):
            start = time.monotonic()
            requests.request(method, f'{BASE_URL}{path}', headers=headers, json=json, timeout=10)
            times.append((time.monotonic() - start) * 1000)
        return times

    def _time_login(self, email, password, count=REQUESTS_PER_ENDPOINT):
        times = []
        last_response = None
        for _ in range(count):
            start = time.monotonic()
            last_response = requests.post(
                f'{BASE_URL}/api/v1/users/login/',
                json={'identifier': email, 'password': password}, timeout=10,
            )
            times.append((time.monotonic() - start) * 1000)
        token = last_response.json()['tokens']['access']
        return times, token

    def _login_official(self, email, password):
        response = requests.post(
            f'{BASE_URL}/api/v1/resources/auth/login/',
            json={'email': email, 'password': password}, timeout=10,
        )
        return response.json()['tokens']['access']

    def _time_ai_pipeline(self, citizen_email, count=REQUESTS_PER_ENDPOINT):
        from ai_pipeline.orchestrator import run_pipeline
        from reports.models import Report
        from users.models import User

        user = User.objects.get(email=citizen_email)
        report = Report.objects.create(
            reporter=user, report_type='fire', description='Performance test report',
            reported_severity=3, victims_count=1, status='received',
            latitude=33.5138, longitude=36.2765, submission_method='form',
        )

        times = []
        for _ in range(count):
            start = time.monotonic()
            run_pipeline(str(report.id))
            times.append((time.monotonic() - start) * 1000)
        return times

    # ------------------------------------------------------------------
    def _print_report(self, results):
        self.stdout.write('')
        self.stdout.write('=== PERFORMANCE REPORT ===')
        self.stdout.write(f'NFR target: < {TARGET_MS}ms average')
        self.stdout.write('')

        labels = {
            'Login': 'Login:          ',
            'Report types': 'Report types:   ',
            'Incidents list': 'Incidents list: ',
            'Analytics stats': 'Analytics stats:',
            'Heatmap': 'Heatmap:        ',
            'AI Pipeline': 'AI Pipeline:    ',
        }

        failures = 0
        for key, times in results.items():
            avg = statistics.mean(times)
            passed = avg < TARGET_MS
            if not passed:
                failures += 1
            verdict = 'PASS' if passed else 'FAIL'
            self.stdout.write(
                f'{labels[key]} avg {avg:.1f}ms (min {min(times):.1f}ms, max {max(times):.1f}ms)  [{verdict}]'
            )

        self.stdout.write('')
        if failures == 0:
            self.stdout.write('Overall: ALL PASS')
        else:
            self.stdout.write(f'Overall: {failures} FAILURES')
        self.stdout.write('===========================')
