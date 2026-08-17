from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import BasePermission

ACTIVE_INCIDENT_STATUSES = ('assigned', 'in_progress')


class CanAccessMedicalData(BasePermission):
    message = 'Medical data access requires an active medical incident for this user.'

    def has_object_permission(self, request, view, obj):
        if obj.user_id == request.user.id:
            return True

        official_account = getattr(request, 'official_account', None)
        if official_account and official_account.role_id and official_account.role.name in ('admin', 'operator'):
            from reports.models import Report

            has_active_incident = Report.objects.filter(
                reporter_id=obj.user_id, status__in=ACTIVE_INCIDENT_STATUSES
            ).exists()
            if has_active_incident:
                return True
            raise PermissionDenied(self.message)

        return False
