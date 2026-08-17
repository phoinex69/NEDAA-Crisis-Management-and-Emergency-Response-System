import logging

from reports.models import Report
from websocket.events import broadcast_incident_updated, broadcast_new_incident

from .credibility import score_credibility
from .dbscan import find_or_create_cluster
from .greedy import suggest_unit
from .severity import predict_severity

logger = logging.getLogger(__name__)


def run_pipeline(report_id):
    try:
        report = Report.objects.get(id=report_id)

        cluster, is_new = find_or_create_cluster(report)
        if is_new:
            broadcast_new_incident(cluster)

        credibility_score = score_credibility(report, cluster)
        band = credibility_score.score_level

        if band == 'red':
            report.status = 'under_review'
            report.save(update_fields=['status'])
            broadcast_incident_updated(cluster)
            return {
                'cluster_id': str(cluster.id),
                'credibility_score_percent': credibility_score.score_percent,
                'credibility_band': band,
                'predicted_severity': None,
                'suggested_unit_call_sign': None,
                'pipeline_status': 'awaiting_operator',
            }

        if band == 'yellow':
            report.status = 'under_review'
            report.save(update_fields=['status'])
            broadcast_incident_updated(cluster)

        severity_prediction = predict_severity(report, cluster, credibility_score.score_percent)

        suggested_unit_call_sign = None
        if band == 'green':
            assignment, _second_unit = suggest_unit(cluster, severity_prediction)
            if assignment:
                suggested_unit_call_sign = assignment.unit.call_sign
            if not is_new:
                # Red/yellow bands already broadcast on merge (above); green merges into an
                # existing cluster were silent, so operators watching the live incidents feed
                # never saw the corroboration count (report_count) grow until a manual refresh.
                broadcast_incident_updated(cluster)

        return {
            'cluster_id': str(cluster.id),
            'credibility_score_percent': credibility_score.score_percent,
            'credibility_band': band,
            'predicted_severity': severity_prediction.predicted_level,
            'suggested_unit_call_sign': suggested_unit_call_sign,
            'pipeline_status': 'completed' if band == 'green' else 'awaiting_operator',
        }
    except Exception as exc:
        logger.exception('AI pipeline failed for report %s', report_id)
        return {
            'pipeline_status': 'failed',
            'error': str(exc),
        }
