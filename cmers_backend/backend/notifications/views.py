# Permission classes used in this file: core.permissions.IsCitizen (citizen notification endpoints),
# resources.permissions.IsOfficialAccount (broadcast history),
# resources.permissions.IsOfficialAccount + IsAdminOrOperator (broadcast)

from core.audit import get_client_ip, write_audit_log
from core.permissions import IsCitizen
from core.ratelimit import official_account_key
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from resources.permissions import IsAdminOrOperator, IsOfficialAccount
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification
from .serializers import BroadcastHistorySerializer, CreateBroadcastSerializer, NotificationSerializer
from .services import broadcast_alert


class CitizenNotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [IsCitizen]

    def get_queryset(self):
        queryset = Notification.objects.filter(recipient=self.request.user).order_by('-created_at')
        is_read_param = self.request.query_params.get('is_read')
        if is_read_param is not None:
            queryset = queryset.filter(is_read=is_read_param.lower() == 'true')
        return queryset


class MarkNotificationReadView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request, pk):
        notification = Notification.objects.filter(pk=pk, recipient=request.user).first()
        if not notification:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        notification.is_read = True
        notification.save(update_fields=['is_read'])
        return Response(NotificationSerializer(notification).data)


class MarkAllReadView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request):
        count = Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        return Response({'marked_read': count})


class UnreadCountView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request):
        count = Notification.objects.filter(recipient=request.user, is_read=False).count()
        return Response({'count': count})


class BroadcastHistoryListView(generics.ListAPIView):
    # Officials-facing broadcast history. Not the same thing as citizens' personal
    # notifications (IsCitizen-only, filtered to request.user) and deliberately not
    # routed through /audit/logs/ (IsAdmin-only, and the audit entry for
    # 'broadcast_sent' only records the alert type -- not title/message/target area).
    # broadcast_alert() already writes exactly one Notification per broadcast with
    # recipient=None, is_broadcast=True and every field the history UI needs, so this
    # just exposes that to any official instead of only admins.
    serializer_class = BroadcastHistorySerializer
    permission_classes = [IsOfficialAccount]

    def get_queryset(self):
        queryset = Notification.objects.filter(is_broadcast=True).order_by('-created_at')
        date_from = self.request.query_params.get('date_from')
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        date_to = self.request.query_params.get('date_to')
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)
        return queryset


@method_decorator(ratelimit(key=official_account_key, rate='20/h', method='POST', block=True), name='post')
class BroadcastAlertView(APIView):
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]

    def post(self, request):
        serializer = CreateBroadcastSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        citizens_notified = broadcast_alert(
            type=data['type'],
            title=data['title'],
            message=data['message'],
            latitude=data.get('target_latitude'),
            longitude=data.get('target_longitude'),
            radius_km=data.get('target_radius_km') or 2.0,
            created_by=request.official_account,
        )

        write_audit_log(
            actor_email=request.official_account.email,
            actor_type='official',
            action='broadcast_sent',
            resource_type='notification',
            resource_id=data['type'],
            ip_address=get_client_ip(request),
        )

        return Response({
            'message': 'Alert broadcast successfully',
            'citizens_notified': citizens_notified,
            'type': data['type'],
            'area': {
                'lat': data.get('target_latitude'),
                'lng': data.get('target_longitude'),
                'radius_km': data.get('target_radius_km') or 2.0,
            },
        })
