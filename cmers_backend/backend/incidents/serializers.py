from routing.services import get_osm_link
from rest_framework import serializers

from .models import AICredibilityScore, AISeverityPrediction, IncidentCluster, StatusUpdate
from .services import SEVERITY_STR_TO_INT


class AICredibilityScoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = AICredibilityScore
        fields = ['id', 'score_percent', 'score_level', 'feature_inputs', 'computed_at']
        read_only_fields = fields


class AISeverityPredictionSerializer(serializers.ModelSerializer):
    class Meta:
        model = AISeverityPrediction
        fields = [
            'id', 'predicted_level', 'probability_low', 'probability_medium',
            'probability_high', 'probability_critical', 'computed_at',
        ]
        read_only_fields = fields


class StatusUpdateSerializer(serializers.ModelSerializer):
    updated_by_name = serializers.SerializerMethodField()

    class Meta:
        model = StatusUpdate
        fields = ['id', 'old_status', 'new_status', 'note', 'updated_at', 'updated_by_name']
        read_only_fields = fields

    def get_updated_by_name(self, obj):
        if not obj.updated_by:
            return None
        return obj.updated_by.full_name or obj.updated_by.email


PROBABILITY_FIELD_BY_LEVEL = {
    'low': 'probability_low',
    'moderate': 'probability_medium',
    'high': 'probability_high',
    'critical': 'probability_critical',
}


class IncidentClusterListSerializer(serializers.ModelSerializer):
    osm_link = serializers.SerializerMethodField()
    predicted_severity = serializers.SerializerMethodField()
    predicted_severity_probability = serializers.SerializerMethodField()
    credibility_score = serializers.SerializerMethodField()

    class Meta:
        model = IncidentCluster
        fields = [
            'id', 'center_latitude', 'center_longitude', 'report_count', 'witness_count',
            'status', 'report_type', 'actual_severity', 'predicted_severity',
            'predicted_severity_probability', 'credibility_score',
            'opened_at', 'closed_at', 'updated_at', 'osm_link',
        ]
        read_only_fields = fields

    def get_osm_link(self, obj):
        return get_osm_link(obj.center_latitude, obj.center_longitude)

    def _latest_severity_prediction(self, obj):
        # obj.ai_severity_predictions is prefetched by get_clusters_queryset()/get_cluster_detail()
        # -- .all() reads the prefetch cache instead of issuing a query per row in the list view.
        predictions = list(obj.ai_severity_predictions.all())
        if not predictions:
            return None
        return max(predictions, key=lambda p: p.computed_at)

    def get_predicted_severity(self, obj):
        latest = self._latest_severity_prediction(obj)
        return SEVERITY_STR_TO_INT.get(latest.predicted_level) if latest else None

    def get_predicted_severity_probability(self, obj):
        latest = self._latest_severity_prediction(obj)
        if not latest:
            return None
        field = PROBABILITY_FIELD_BY_LEVEL.get(latest.predicted_level)
        return getattr(latest, field) if field else None

    def get_credibility_score(self, obj):
        # AICredibilityScoreSerializer existed but was never wired to any output before --
        # ai_credibility_scores is prefetched the same way, so this is equally prefetch-safe.
        scores = list(obj.ai_credibility_scores.all())
        if not scores:
            return None
        latest = max(scores, key=lambda s: s.computed_at)
        return AICredibilityScoreSerializer(latest).data


class IncidentClusterDetailSerializer(IncidentClusterListSerializer):
    severity_prediction = serializers.SerializerMethodField()
    latest_assignment = serializers.SerializerMethodField()
    status_updates_count = serializers.SerializerMethodField()

    class Meta(IncidentClusterListSerializer.Meta):
        fields = IncidentClusterListSerializer.Meta.fields + [
            'severity_prediction', 'latest_assignment', 'status_updates_count',
        ]
        read_only_fields = fields

    def get_severity_prediction(self, obj):
        prediction = obj.ai_severity_predictions.order_by('-computed_at').first()
        if not prediction:
            return None
        return AISeverityPredictionSerializer(prediction).data

    def get_latest_assignment(self, obj):
        from dispatch.models import ResourceAssignment

        # NOTE: assignments are created with cluster=cluster directly (ai_pipeline/greedy.py),
        # never via the unused DispatchRequest.request FK -- filtering on request__incident
        # always returned nothing, so this field was silently None even when a unit was
        # actively dispatched.
        assignment = ResourceAssignment.objects.filter(
            cluster=obj
        ).select_related('unit').order_by('-assigned_at').first()
        if not assignment:
            return None
        return {
            'unit_call_sign': assignment.unit.call_sign,
            'status': assignment.status,
            'eta_minutes': assignment.eta_minutes,
        }

    def get_status_updates_count(self, obj):
        return obj.status_updates.count()


class CloseIncidentSerializer(serializers.Serializer):
    actual_severity = serializers.IntegerField()
    note = serializers.CharField(required=False, allow_blank=True, default='')

    def validate_actual_severity(self, value):
        if value not in (1, 2, 3, 4):
            raise serializers.ValidationError('actual_severity must be 1, 2, 3, or 4.')
        return value
