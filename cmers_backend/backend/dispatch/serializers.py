from incidents.services import SEVERITY_STR_TO_INT
from routing.services import get_osm_link
from rest_framework import serializers

from resources.models import FieldUnit

from .models import ResourceAssignment


class ResourceAssignmentListSerializer(serializers.ModelSerializer):
    cluster_id = serializers.UUIDField(source='cluster.id', read_only=True, default=None)
    unit_call_sign = serializers.CharField(source='unit.call_sign', read_only=True)
    unit_type_name = serializers.CharField(source='unit.unit_type.name', read_only=True)
    cluster_report_type = serializers.CharField(source='cluster.report_type', read_only=True, default=None)
    cluster_predicted_severity = serializers.SerializerMethodField()
    confirmed_by = serializers.SerializerMethodField()

    class Meta:
        model = ResourceAssignment
        fields = [
            'id', 'cluster_id', 'unit_call_sign', 'unit_type_name', 'priority_score',
            'eta_minutes', 'justification', 'status', 'assigned_at',
            'cluster_report_type', 'cluster_predicted_severity',
            'confirmed_by', 'confirmed_at', 'completed_at',
        ]
        read_only_fields = fields

    def get_cluster_predicted_severity(self, obj):
        if not obj.cluster:
            return None
        # cluster__ai_severity_predictions is prefetched by AssignmentListView /
        # AssignmentDetailView -- .all() reads the prefetch cache instead of
        # issuing a query per row.
        predictions = list(obj.cluster.ai_severity_predictions.all())
        if not predictions:
            return None
        latest = max(predictions, key=lambda p: p.computed_at)
        return SEVERITY_STR_TO_INT.get(latest.predicted_level)

    def get_confirmed_by(self, obj):
        if not obj.confirmed_by:
            return None
        return {'full_name': obj.confirmed_by.full_name or obj.confirmed_by.email}


class ResourceAssignmentDetailSerializer(ResourceAssignmentListSerializer):
    cluster = serializers.SerializerMethodField()
    unit = serializers.SerializerMethodField()

    class Meta(ResourceAssignmentListSerializer.Meta):
        fields = ResourceAssignmentListSerializer.Meta.fields + ['cluster', 'unit']
        read_only_fields = fields

    def get_cluster(self, obj):
        cluster = obj.cluster
        if not cluster:
            return None
        return {
            'id': str(cluster.id),
            'status': cluster.status,
            'report_count': cluster.report_count,
            'center_latitude': cluster.center_latitude,
            'center_longitude': cluster.center_longitude,
            'osm_link': get_osm_link(cluster.center_latitude, cluster.center_longitude),
        }

    def get_unit(self, obj):
        unit = obj.unit
        return {
            'call_sign': unit.call_sign,
            'unit_type_name': unit.unit_type.name,
            'organization_name': unit.organization.name,
            'current_latitude': unit.current_latitude,
            'current_longitude': unit.current_longitude,
        }


class ConfirmAssignmentSerializer(serializers.Serializer):
    def validate(self, attrs):
        assignment = self.context.get('assignment')
        if assignment.status != 'suggested':
            raise serializers.ValidationError(f'Assignment is already {assignment.status}.')
        return attrs


class OverrideAssignmentSerializer(serializers.Serializer):
    unit_id = serializers.PrimaryKeyRelatedField(queryset=FieldUnit.objects.all(), required=True)

    def validate_unit_id(self, unit):
        if unit.status != 'available':
            raise serializers.ValidationError('Selected unit is not available.')
        assignment = self.context.get('assignment')
        if assignment and assignment.unit_id == unit.id:
            raise serializers.ValidationError('Selected unit is already the suggested unit.')
        return unit

    def validate(self, attrs):
        attrs['unit'] = attrs['unit_id']
        return attrs
