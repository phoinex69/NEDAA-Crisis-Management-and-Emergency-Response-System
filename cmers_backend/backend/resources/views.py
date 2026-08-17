# Permission classes used in this file: permissions.AllowAny (official login),
# resources.permissions.IsOfficialAccount + IsAdmin (roles),
# resources.permissions.IsOfficialAccount + ReadOnlyOrAdmin (official accounts -- any
#   official can list/view, only admin can create/edit/deactivate),
# resources.permissions.IsOfficialAccount + ReadOnlyOrAdminOrOperator (organizations --
#   any official can read, admin/operator can write),
# resources.permissions.IsOfficialAccount + IsAdminOrOperator (unit types, field units, unit status),
# resources.permissions.IsOfficialAccount (unit location update)

from django.contrib.gis.geos import Point
from django.utils import timezone
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from core.audit import get_client_ip, write_audit_log
from routing.services import get_osm_link
from websocket.events import broadcast_unit_location

from .authentication import get_official_tokens
from .models import AccessRole, FieldUnit, OfficialAccount, Organization, UnitType
from .permissions import IsAdmin, IsAdminOrOperator, IsOfficialAccount, ReadOnlyOrAdmin, ReadOnlyOrAdminOrOperator
from .serializers import (
    AccessRoleSerializer,
    CreateOfficialAccountSerializer,
    FieldUnitSerializer,
    OfficialAccountSerializer,
    OfficialLoginSerializer,
    OrganizationSerializer,
    UnitTypeSerializer,
    UpdateLocationSerializer,
)

UNIT_STATUS_OPTIONS = {'available', 'busy', 'out_of_service'}


@method_decorator(ratelimit(key='ip', rate='10/h', method='POST', block=True), name='post')
class OfficialLoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = OfficialLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        account = serializer.validated_data['account']
        tokens = get_official_tokens(account)
        write_audit_log(
            actor_email=account.email,
            actor_type='official',
            action='official_login',
            resource_type='official_account',
            resource_id=str(account.id),
            ip_address=get_client_ip(request),
        )
        return Response({
            'tokens': tokens,
            'account': OfficialAccountSerializer(account).data,
        })


class OrganizationListCreateView(generics.ListCreateAPIView):
    queryset = Organization.objects.all().order_by('-created_at')
    serializer_class = OrganizationSerializer
    permission_classes = [IsOfficialAccount, ReadOnlyOrAdminOrOperator]


class OrganizationDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Organization.objects.all()
    serializer_class = OrganizationSerializer
    permission_classes = [IsOfficialAccount, ReadOnlyOrAdminOrOperator]


class AccessRoleListCreateView(generics.ListCreateAPIView):
    queryset = AccessRole.objects.all().order_by('name')
    serializer_class = AccessRoleSerializer
    permission_classes = [IsOfficialAccount, IsAdmin]


class OfficialAccountListCreateView(generics.ListCreateAPIView):
    queryset = OfficialAccount.objects.select_related('organization', 'role').all().order_by('-created_at')
    permission_classes = [IsOfficialAccount, ReadOnlyOrAdmin]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateOfficialAccountSerializer
        return OfficialAccountSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        account = serializer.save()
        write_audit_log(
            actor_email=request.official_account.email,
            actor_type='official',
            action='account_created',
            resource_type='official_account',
            resource_id=str(account.id),
            ip_address=get_client_ip(request),
        )
        return Response(OfficialAccountSerializer(account).data, status=status.HTTP_201_CREATED)


class OfficialAccountDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = OfficialAccount.objects.select_related('organization', 'role').all()
    serializer_class = OfficialAccountSerializer
    permission_classes = [IsOfficialAccount, ReadOnlyOrAdmin]

    def perform_destroy(self, instance):
        write_audit_log(
            actor_email=self.request.official_account.email,
            actor_type='official',
            action='account_deleted',
            resource_type='official_account',
            resource_id=str(instance.id),
            ip_address=get_client_ip(self.request),
        )
        instance.delete()


class UnitTypeListView(generics.ListCreateAPIView):
    queryset = UnitType.objects.all().order_by('name')
    serializer_class = UnitTypeSerializer
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]


class FieldUnitListCreateView(generics.ListCreateAPIView):
    serializer_class = FieldUnitSerializer
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]

    def get_queryset(self):
        queryset = FieldUnit.objects.select_related('unit_type', 'organization').all().order_by('-created_at')
        status_param = self.request.query_params.get('status')
        unit_type_param = self.request.query_params.get('unit_type')
        if status_param:
            queryset = queryset.filter(status=status_param)
        if unit_type_param:
            queryset = queryset.filter(unit_type_id=unit_type_param)
        return queryset


class FieldUnitDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = FieldUnit.objects.select_related('unit_type', 'organization').all()
    serializer_class = FieldUnitSerializer
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]


class UpdateUnitLocationView(APIView):
    permission_classes = [IsOfficialAccount]

    def patch(self, request, pk):
        unit = FieldUnit.objects.filter(pk=pk).first()
        if not unit:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = UpdateLocationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        latitude = serializer.validated_data['latitude']
        longitude = serializer.validated_data['longitude']

        unit.current_latitude = latitude
        unit.current_longitude = longitude
        unit.current_location = Point(longitude, latitude)
        unit.last_location_update = timezone.now()
        unit.save(update_fields=[
            'current_latitude', 'current_longitude', 'current_location', 'last_location_update',
        ])

        broadcast_unit_location(unit)
        osm_link = get_osm_link(latitude, longitude)

        return Response({
            'id': unit.id,
            'call_sign': unit.call_sign,
            'current_latitude': unit.current_latitude,
            'current_longitude': unit.current_longitude,
            'last_location_update': unit.last_location_update,
            'osm_link': osm_link,
        })


class UnitStatusUpdateView(APIView):
    permission_classes = [IsOfficialAccount, IsAdminOrOperator]

    def patch(self, request, pk):
        unit = FieldUnit.objects.filter(pk=pk).first()
        if not unit:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        if new_status not in UNIT_STATUS_OPTIONS:
            return Response(
                {'detail': f'status must be one of {sorted(UNIT_STATUS_OPTIONS)}.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        unit.status = new_status
        unit.save(update_fields=['status', 'updated_at'])
        return Response(FieldUnitSerializer(unit).data)
