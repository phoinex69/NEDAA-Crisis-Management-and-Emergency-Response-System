from rest_framework.permissions import BasePermission


class IsCitizen(BasePermission):
    """Authenticated citizen JWT only — rejects official-account tokens.

    Official tokens authenticate against a shared internal system user, so a bare
    IsAuthenticated check does not distinguish them from citizens; this closes that gap.
    """

    message = 'Citizen authentication required.'

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        return getattr(request, 'official_account', None) is None
