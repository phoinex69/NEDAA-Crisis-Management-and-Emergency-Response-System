# Permission classes used in this file: resources.permissions.IsOfficialAccount (all views)

from incidents.models import IncidentCluster
from resources.permissions import IsOfficialAccount
from resources.serializers import FieldUnitSerializer
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import ResourceAssignment
from .serializers import (
    ConfirmAssignmentSerializer,
    OverrideAssignmentSerializer,
    ResourceAssignmentDetailSerializer,
    ResourceAssignmentListSerializer,
)
from .services import (
    complete_assignment,
    confirm_dispatch,
    get_available_units_for_incident,
    get_incident_suggestion,
    override_dispatch,
)

COMPLETABLE_STATUSES = {'confirmed', 'dispatched'}


def _advance_cluster_to_assigned(cluster):
    if cluster and cluster.status == 'active':
        cluster.status = 'assigned'
        cluster.save(update_fields=['status'])


class AssignmentListView(generics.ListAPIView):
    serializer_class = ResourceAssignmentListSerializer
    permission_classes = [IsOfficialAccount]

    def get_queryset(self):
        queryset = ResourceAssignment.objects.select_related(
            'unit', 'unit__unit_type', 'cluster', 'confirmed_by'
        ).prefetch_related('cluster__ai_severity_predictions').order_by('-assigned_at')
        status_param = self.request.query_params.get('status')
        cluster_id = self.request.query_params.get('cluster_id')
        unit_id = self.request.query_params.get('unit_id')
        if status_param:
            queryset = queryset.filter(status=status_param)
        if cluster_id:
            queryset = queryset.filter(cluster_id=cluster_id)
        if unit_id:
            queryset = queryset.filter(unit_id=unit_id)
        return queryset


class AssignmentDetailView(generics.RetrieveAPIView):
    queryset = ResourceAssignment.objects.select_related(
        'unit', 'unit__unit_type', 'unit__organization', 'cluster', 'confirmed_by'
    ).prefetch_related('cluster__ai_severity_predictions')
    serializer_class = ResourceAssignmentDetailSerializer
    permission_classes = [IsOfficialAccount]


class IncidentSuggestionView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request, cluster_id):
        assignment = get_incident_suggestion(cluster_id)
        if not assignment:
            return Response({'detail': 'No AI suggestion available yet.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(ResourceAssignmentDetailSerializer(assignment).data)


class ConfirmDispatchView(APIView):
    permission_classes = [IsOfficialAccount]

    def post(self, request, pk):
        assignment = ResourceAssignment.objects.filter(pk=pk).first()
        if not assignment:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = ConfirmAssignmentSerializer(data=request.data, context={'assignment': assignment})
        serializer.is_valid(raise_exception=True)

        assignment = confirm_dispatch(assignment, request.official_account, request=request)
        _advance_cluster_to_assigned(assignment.cluster)

        return Response(ResourceAssignmentDetailSerializer(assignment).data)


class OverrideDispatchView(APIView):
    permission_classes = [IsOfficialAccount]

    def post(self, request, pk):
        assignment = ResourceAssignment.objects.filter(pk=pk).first()
        if not assignment:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = OverrideAssignmentSerializer(data=request.data, context={'assignment': assignment})
        serializer.is_valid(raise_exception=True)

        new_unit = serializer.validated_data['unit']
        new_assignment = override_dispatch(assignment, new_unit, request.official_account, request=request)
        _advance_cluster_to_assigned(new_assignment.cluster)

        return Response(ResourceAssignmentDetailSerializer(new_assignment).data)


class CompleteAssignmentView(APIView):
    permission_classes = [IsOfficialAccount]

    def post(self, request, pk):
        assignment = ResourceAssignment.objects.filter(pk=pk).first()
        if not assignment:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        if assignment.status not in COMPLETABLE_STATUSES:
            return Response(
                {'detail': f'Assignment must be confirmed or dispatched to complete (current: {assignment.status}).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        assignment = complete_assignment(assignment)
        return Response(ResourceAssignmentDetailSerializer(assignment).data)


class AvailableUnitsView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request, cluster_id):
        cluster = IncidentCluster.objects.filter(pk=cluster_id).first()
        if not cluster:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        units = get_available_units_for_incident(cluster)
        data = []
        for unit in units:
            unit_data = FieldUnitSerializer(unit).data
            eta_minutes = getattr(unit, 'eta_minutes', None)
            unit_data['eta_minutes'] = round(eta_minutes, 2) if eta_minutes is not None else None
            data.append(unit_data)
        return Response(data)
