from datetime import datetime, time, timedelta

from django.utils import timezone
from rest_framework import serializers

from .models import IncidentReportSummary


class IncidentReportSummarySerializer(serializers.ModelSerializer):
    cluster_id = serializers.UUIDField(source='incident.id', read_only=True)
    closed_at = serializers.DateTimeField(source='incident.closed_at', read_only=True)

    class Meta:
        model = IncidentReportSummary
        fields = [
            'id', 'cluster_id', 'citizen_reported_severity', 'ai_predicted_severity',
            'actual_severity', 'response_time_minutes', 'citizen_rating',
            'total_reports', 'total_witnesses', 'false_report', 'closed_at',
        ]
        read_only_fields = fields


class DateRangeSerializer(serializers.Serializer):
    date_from = serializers.DateField(required=False)
    date_to = serializers.DateField(required=False)

    def validate(self, attrs):
        today = timezone.localdate()
        date_from = attrs.get('date_from') or (today - timedelta(days=30))
        date_to = attrs.get('date_to') or today

        if date_from > date_to:
            raise serializers.ValidationError('date_from must not be after date_to.')

        attrs['date_from'] = timezone.make_aware(datetime.combine(date_from, time.min))
        attrs['date_to'] = timezone.make_aware(datetime.combine(date_to, time.max))
        return attrs
