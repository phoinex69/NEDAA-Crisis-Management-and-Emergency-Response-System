from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, username=None, **extra_fields):
        if not email:
            raise ValueError('The email field must be set.')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username or email.split('@')[0], **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, username=None, **extra_fields):
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_superuser', False)
        return self._create_user(email, password, username=username, **extra_fields)

    def create_superuser(self, email, password=None, username=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if not extra_fields.get('is_staff'):
            raise ValueError('Superuser must have is_staff=True.')
        if not extra_fields.get('is_superuser'):
            raise ValueError('Superuser must have is_superuser=True.')

        return self._create_user(email, password, username=username, **extra_fields)


class User(AbstractUser):
    ROLE_CHOICES = [
        ('administrator', 'Administrator'),
        ('emergency_manager', 'Emergency Manager'),
        ('dispatch_officer', 'Dispatch Officer'),
        ('field_responder', 'Field Responder'),
        ('medical_staff', 'Medical Staff'),
        ('volunteer', 'Volunteer'),
        ('civilian', 'Civilian'),
    ]

    email = models.EmailField(unique=True, blank=True, null=True)
    phone = models.CharField(max_length=30, unique=True, blank=True, null=True)
    full_name = models.CharField(max_length=150, blank=True, default='')
    preferred_language = models.CharField(max_length=20, default='en')
    phone_number = models.CharField(max_length=30, blank=True, default='')
    role = models.CharField(max_length=30, choices=ROLE_CHOICES, default='civilian')
    is_verified = models.BooleanField(default=False)
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    otp_expires_at = models.DateTimeField(blank=True, null=True)
    otp_verified = models.BooleanField(default=False)
    failed_login_attempts = models.IntegerField(default=0)
    locked_until = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'users_user'

    def __str__(self):
        return self.full_name or self.email or self.phone or self.username


class MedicalProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='medical_profile')
    blood_type = models.CharField(max_length=10, blank=True, default='')
    allergies = models.TextField(blank=True, default='')
    chronic_conditions = models.TextField(blank=True, default='')
    medications = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users_medical_profile'

    def __str__(self):
        return f'{self.user} medical profile'


class EmergencyContact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='emergency_contacts')
    name = models.CharField(max_length=150)
    relationship = models.CharField(max_length=80)
    phone_number = models.CharField(max_length=30)
    email = models.EmailField(blank=True, default='')
    address = models.CharField(max_length=255, blank=True, default='')
    is_primary = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'users_emergency_contact'
        ordering = ['-is_primary', 'name']

    def __str__(self):
        return f'{self.name} ({self.relationship})'
