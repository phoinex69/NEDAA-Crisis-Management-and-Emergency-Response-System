from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from routing.services import get_osm_link


def _send(group_name, handler_name, payload_type, data):
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return
    async_to_sync(channel_layer.group_send)(
        group_name,
        {'type': handler_name, 'payload': {'type': payload_type, 'data': data}},
    )


def broadcast_new_incident(cluster):
    data = {
        'id': str(cluster.id),
        'center_latitude': cluster.center_latitude,
        'center_longitude': cluster.center_longitude,
        'report_count': cluster.report_count,
        'witness_count': cluster.witness_count,
        'status': cluster.status,
        'report_type': cluster.report_type,
        'opened_at': cluster.opened_at.isoformat() if cluster.opened_at else None,
        'osm_link': get_osm_link(cluster.center_latitude, cluster.center_longitude),
    }
    _send('incidents_feed', 'incident_new', 'incident.new', data)


def broadcast_incident_updated(cluster):
    data = {
        'id': str(cluster.id),
        'status': cluster.status,
        'report_count': cluster.report_count,
        'updated_at': cluster.updated_at.isoformat() if cluster.updated_at else None,
    }
    _send('incidents_feed', 'incident_updated', 'incident.updated', data)


def broadcast_unit_location(unit):
    data = {
        'id': str(unit.id),
        'call_sign': unit.call_sign,
        'status': unit.status,
        'latitude': unit.current_latitude,
        'longitude': unit.current_longitude,
        'updated_at': unit.last_location_update.isoformat() if unit.last_location_update else None,
    }
    _send('units_feed', 'unit_location_updated', 'unit.location_updated', data)


def broadcast_dispatch_event(assignment):
    data = {
        'cluster_id': str(assignment.cluster_id) if assignment.cluster_id else None,
        'assignment_id': str(assignment.id),
        'unit_call_sign': assignment.unit.call_sign,
        'status': assignment.status,
        'eta_minutes': assignment.eta_minutes,
        'confirmed_at': assignment.confirmed_at.isoformat() if assignment.confirmed_at else None,
    }
    _send('incidents_feed', 'dispatch_updated', 'dispatch.updated', data)


def broadcast_citizen_report_update(report):
    from dispatch.models import ResourceAssignment

    assigned_unit = None
    eta_minutes = None
    if report.cluster_id:
        assignment = (
            ResourceAssignment.objects.filter(cluster_id=report.cluster_id, status__in=['confirmed', 'dispatched'])
            .select_related('unit')
            .order_by('-assigned_at')
            .first()
        )
        if assignment:
            assigned_unit = assignment.unit.call_sign
            eta_minutes = assignment.eta_minutes

    data = {
        'report_id': str(report.id),
        'status': report.status,
        'status_display': report.get_status_display(),
        'updated_at': report.updated_at.isoformat() if report.updated_at else None,
        'eta_minutes': eta_minutes,
        'assigned_unit': assigned_unit,
    }
    _send(f'report_{report.id}', 'report_status_updated', 'report.status_updated', data)


def broadcast_danger_zone(title, message, latitude, longitude, radius_km):
    data = {
        'title': title,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radius_km,
    }
    _send('incidents_feed', 'alert_danger_zone', 'alert.danger_zone', data)
