from django.db.models import Avg
from django.utils import timezone

from core.audit import get_client_ip, write_audit_log
from notifications.services import notify_report_status_change
from websocket.events import broadcast_incident_updated

from .models import IncidentCluster, StatusUpdate

CLUSTER_PREFETCH = ('ai_severity_predictions', 'ai_credibility_scores', 'status_updates', 'source_reports')
SEVERITY_STR_TO_INT = {'low': 1, 'moderate': 2, 'high': 3, 'critical': 4}


def get_clusters_queryset(filters=None):
    filters = filters or {}
    queryset = IncidentCluster.objects.prefetch_related(*CLUSTER_PREFETCH).order_by('-opened_at')

    status_value = filters.get('status')
    if status_value:
        queryset = queryset.filter(status=status_value)

    severity_value = filters.get('severity')
    if severity_value:
        queryset = queryset.filter(actual_severity=severity_value)

    report_type_value = filters.get('report_type')
    if report_type_value:
        queryset = queryset.filter(source_reports__report_type=report_type_value).distinct()

    date_from = filters.get('date_from')
    if date_from:
        queryset = queryset.filter(opened_at__gte=date_from)

    date_to = filters.get('date_to')
    if date_to:
        queryset = queryset.filter(opened_at__lte=date_to)

    # description lives on Report, not IncidentCluster, so a text search has to
    # go through source_reports -- distinct() to avoid duplicate clusters when
    # more than one of their reports matches.
    search = filters.get('search')
    if search:
        queryset = queryset.filter(source_reports__description__icontains=search).distinct()

    return queryset


def get_cluster_detail(cluster_id):
    return IncidentCluster.objects.prefetch_related(*CLUSTER_PREFETCH).filter(pk=cluster_id).first()


def update_cluster_status(cluster, new_status, official_account, note=''):
    old_status = cluster.status
    cluster.status = new_status
    cluster.save(update_fields=['status', 'updated_at'])
    StatusUpdate.objects.create(
        incident=cluster,
        old_status=old_status,
        new_status=new_status,
        updated_by=official_account,
        note=note or '',
    )
    broadcast_incident_updated(cluster)

    for report in cluster.source_reports.all():
        notify_report_status_change(report)

    return cluster


def close_cluster(cluster, actual_severity, official_account, note='', request=None):
    from analytics.models import IncidentReportSummary

    cluster.actual_severity = actual_severity
    cluster.closed_at = timezone.now()
    cluster.save(update_fields=['actual_severity', 'closed_at'])

    update_cluster_status(cluster, 'closed', official_account, note)

    response_time_minutes = None
    if cluster.opened_at and cluster.closed_at:
        response_time_minutes = (cluster.closed_at - cluster.opened_at).total_seconds() / 60

    avg_citizen_severity = cluster.source_reports.aggregate(avg=Avg('reported_severity'))['avg']
    citizen_reported_severity = round(avg_citizen_severity) if avg_citizen_severity is not None else None

    latest_prediction = cluster.ai_severity_predictions.order_by('-computed_at').first()
    ai_predicted_severity = (
        SEVERITY_STR_TO_INT.get(latest_prediction.predicted_level) if latest_prediction else None
    )

    IncidentReportSummary.objects.update_or_create(
        incident=cluster,
        defaults={
            'actual_severity': actual_severity,
            'citizen_reported_severity': citizen_reported_severity,
            'ai_predicted_severity': ai_predicted_severity,
            'response_time_minutes': response_time_minutes,
            'total_reports': cluster.report_count,
            'total_witnesses': cluster.witness_count,
        },
    )
    write_audit_log(
        actor_email=official_account.email,
        actor_type='official',
        action='incident_closed',
        resource_type='cluster',
        resource_id=str(cluster.id),
        note=note or '',
        ip_address=get_client_ip(request),
    )
    broadcast_incident_updated(cluster)
    return cluster
