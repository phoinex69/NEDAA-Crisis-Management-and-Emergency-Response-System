from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import AccessToken


def get_token_from_scope(scope):
    """Browsers can't set custom headers on a WebSocket handshake, so accept the JWT
    either as ?token=<access_token> or, for non-browser clients, an Authorization header."""
    query_string = scope.get('query_string', b'').decode()
    token = parse_qs(query_string).get('token', [None])[0]
    if token:
        return token

    headers = dict(scope.get('headers') or [])
    auth_header = headers.get(b'authorization', b'').decode()
    if auth_header.lower().startswith('bearer '):
        return auth_header[7:]
    return None


def decode_token(token):
    if not token:
        return None
    try:
        return AccessToken(token)
    except TokenError:
        return None


@database_sync_to_async
def get_active_official_account(validated_token):
    from resources.models import OfficialAccount

    official_account_id = validated_token.get('official_account_id')
    if not official_account_id:
        return None
    return OfficialAccount.objects.filter(id=official_account_id, is_active=True).first()


@database_sync_to_async
def report_belongs_to_user(report_id, user_id):
    from reports.models import Report

    if not report_id or not user_id:
        return False
    return Report.objects.filter(id=report_id, reporter_id=user_id).exists()
