from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User


@override_settings(RATELIMIT_ENABLE=False)
class TestCitizenAuth(TestCase):
    def setUp(self):
        self.client = APIClient()

    def _register_payload(self, email='newcitizen@example.com'):
        return {
            'full_name': 'New Citizen',
            'email': email,
            'password': 'Citizen1234!',
            'password_confirm': 'Citizen1234!',
        }

    def test_register_success(self):
        response = self.client.post('/api/v1/users/register/', self._register_payload(), format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        user = User.objects.filter(email='newcitizen@example.com').first()
        self.assertIsNotNone(user)
        self.assertFalse(user.otp_verified)

    def test_register_duplicate_email(self):
        payload = self._register_payload('duplicate@example.com')
        first = self.client.post('/api/v1/users/register/', payload, format='json')
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)

        second = self.client.post('/api/v1/users/register/', payload, format='json')
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)

    def test_otp_verify_success(self):
        self.client.post('/api/v1/users/register/', self._register_payload('otpuser@example.com'), format='json')
        user = User.objects.get(email='otpuser@example.com')

        response = self.client.post('/api/v1/users/verify-otp/', {
            'identifier': 'otpuser@example.com',
            'otp_code': user.otp_code,
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data['tokens'])

        user.refresh_from_db()
        self.assertTrue(user.otp_verified)

    def test_otp_expired(self):
        self.client.post('/api/v1/users/register/', self._register_payload('expired@example.com'), format='json')
        user = User.objects.get(email='expired@example.com')
        user.otp_expires_at = timezone.now() - timezone.timedelta(hours=1)
        user.save(update_fields=['otp_expires_at'])

        response = self.client.post('/api/v1/users/verify-otp/', {
            'identifier': 'expired@example.com',
            'otp_code': user.otp_code,
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def _create_verified_user(self, email='verified@example.com', password='Citizen1234!'):
        user = User(email=email, username=email.split('@')[0], is_verified=True, otp_verified=True)
        user.set_password(password)
        user.save()
        return user

    def test_login_success(self):
        self._create_verified_user('login@example.com')

        response = self.client.post('/api/v1/users/login/', {
            'identifier': 'login@example.com',
            'password': 'Citizen1234!',
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data['tokens'])

    def test_login_wrong_password(self):
        self._create_verified_user('wrongpass@example.com')

        response = self.client.post('/api/v1/users/login/', {
            'identifier': 'wrongpass@example.com',
            'password': 'NotTheRightPassword!',
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_account_lockout(self):
        self._create_verified_user('lockout@example.com')

        for _ in range(5):
            self.client.post('/api/v1/users/login/', {
                'identifier': 'lockout@example.com',
                'password': 'WrongPassword!',
            }, format='json')

        response = self.client.post('/api/v1/users/login/', {
            'identifier': 'lockout@example.com',
            'password': 'WrongPassword!',
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        error_text = str(response.data).lower()
        self.assertIn('locked', error_text)

    def test_profile_requires_auth(self):
        response = self.client.get('/api/v1/users/profile/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_token_refresh(self):
        self._create_verified_user('refresh@example.com')

        login_response = self.client.post('/api/v1/users/login/', {
            'identifier': 'refresh@example.com',
            'password': 'Citizen1234!',
        }, format='json')
        refresh_token = login_response.data['tokens']['refresh']

        response = self.client.post('/api/v1/users/token/refresh/', {'refresh': refresh_token}, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
