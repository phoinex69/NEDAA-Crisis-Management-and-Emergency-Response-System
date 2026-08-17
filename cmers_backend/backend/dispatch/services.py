from collections import Counter

from django.utils import timezone

from ai_pipeline.greedy import REPORT_TYPE_TO_UNIT_TYPE
from core.audit import get_client_ip, write_audit_log
from notifications.services import notify_report_status_change
from resources.models import FieldUnit
from routing.services import get_eta, get_eta_for_units
from websocket.events import broadcast_dispatch_event, broadcast_incident_updated, broadcast_unit_location

from .models import ResourceAssignment


def get_incident_suggestion(cluster_id):
    return (
        ResourceAssignment.objects.select_related('unit', 'unit__unit_type', 'cluster', 'confirmed_by')
        .prefetch_related('cluster__ai_severity_predictions')
        .filter(cluster_id=cluster_id, status='suggested')
        .order_by('-assigned_at')
        .first()
    )


def confirm_dispatch(assignment, official_account, request=None):
    assignment.status = 'confirmed'
    assignment.confirmed_by = official_account
    assignment.confirmed_at = timezone.now()
    assignment.save(update_fields=['status', 'confirmed_by', 'confirmed_at'])

    unit = assignment.unit
    unit.status = 'busy'
    unit.save(update_fields=['status'])

    # The unit is no longer available, so any other AI suggestion still
    # pointing at it is stale -- cancel those rather than leaving them
    # sitting in the pending queue for an operator to confirm into a unit
    # that's already busy elsewhere.
    ResourceAssignment.objects.filter(unit=unit, status='suggested').exclude(id=assignment.id).update(
        status='cancelled'
    )

    write_audit_log(
        actor_email=official_account.email,
        actor_type='official',
        action='dispatch_confirmed',
        resource_type='assignment',
        resource_id=str(assignment.id),
        ip_address=get_client_ip(request),
    )
    broadcast_dispatch_event(assignment)
    if assignment.cluster:
        broadcast_incident_updated(assignment.cluster)
        for report in assignment.cluster.source_reports.all():
            report.status = 'assigned'
            report.save(update_fields=['status'])
            notify_report_status_change(report)
    return assignment


def override_dispatch(assignment, new_unit, official_account, request=None):
    assignment.status = 'overridden'
    assignment.save(update_fields=['status'])

    eta_minutes = 0
    if assignment.cluster:
        eta_value, _routing_method = get_eta(new_unit, assignment.cluster)
        eta_minutes = int(round(eta_value))

    new_assignment = ResourceAssignment.objects.create(
        cluster=assignment.cluster,
        unit=new_unit,
        status='confirmed',
        confirmed_by=official_account,
        confirmed_at=timezone.now(),
        priority_score=0,
        justification='Manual override by operator',
        eta_minutes=eta_minutes,
    )

    new_unit.status = 'busy'
    new_unit.save(update_fields=['status'])

    # Same cleanup as confirm_dispatch: the newly-dispatched unit is no
    # longer available, so any other pending suggestion for it is stale.
    ResourceAssignment.objects.filter(unit=new_unit, status='suggested').exclude(id=new_assignment.id).update(
        status='cancelled'
    )

    write_audit_log(
        actor_email=official_account.email,
        actor_type='official',
        action='dispatch_overridden',
        resource_type='assignment',
        resource_id=str(new_assignment.id),
        ip_address=get_client_ip(request),
    )
    broadcast_dispatch_event(new_assignment)
    if new_assignment.cluster:
        broadcast_incident_updated(new_assignment.cluster)
        for report in new_assignment.cluster.source_reports.all():
            report.status = 'assigned'
            report.save(update_fields=['status'])
            notify_report_status_change(report)
    return new_assignment


def complete_assignment(assignment):
    assignment.status = 'completed'
    assignment.completed_at = timezone.now()
    assignment.save(update_fields=['status', 'completed_at'])

    unit = assignment.unit
    unit.status = 'available'
    unit.save(update_fields=['status'])

    broadcast_dispatch_event(assignment)
    broadcast_unit_location(unit)
    return assignment


def get_available_units_for_incident(cluster):
    report_type = cluster.report_type
    if not report_type:
        types = list(cluster.source_reports.values_list('report_type', flat=True))
        report_type = Counter(types).most_common(1)[0][0] if types else None

    unit_type_name = REPORT_TYPE_TO_UNIT_TYPE.get(report_type)

    units = FieldUnit.objects.filter(status='available')
    if unit_type_name:
        matching = units.filter(unit_type__name=unit_type_name)
        if matching.exists():
            units = matching

    units = list(units)
    eta_by_unit = get_eta_for_units(units, cluster)

    units.sort(key=lambda u: eta_by_unit.get(u.id, float('inf')))
    for unit in units:
        unit.eta_minutes = eta_by_unit.get(unit.id)

    return units
