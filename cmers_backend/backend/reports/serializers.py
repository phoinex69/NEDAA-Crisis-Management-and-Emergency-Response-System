from rest_framework import serializers

from .models import Report, WitnessReport


class ReportCreateSerializer(serializers.ModelSerializer):
    latitude = serializers.FloatField(required=False, allow_null=True, min_value=-90, max_value=90)
    longitude = serializers.FloatField(required=False, allow_null=True, min_value=-180, max_value=180)
    reported_severity = serializers.IntegerField(required=False, min_value=1, max_value=5, default=1)
    victims_count = serializers.IntegerField(required=False, min_value=0, default=0)
    description = serializers.CharField(required=False, allow_blank=True, default='')
    submission_method = serializers.CharField(required=False, allow_blank=True, default='form')
    idempotency_key = serializers.CharField(required=False, allow_blank=True, default='')

    class Meta:
        model = Report
        fields = [
            'report_type',
            'latitude',
            'longitude',
            'reported_severity',
            'victims_count',
            'description',
            'submission_method',
            'idempotency_key',
        ]


class ReportSerializer(serializers.ModelSerializer):
    latitude = serializers.FloatField(read_only=True)
    longitude = serializers.FloatField(read_only=True)

    class Meta:
        model = Report
        fields = [
            'id',
            'report_type',
            'status',
            'latitude',
            'longitude',
            'reported_severity',
            'victims_count',
            'description',
            'submission_method',
            'idempotency_key',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields


class WitnessReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = WitnessReport
        fields = ['id', 'witness_name', 'contact_info', 'statement', 'created_at']
        read_only_fields = fields
