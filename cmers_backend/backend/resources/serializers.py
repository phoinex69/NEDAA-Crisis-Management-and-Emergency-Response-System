import bcrypt
from rest_framework import serializers

from .models import AccessRole, FieldUnit, OfficialAccount, Organization, UnitType


class OrganizationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Organization
        fields = '__all__'
        read_only_fields = ['id', 'created_at']


class AccessRoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = AccessRole
        fields = '__all__'
        read_only_fields = ['id', 'created_at']


class OfficialAccountSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    role_name = serializers.CharField(source='role.name', read_only=True, default=None)

    class Meta:
        model = OfficialAccount
        fields = [
            'id', 'email', 'organization', 'organization_name', 'role', 'role_name',
            'designation', 'is_active', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']


class CreateOfficialAccountSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=True)
    role = serializers.PrimaryKeyRelatedField(queryset=AccessRole.objects.all(), required=True)
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = OfficialAccount
        fields = ['id', 'email', 'password', 'organization', 'role', 'designation', 'is_active']
        read_only_fields = ['id']

    def validate_email(self, value):
        if OfficialAccount.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('An official account with this email already exists.')
        return value

    def create(self, validated_data):
        password = validated_data.pop('password')
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        return OfficialAccount.objects.create(password_hash=password_hash, **validated_data)


class OfficialLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        account = OfficialAccount.objects.select_related('organization', 'role').filter(
            email__iexact=email, is_active=True
        ).first()
        if not account or not bcrypt.checkpw(password.encode('utf-8'), account.password_hash.encode('utf-8')):
            raise serializers.ValidationError('Invalid email or password.')
        attrs['account'] = account
        return attrs


class UnitTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = UnitType
        fields = ['id', 'name']


class FieldUnitSerializer(serializers.ModelSerializer):
    call_sign = serializers.CharField(required=True)
    unit_type_name = serializers.CharField(source='unit_type.name', read_only=True)
    organization_name = serializers.CharField(source='organization.name', read_only=True)

    class Meta:
        model = FieldUnit
        fields = [
            'id', 'call_sign', 'unit_type', 'unit_type_name', 'organization', 'organization_name',
            'status', 'current_latitude', 'current_longitude', 'last_location_update',
            'capacity', 'assigned_operator', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'current_latitude', 'current_longitude', 'last_location_update',
            'created_at', 'updated_at',
        ]


class UpdateLocationSerializer(serializers.Serializer):
    latitude = serializers.FloatField(min_value=-90, max_value=90)
    longitude = serializers.FloatField(min_value=-180, max_value=180)
