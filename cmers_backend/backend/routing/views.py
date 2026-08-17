# Permission classes used in this file: resources.permissions.IsOfficialAccount (all views)

from incidents.models import IncidentCluster
from resources.models import FieldUnit
from resources.permissions import IsOfficialAccount
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .services import get_eta, get_osm_link


class ETAView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        unit_id = request.query_params.get('unit_id')
        cluster_id = request.query_params.get('cluster_id')

        if not unit_id or not cluster_id:
            return Response(
                {'detail': 'unit_id and cluster_id are both required.'}, status=status.HTTP_400_BAD_REQUEST
            )

        unit = FieldUnit.objects.filter(pk=unit_id).first()
        if not unit:
            return Response({'detail': 'Unit not found.'}, status=status.HTTP_404_NOT_FOUND)

        cluster = IncidentCluster.objects.filter(pk=cluster_id).first()
        if not cluster:
            return Response({'detail': 'Cluster not found.'}, status=status.HTTP_404_NOT_FOUND)

        eta_minutes, routing_method = get_eta(unit, cluster)

        return Response({
            'unit_call_sign': unit.call_sign,
            'cluster_id': str(cluster.id),
            'eta_minutes': round(eta_minutes, 2) if eta_minutes is not None else None,
            'routing_method': routing_method,
            'osm_unit_link': get_osm_link(unit.current_latitude, unit.current_longitude),
            'osm_cluster_link': get_osm_link(cluster.center_latitude, cluster.center_longitude),
        })
