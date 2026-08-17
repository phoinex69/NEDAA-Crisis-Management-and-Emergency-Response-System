from django.db import models


class CrisisSummary(models.Model):
    date = models.DateField()
    region = models.CharField(max_length=120, default='all')
    total_reports = models.IntegerField(default=0)
    open_incidents = models.IntegerField(default=0)
    resolved_incidents = models.IntegerField(default=0)
    avg_severity = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    generated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'analytics_crisis_summary'
        ordering = ['-date']

    def __str__(self):
        return f'{self.region} summary for {self.date}'


class ResponseMetric(models.Model):
    summary = models.ForeignKey(CrisisSummary, on_delete=models.CASCADE, related_name='metrics')
    metric_name = models.CharField(max_length=80)
    metric_value = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'analytics_response_metric'

    def __str__(self):
        return f'{self.metric_name} = {self.metric_value}'


class IncidentReportSummary(models.Model):
    incident = models.OneToOneField('incidents.IncidentCluster', on_delete=models.CASCADE, related_name='report_summary')
    citizen_reported_severity = models.IntegerField(null=True, blank=True)
    ai_predicted_severity = models.IntegerField(null=True, blank=True)
    actual_severity = models.IntegerField(null=True, blank=True)
    response_time_minutes = models.FloatField(null=True, blank=True)
    citizen_rating = models.IntegerField(null=True, blank=True)
    total_reports = models.IntegerField(default=0)
    total_witnesses = models.IntegerField(default=0)
    false_report = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'analytics_incident_report_summary'

    def __str__(self):
        return f'Summary for {self.incident_id}'
