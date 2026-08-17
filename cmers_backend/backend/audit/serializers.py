from rest_framework import serializers

from .models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = [
            'id', 'actor_email', 'actor_type', 'action', 'resource_type',
            'resource_id', 'note', 'ip_address', 'created_at',
        ]
        read_only_fields = fields
