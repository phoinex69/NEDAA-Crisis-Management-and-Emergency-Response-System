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
    from users.models import User

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

    # There's no live citizen-location tracking in this system (the app only
    # ever sends a location alongside a report submission) -- targeting by
    # "reported near here in the last 24h" silently notifies nobody the
    # moment report history is thin (e.g. right after a data reset, or for
    # an area nobody has reported from yet), even though citizens actually
    # near the danger zone are on the app right now. Broadcasting to every
    # verified citizen is the safe default for an emergency alert.
    # Not filtered by is_verified/otp_verified -- an emergency broadcast
    # (danger zone, road closure, weather) is a safety message, not a
    # trust-gated feature, and is_verified in particular is never actually
    # set by the normal registration/OTP flow, so filtering on it would
    # silently exclude every real citizen account.
    citizen_ids = User.objects.values_list('id', flat=True)

    count = 0
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

    print(f'[BROADCAST] type={type} sent to {count} citizens')
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
