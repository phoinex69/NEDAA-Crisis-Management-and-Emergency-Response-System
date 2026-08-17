
import uuid

from django.contrib.gis.db import models as gis_models
from django.db import models

from users.models import User


class Report(models.Model):
    REPORT_TYPE_CHOICES = [
        ('accident', 'Accident'),
        ('fire', 'Fire'),
        ('medical', 'Medical'),
        ('flood', 'Flood'),
        ('security', 'Security'),
        ('hazmat', 'HazMat'),
        ('weather', 'Weather'),
        ('sos', 'SOS'),
        ('other', 'Other'),
    ]

    STATUS_CHOICES = [
        ('received', 'Received'),
        ('under_review', 'Under Review'),
        ('pending_transcription', 'Pending Transcription'),
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('rejected', 'Rejected'),
        ('closed', 'Closed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reporter = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reports')
    cluster = models.ForeignKey(
        'incidents.IncidentCluster', on_delete=models.SET_NULL, null=True, blank=True, related_name='cluster_reports'
    )
    report_type = models.CharField(max_length=30, choices=REPORT_TYPE_CHOICES, default='other')
    title = models.CharField(max_length=200, blank=True, default='')
    description = models.TextField(blank=True, default='')
    reported_severity = models.IntegerField(default=1)
    victims_count = models.IntegerField(default=0)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='received')
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    location = gis_models.PointField(geography=True, srid=4326, blank=True, null=True)
    address = models.CharField(max_length=255, blank=True, default='')
    source = models.CharField(max_length=50, default='web')
    submission_method = models.CharField(max_length=30, default='form')
    idempotency_key = models.CharField(max_length=120, blank=True, default='')
    is_anonymous = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'reports_report'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title or self.report_type} ({self.status})'


class ReportAttachment(models.Model):
    report = models.ForeignKey(Report, on_delete=models.CASCADE, related_name='attachments')
    file_url = models.URLField(max_length=500)
    caption = models.CharField(max_length=255, blank=True, default='')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reports_attachment'


class VoiceRecord(models.Model):
    report = models.ForeignKey(Report, on_delete=models.CASCADE, related_name='voice_records')
    audio_url = models.URLField(max_length=500)
    transcript = models.TextField(null=True, blank=True)
    duration_seconds = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reports_voice_record'


class WitnessReport(models.Model):
    report = models.ForeignKey(
        Report, on_delete=models.CASCADE, related_name='witness_reports', null=True, blank=True
    )
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='witness_statements'
    )
    cluster = models.ForeignKey(
        'incidents.IncidentCluster', on_delete=models.SET_NULL, null=True, blank=True, related_name='witness_reports'
    )
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    photo_url = models.URLField(max_length=500, null=True, blank=True)
    witness_name = models.CharField(max_length=150, blank=True, default='Anonymous')
    contact_info = models.CharField(max_length=255, blank=True, default='')
    statement = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reports_witness_report'
