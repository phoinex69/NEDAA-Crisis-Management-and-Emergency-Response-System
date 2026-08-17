import uuid

from django.contrib.gis.db import models as gis_models
from django.db import models
from django.utils import timezone

from reports.models import Report
from resources.models import OfficialAccount


class IncidentCluster(models.Model):
    STATUS_CHOICES = [
        ('new', 'New'),
        ('active', 'Active'),
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('closed', 'Closed'),
    ]

    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('moderate', 'Moderate'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200, blank=True, default='')
    description = models.TextField(blank=True, default='')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    report_type = models.CharField(max_length=30, choices=Report.REPORT_TYPE_CHOICES, null=True, blank=True)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='moderate')
    actual_severity = models.IntegerField(null=True, blank=True)
    center_latitude = models.FloatField(null=True, blank=True)
    center_longitude = models.FloatField(null=True, blank=True)
    location = gis_models.PointField(geography=True, srid=4326, blank=True, null=True)
    report_count = models.IntegerField(default=0)
    witness_count = models.IntegerField(default=0)
    source_reports = models.ManyToManyField(Report, related_name='incident_clusters', blank=True)
    opened_at = models.DateTimeField(default=timezone.now)
    closed_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'incidents_incident_cluster'
        ordering = ['-opened_at']

    def __str__(self):
        return self.title or str(self.id)


class AICredibilityScore(models.Model):
    incident = models.ForeignKey(IncidentCluster, on_delete=models.CASCADE, related_name='ai_credibility_scores')
    score_percent = models.FloatField(null=True, blank=True)
    score_level = models.CharField(max_length=20, blank=True, default='')
    feature_inputs = models.JSONField(default=dict, blank=True)
    ai_was_correct = models.BooleanField(null=True, blank=True)
    model_version = models.CharField(max_length=100, blank=True, default='')
    analysis_summary = models.TextField(blank=True, default='')
    computed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'incidents_ai_credibility_score'

    def __str__(self):
        return f'Credibility score for {self.incident_id}: {self.score_percent}'


class AISeverityPrediction(models.Model):
    incident = models.ForeignKey(IncidentCluster, on_delete=models.CASCADE, related_name='ai_severity_predictions')
    predicted_level = models.CharField(max_length=20, blank=True, default='')
    probability_low = models.FloatField(default=0)
    probability_medium = models.FloatField(default=0)
    probability_high = models.FloatField(default=0)
    probability_critical = models.FloatField(default=0)
    confidence = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    model_version = models.CharField(max_length=100, blank=True, default='')
    computed_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'incidents_ai_severity_prediction'

    def __str__(self):
        return f'Prediction for {self.incident_id}: {self.predicted_level}'


class StatusUpdate(models.Model):
    incident = models.ForeignKey(IncidentCluster, on_delete=models.CASCADE, related_name='status_updates')
    old_status = models.CharField(max_length=20, blank=True, default='')
    new_status = models.CharField(max_length=20, default='')
    note = models.TextField(blank=True, default='')
    updated_by = models.ForeignKey(
        OfficialAccount, on_delete=models.SET_NULL, null=True, blank=True, related_name='incident_status_updates'
    )
    updated_at = models.DateTimeField(default=timezone.now)

    class Meta:
        db_table = 'incidents_status_update'
        ordering = ['-updated_at']

    def __str__(self):
        return f'{self.incident} - {self.new_status}'
