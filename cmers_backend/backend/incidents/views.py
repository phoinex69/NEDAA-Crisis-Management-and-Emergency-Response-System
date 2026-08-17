# Permission classes used in this file: resources.permissions.IsOfficialAccount (all views)

from reports.models import Report
from reports.serializers import ReportSerializer
from resources.permissions import IsOfficialAccount
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AICredibilityScore, IncidentCluster, StatusUpdate
from .serializers import (
    CloseIncidentSerializer,
    IncidentClusterDetailSerializer,
    IncidentClusterListSerializer,
    StatusUpdateSerializer,
)
from .services import close_cluster, get_cluster_detail, get_clusters_queryset, update_cluster_status

STATUS_TRANSITIONS = {
    'active': 'assigned',
    'assigned': 'in_progress',
    'in_progress': 'closed',
}

SEVERITY_LEVEL_MAP = {1: 'low', 2: 'moderate', 3: 'high', 4: 'critical'}


class IncidentClusterListView(generics.ListAPIView):
    serializer_class = IncidentClusterListSerializer
    permission_classes = [IsOfficialAccount]

    def get_queryset(self):
        filters = {
            'status': self.request.query_params.get('status'),
            'severity': self.request.query_params.get('severity'),
            'date_from': self.request.query_params.get('date_from'),
            'date_to': self.request.query_params.get('date_to'),
            'search': self.request.query_params.get('search'),
        }
        return get_clusters_queryset(filters)


class IncidentClusterDetailView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request, pk):
        cluster = get_cluster_detail(pk)
        if not cluster:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(IncidentClusterDetailSerializer(cluster).data)


class UpdateIncidentStatusView(APIView):
    permission_classes = [IsOfficialAccount]

    def patch(self, request, pk):
        cluster = IncidentCluster.objects.filter(pk=pk).first()
        if not cluster:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('new_status')
        note = request.data.get('note', '')

        expected_next = STATUS_TRANSITIONS.get(cluster.status)
        if not expected_next or new_status != expected_next:
            return Response(
                {'detail': f'Invalid status transition from "{cluster.status}" to "{new_status}".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        cluster = update_cluster_status(cluster, new_status, request.official_account, note)
        return Response(IncidentClusterDetailSerializer(cluster).data)


class CloseIncidentView(APIView):
    permission_classes = [IsOfficialAccount]

    def post(self, request, pk):
        cluster = IncidentCluster.objects.filter(pk=pk).first()
        if not cluster:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        if cluster.status == 'closed':
            return Response({'detail': 'Incident is already closed.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = CloseIncidentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        cluster = close_cluster(
            cluster,
            serializer.validated_data['actual_severity'],
            request.official_account,
            serializer.validated_data.get('note', ''),
            request=request,
        )

        # Write training labels back onto the AI credibility scores for this cluster.
        predicted = cluster.ai_severity_predictions.order_by('-computed_at').first()
        ai_was_correct = None
        if predicted:
            ai_was_correct = predicted.predicted_level == SEVERITY_LEVEL_MAP.get(cluster.actual_severity)
        AICredibilityScore.objects.filter(incident=cluster).update(ai_was_correct=ai_was_correct)

        return Response(IncidentClusterDetailSerializer(cluster).data)


class IncidentStatusHistoryView(generics.ListAPIView):
    serializer_class = StatusUpdateSerializer
    permission_classes = [IsOfficialAccount]

    def get_queryset(self):
        return StatusUpdate.objects.filter(incident_id=self.kwargs['pk']).order_by('updated_at')


class IncidentReportsView(generics.ListAPIView):
    serializer_class = ReportSerializer
    permission_classes = [IsOfficialAccount]

    def get_queryset(self):
        cluster = IncidentCluster.objects.filter(pk=self.kwargs['pk']).first()
        if not cluster:
            return Report.objects.none()
        return cluster.source_reports.all()
