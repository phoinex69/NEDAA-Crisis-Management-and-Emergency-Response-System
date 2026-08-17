from .audit import get_client_ip


def user_or_ip_key(group, request):
    user = getattr(request, 'user', None)
    if user and getattr(user, 'is_authenticated', False):
        return str(user.pk)
    return get_client_ip(request) or 'unknown'


def official_account_key(group, request):
    official_account = getattr(request, 'official_account', None)
    if official_account:
        return str(official_account.id)
    return get_client_ip(request) or 'unknown'
