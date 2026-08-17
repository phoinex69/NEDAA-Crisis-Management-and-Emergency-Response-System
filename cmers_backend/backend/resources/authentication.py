from django.contrib.auth import get_user_model
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.tokens import RefreshToken

from .models import OfficialAccount

SYSTEM_USER_EMAIL = 'system@cmers.internal'


def _get_system_user():
    User = get_user_model()
    try:
        return User.objects.get(email=SYSTEM_USER_EMAIL)
    except User.DoesNotExist:
        user = User(email=SYSTEM_USER_EMAIL, username='system-internal', is_active=True)
        user.set_unusable_password()
        user.save()
        return user


def get_official_tokens(account):
    """Issue a JWT pair for an OfficialAccount, keyed to the internal system user."""
    system_user = _get_system_user()
    refresh = RefreshToken.for_user(system_user)
    refresh['official_account_id'] = account.id
    refresh['email'] = account.email
    refresh['role'] = account.role.name if account.role_id else None
    refresh['organization'] = account.organization.name if account.organization_id else None
    return {'access': str(refresh.access_token), 'refresh': str(refresh)}


class OfficialJWTAuthentication(JWTAuthentication):
    """JWTAuthentication that additionally resolves an official_account_id claim onto request.official_account."""

    def authenticate(self, request):
        result = super().authenticate(request)
        if result is None:
            return None

        user, validated_token = result
        official_account_id = validated_token.get('official_account_id')
        request.official_account = None
        if official_account_id:
            request.official_account = OfficialAccount.objects.select_related('organization', 'role').filter(
                id=official_account_id, is_active=True
            ).first()
        return user, validated_token
