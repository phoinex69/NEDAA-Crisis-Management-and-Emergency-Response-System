# Permission classes used in this file: permissions.AllowAny (auth endpoints),
# core.permissions.IsCitizen (+ CanAccessMedicalData on medical profile),
# resources.permissions.IsOfficialAccount + IsAdminOrOperator (operator medical endpoint)

from core.audit import get_client_ip, write_audit_log
from core.permissions import IsCitizen
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from reports.models import Report
from resources.permissions import IsAdminOrOperator, IsOfficialAccount
from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, MedicalProfile, EmergencyContact
from .permissions import ACTIVE_INCIDENT_STATUSES, CanAccessMedicalData
from .serializers import (
    RegisterSerializer, VerifyOTPSerializer, ResendOTPSerializer,
    LoginSerializer, PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer, UserProfileSerializer,
    MedicalProfileSerializer, EmergencyContactSerializer,
)
from .utils import generate_otp, get_otp_expiry


def get_tokens_for_user(user):
    """Generate JWT access and refresh tokens for a user."""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


@method_decorator(ratelimit(key='ip', rate='5/h', method='POST', block=True), name='post')
class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            write_audit_log(
                actor_email=user.email or user.phone or 'unknown',
                actor_type='citizen',
                action='citizen_registered',
                resource_type='user',
                resource_id=str(user.id),
                ip_address=get_client_ip(request),
            )
            return Response({
                'message': 'Registration successful. '
                           'Please verify your OTP to activate your account.',
                'user_id': str(user.id),
                'identifier': user.email or user.phone,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@method_decorator(ratelimit(key='ip', rate='10/h', method='POST', block=True), name='post')
class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            user.otp_verified = True
            user.otp_code = None
            user.otp_expires_at = None
            user.save(update_fields=['otp_verified', 'otp_code', 'otp_expires_at'])
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Account verified successfully.',
                'tokens': tokens,
                'user': UserProfileSerializer(user).data,
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ResendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ResendOTPSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            otp = generate_otp()
            user.otp_code = otp
            user.otp_expires_at = get_otp_expiry()
            user.save(update_fields=['otp_code', 'otp_expires_at'])
            print(f'[DEV] Resent OTP for {user.email or user.phone}: {otp}')
            return Response({
                'message': 'OTP resent successfully.'
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@method_decorator(ratelimit(key='ip', rate='10/h', method='POST', block=True), name='post')
class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            tokens = get_tokens_for_user(user)
            write_audit_log(
                actor_email=user.email or user.phone or 'unknown',
                actor_type='citizen',
                action='citizen_login',
                resource_type='user',
                resource_id=str(user.id),
                ip_address=get_client_ip(request),
            )
            return Response({
                'message': 'Login successful.',
                'tokens': tokens,
                'user': UserProfileSerializer(user).data,
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@method_decorator(ratelimit(key='ip', rate='5/h', method='POST', block=True), name='post')
class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data.get('user')
            if user:
                otp = generate_otp()
                user.otp_code = otp
                user.otp_expires_at = get_otp_expiry()
                user.save(update_fields=['otp_code', 'otp_expires_at'])
                print(f'[DEV] Password reset OTP for {user.email or user.phone}: {otp}')
        return Response({
            'message': 'If this account exists, an OTP has been sent.'
        }, status=status.HTTP_200_OK)


class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            user.set_password(serializer.validated_data['new_password'])
            user.otp_code = None
            user.otp_expires_at = None
            user.save(update_fields=['password', 'otp_code', 'otp_expires_at'])
            return Response({
                'message': 'Password reset successful. Please log in.'
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsCitizen]
    serializer_class = UserProfileSerializer

    def get_object(self):
        return self.request.user


class MedicalProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsCitizen, CanAccessMedicalData]
    serializer_class = MedicalProfileSerializer

    def get_object(self):
        profile, _created = MedicalProfile.objects.get_or_create(
            user=self.request.user
        )
        self.check_object_permissions(self.request, profile)

        if self.request.method == 'GET':
            write_audit_log(
                actor_email=self.request.user.email or self.request.user.phone or 'unknown',
                actor_type='citizen',
                action='medical_card_accessed',
                resource_type='medical_profile',
                resource_id=str(profile.user_id),
                ip_address=get_client_ip(self.request),
            )
        return profile


class OperatorMedicalProfileView(APIView):
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]

    def get(self, request, user_id):
        has_active_incident = Report.objects.filter(
            reporter_id=user_id, status__in=ACTIVE_INCIDENT_STATUSES
        ).exists()
        if not has_active_incident:
            return Response({'detail': 'No active incident for this citizen.'}, status=status.HTTP_403_FORBIDDEN)

        profile, _created = MedicalProfile.objects.get_or_create(user_id=user_id)
        write_audit_log(
            actor_email=request.official_account.email,
            actor_type='official',
            action='medical_card_accessed',
            resource_type='medical_profile',
            resource_id=str(profile.user_id),
            ip_address=get_client_ip(request),
        )
        return Response(MedicalProfileSerializer(profile).data)


class EmergencyContactListView(generics.ListCreateAPIView):
    permission_classes = [IsCitizen]
    serializer_class = EmergencyContactSerializer

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class EmergencyContactDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsCitizen]
    serializer_class = EmergencyContactSerializer

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)
