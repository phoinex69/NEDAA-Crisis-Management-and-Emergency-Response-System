from django.contrib.gis.db import models as gis_models
from django.db import models

from users.models import User


class Organization(models.Model):
    ORG_TYPE_CHOICES = [
        ('fire_service', 'Fire Service'),
        ('police', 'Police'),
        ('medical', 'Medical'),
        ('government', 'Government'),
        ('ngo', 'NGO'),
        ('private', 'Private'),
    ]

    name = models.CharField(max_length=200)
    organization_type = models.CharField(max_length=30, choices=ORG_TYPE_CHOICES, default='government')
    contact_phone = models.CharField(max_length=30, blank=True, default='')
    email = models.EmailField(blank=True, default='')
    address = models.CharField(max_length=255, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'resources_organization'

    def __str__(self):
        return self.name


class UnitType(models.Model):
    name = models.CharField(max_length=80, unique=True)
    description = models.TextField(blank=True, default='')

    class Meta:
        db_table = 'resources_unit_type'

    def __str__(self):
        return self.name


class AccessRole(models.Model):
    name = models.CharField(max_length=50, unique=True)
    permissions = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'resources_access_role'

    def __str__(self):
        return self.name


class OfficialAccount(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='official_accounts')
    role = models.ForeignKey(AccessRole, on_delete=models.PROTECT, related_name='official_accounts', null=True, blank=True)
    email = models.EmailField(unique=True, default='')
    password_hash = models.CharField(max_length=128, default='')
    full_name = models.CharField(max_length=150, blank=True, default='')
    designation = models.CharField(max_length=120, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'resources_official_account'

    def __str__(self):
        return f'{self.email} @ {self.organization}'


class FieldUnit(models.Model):
    UNIT_STATUS_CHOICES = [
        ('available', 'Available'),
        ('busy', 'Busy'),
        ('out_of_service', 'Out of Service'),
    ]

    call_sign = models.CharField(max_length=80, unique=True, default='')
    unit_type = models.ForeignKey(UnitType, on_delete=models.PROTECT, related_name='field_units')
    organization = models.ForeignKey(Organization, on_delete=models.PROTECT, related_name='field_units')
    status = models.CharField(max_length=20, choices=UNIT_STATUS_CHOICES, default='available')
    current_location = gis_models.PointField(geography=True, srid=4326, blank=True, null=True)
    current_latitude = models.FloatField(null=True, blank=True)
    current_longitude = models.FloatField(null=True, blank=True)
    last_location_update = models.DateTimeField(null=True, blank=True)
    capacity = models.IntegerField(default=0)
    assigned_operator = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_units')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'resources_field_unit'

    def __str__(self):
        return self.call_sign


class ResourceInventory(models.Model):
    unit = models.ForeignKey(FieldUnit, on_delete=models.CASCADE, related_name='inventory_items')
    item_name = models.CharField(max_length=150)
    quantity = models.IntegerField(default=0)
    category = models.CharField(max_length=80, blank=True, default='')
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'resources_inventory'

    def __str__(self):
        return f'{self.item_name} ({self.unit})'
