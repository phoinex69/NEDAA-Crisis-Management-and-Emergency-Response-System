from rest_framework import serializers
from .models import User, MedicalProfile, EmergencyContact
from .utils import (generate_otp, get_otp_expiry, is_otp_valid,
                    is_account_locked, lock_account, reset_login_attempts)


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['full_name', 'email', 'phone', 'password',
                  'password_confirm', 'preferred_language']

    def validate(self, data):
        if not data.get('email') and not data.get('phone'):
            raise serializers.ValidationError(
                'At least one of email or phone is required.'
            )
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError('Passwords do not match.')
        if data.get('email') and User.objects.filter(email=data['email']).exists():
            raise serializers.ValidationError('Email already registered.')
        if data.get('phone') and User.objects.filter(phone=data['phone']).exists():
            raise serializers.ValidationError('Phone already registered.')
        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        otp = generate_otp()

        base_username = (validated_data.get('email') or '').split('@')[0] or validated_data.get('phone') or 'user'
        username = base_username
        suffix = 1
        while User.objects.filter(username=username).exists():
            suffix += 1
            username = f'{base_username}{suffix}'

        user = User(username=username, **validated_data)
        user.set_password(password)
        user.otp_code = otp
        user.otp_expires_at = get_otp_expiry()
        user.otp_verified = False
        user.save()
        print(f'[DEV] OTP for {user.email or user.phone}: {otp}')
        return user


class VerifyOTPSerializer(serializers.Serializer):
    identifier = serializers.CharField()
    otp_code = serializers.CharField(max_length=6, min_length=6)

    def validate(self, data):
        identifier = data['identifier']
        user = (User.objects.filter(email=identifier).first() or
                User.objects.filter(phone=identifier).first())
        if not user:
            raise serializers.ValidationError('User not found.')
        if user.otp_verified:
            raise serializers.ValidationError('Account already verified.')
        if not is_otp_valid(user):
            raise serializers.ValidationError(
                'OTP has expired. Please request a new one.'
            )
        if user.otp_code != data['otp_code']:
            raise serializers.ValidationError('Invalid OTP code.')
        data['user'] = user
        return data


class ResendOTPSerializer(serializers.Serializer):
    identifier = serializers.CharField()

    def validate(self, data):
        identifier = data['identifier']
        user = (User.objects.filter(email=identifier).first() or
                User.objects.filter(phone=identifier).first())
        if not user:
            raise serializers.ValidationError('User not found.')
        if user.otp_verified:
            raise serializers.ValidationError('Account already verified.')
        data['user'] = user
        return data


class LoginSerializer(serializers.Serializer):
    identifier = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        identifier = data['identifier']
        password = data['password']

        user = (User.objects.filter(email=identifier).first() or
                User.objects.filter(phone=identifier).first())

        if not user:
            raise serializers.ValidationError('Invalid credentials.')

        if is_account_locked(user):
            raise serializers.ValidationError(
                'Account is temporarily locked due to too many failed attempts. '
                'Try again in 15 minutes.'
            )

        if not user.check_password(password):
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= 5:
                lock_account(user)
                raise serializers.ValidationError(
                    'Too many failed attempts. Account locked for 15 minutes.'
                )
            user.save(update_fields=['failed_login_attempts'])
            raise serializers.ValidationError('Invalid credentials.')

        if not user.otp_verified:
            raise serializers.ValidationError(
                'Account not verified. Please verify your OTP first.'
            )

        if not user.is_active:
            raise serializers.ValidationError('Account is deactivated.')

        reset_login_attempts(user)
        data['user'] = user
        return data


class PasswordResetRequestSerializer(serializers.Serializer):
    identifier = serializers.CharField()

    def validate(self, data):
        identifier = data['identifier']
        user = (User.objects.filter(email=identifier).first() or
                User.objects.filter(phone=identifier).first())
        if not user:
            data['user'] = None
            return data
        data['user'] = user
        return data


class PasswordResetConfirmSerializer(serializers.Serializer):
    identifier = serializers.CharField()
    otp_code = serializers.CharField(max_length=6, min_length=6)
    new_password = serializers.CharField(min_length=8, write_only=True)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['new_password'] != data['new_password_confirm']:
            raise serializers.ValidationError('Passwords do not match.')

        identifier = data['identifier']
        user = (User.objects.filter(email=identifier).first() or
                User.objects.filter(phone=identifier).first())

        if not user:
            raise serializers.ValidationError('User not found.')
        if not is_otp_valid(user):
            raise serializers.ValidationError('OTP has expired.')
        if user.otp_code != data['otp_code']:
            raise serializers.ValidationError('Invalid OTP code.')

        data['user'] = user
        return data


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'full_name', 'email', 'phone',
                  'preferred_language', 'otp_verified', 'created_at']
        read_only_fields = ['id', 'otp_verified', 'created_at']


class MedicalProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicalProfile
        fields = ['id', 'blood_type', 'allergies',
                  'chronic_conditions', 'medications']
        read_only_fields = ['id']


class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = ['id', 'name', 'phone_number']
        read_only_fields = ['id']
