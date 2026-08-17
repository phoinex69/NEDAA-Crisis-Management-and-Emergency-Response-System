from datetime import timedelta

from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.utils import timezone
from routing.services import get_osm_link

from websocket.events import broadcast_citizen_report_update, broadcast_danger_zone

from .models import Notification


def notify_citizen(user, type, title, message, report=None):
    notification = Notification.objects.create(
        recipient=user,
        notification_type=type,
        title=title,
        message=message,
        is_broadcast=False,
    )

    if report is not None:
        broadcast_citizen_report_update(report)

    email = getattr(user, 'email', None) or getattr(user, 'phone', None) or 'unknown'
    print(f'[NOTIFY] user={email} type={type} msg={message}')
    return notification


def broadcast_alert(type, title, message, latitude, longitude, radius_km, created_by):
    from reports.models import Report

    Notification.objects.create(
        recipient=None,
        notification_type=type,
        title=title,
        message=message,
        is_broadcast=True,
        target_latitude=latitude,
        target_longitude=longitude,
        target_radius_km=radius_km,
    )

    count = 0
    if latitude is not None and longitude is not None:
        since = timezone.now() - timedelta(hours=24)
        point = Point(longitude, latitude)
        citizen_ids = (
            Report.objects.filter(
                created_at__gte=since,
                reporter__isnull=False,
                location__dwithin=(point, D(km=radius_km)),
            )
            .order_by()
            .values_list('reporter_id', flat=True)
            .distinct()
        )

        for user_id in citizen_ids:
            Notification.objects.create(
                recipient_id=user_id,
                notification_type=type,
                title=title,
                message=message,
                is_broadcast=False,
            )
            count += 1

    broadcast_danger_zone(title, message, latitude, longitude, radius_km)

    print(f'[BROADCAST] type={type} sent to {count} citizens within {radius_km}km of {latitude},{longitude}')
    return count


def notify_report_status_change(report):
    if not report.reporter_id:
        return None

    message = f'Your report status changed to {report.get_status_display()}'

    from dispatch.models import ResourceAssignment

    if report.cluster_id:
        assignment = (
            ResourceAssignment.objects.filter(cluster_id=report.cluster_id, status__in=['confirmed', 'dispatched'])
            .select_related('unit')
            .order_by('-assigned_at')
            .first()
        )
        if assignment:
            message += f'. Unit {assignment.unit.call_sign} ETA {assignment.eta_minutes} minutes.'

    return notify_citizen(
        user=report.reporter,
        type='report_status',
        title='Report Update',
        message=message,
        report=report,
    )


def notify_sos_contacts(report):
    from users.models import EmergencyContact

    reporter = report.reporter
    contacts = EmergencyContact.objects.filter(user=reporter) if reporter else EmergencyContact.objects.none()

    reporter_name = (reporter.full_name or reporter.email or reporter.phone) if reporter else 'Unknown'
    osm_link = get_osm_link(report.latitude, report.longitude)
    sos_message = f'{reporter_name} triggered an SOS alert. Location: {osm_link}'

    for contact in contacts:
        print(f'[SOS CONTACT] name={contact.name} phone={contact.phone_number} message={sos_message}')

    if reporter:
        notify_citizen(
            user=reporter,
            type='sos_confirm',
            title='SOS Alert Sent',
            message='Your SOS has been received. Emergency contacts notified.',
        )
