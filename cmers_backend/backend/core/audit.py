from django.utils import timezone


def get_client_ip(request):
    if request is None:
        return None
    forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if forwarded_for:
        return forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')


def write_audit_log(actor_email, actor_type, action, resource_type, resource_id, note=None, ip_address=None):
    print(f'[AUDIT] actor={actor_email} action={action} resource={resource_type}:{resource_id} time={timezone.now().isoformat()}')

    try:
        from audit.models import AuditLog
        AuditLog.objects.create(
            actor_email=actor_email or 'unknown',
            actor_type=actor_type,
            action=action,
            resource_type=resource_type,
            resource_id=str(resource_id),
            note=note or '',
            ip_address=ip_address,
        )
    except Exception as exc:
        print(f'[AUDIT WARNING] Failed to write log: {exc}')
