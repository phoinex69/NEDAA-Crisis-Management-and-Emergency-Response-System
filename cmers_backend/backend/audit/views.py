# Permission classes used in this file: resources.permissions.IsOfficialAccount + IsAdminOrOperator.
# Admins see the full log; operators are restricted server-side (not just a UI banner over
# the same data) to their own dispatch-related actions. Viewers get 403 (IsAdminOrOperator
# excludes them) -- per spec, viewers see nothing here.

from resources.permissions import IsAdminOrOperator, IsOfficialAccount
from rest_framework import generics

from .models import AuditLog
from .serializers import AuditLogSerializer

OPERATOR_VISIBLE_ACTIONS = ['dispatch_confirmed', 'dispatch_overridden', 'incident_closed']


class AuditLogListView(generics.ListAPIView):
    serializer_class = AuditLogSerializer
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]

    def get_queryset(self):
        queryset = AuditLog.objects.all()
        account = self.request.official_account

        is_admin = bool(account.role_id and account.role.name == 'admin')
        if not is_admin:
            queryset = queryset.filter(actor_email__iexact=account.email, action__in=OPERATOR_VISIBLE_ACTIONS)

        params = self.request.query_params

        actor_email = params.get('actor_email')
        if actor_email:
            queryset = queryset.filter(actor_email__iexact=actor_email)

        action = params.get('action')
        if action:
            queryset = queryset.filter(action=action)

        resource_type = params.get('resource_type')
        if resource_type:
            queryset = queryset.filter(resource_type=resource_type)

        date_from = params.get('date_from')
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)

        date_to = params.get('date_to')
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)

        return queryset
