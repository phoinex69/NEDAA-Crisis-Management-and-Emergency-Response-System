from rest_framework.permissions import SAFE_METHODS, BasePermission


class IsOfficialAccount(BasePermission):
    message = 'Official account authentication required.'

    def has_permission(self, request, view):
        return getattr(request, 'official_account', None) is not None


class IsAdmin(BasePermission):
    message = 'Admin role required.'

    def has_permission(self, request, view):
        account = getattr(request, 'official_account', None)
        return bool(account and account.role_id and account.role.name == 'admin')


class IsAdminOrOperator(BasePermission):
    message = 'Admin or operator role required.'

    def has_permission(self, request, view):
        account = getattr(request, 'official_account', None)
        return bool(account and account.role_id and account.role.name in ('admin', 'operator'))


class ReadOnlyOrAdminOrOperator(BasePermission):
    """Any authenticated official (including viewers) can read; only admin or
    operator roles can write. For reference data viewers need to see but not
    change, e.g. organizations."""
    message = 'Admin or operator role required for this action.'

    def has_permission(self, request, view):
        account = getattr(request, 'official_account', None)
        if not account:
            return False
        if request.method in SAFE_METHODS:
            return True
        return bool(account.role_id and account.role.name in ('admin', 'operator'))


class ReadOnlyOrAdmin(BasePermission):
    """Any authenticated official (including viewers/operators) can read;
    only admin can write. For official-account management, where creating
    or deactivating an account is admin-only but operators/viewers still
    need to see the account list."""
    message = 'Admin role required for this action.'

    def has_permission(self, request, view):
        account = getattr(request, 'official_account', None)
        if not account:
            return False
        if request.method in SAFE_METHODS:
            return True
        return bool(account.role_id and account.role.name == 'admin')
