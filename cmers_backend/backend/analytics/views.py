# Permission classes used in this file: resources.permissions.IsOfficialAccount (all views except rate),
# core.permissions.IsCitizen (CitizenRatingView)

from core.pagination import StandardPagination
from core.permissions import IsCitizen
from django.core.cache import cache
from incidents.models import IncidentCluster
from resources.permissions import IsOfficialAccount
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import IncidentReportSummary
from .serializers import DateRangeSerializer
from .services import (
    get_ai_accuracy,
    get_heatmap_data,
    get_response_time_stats,
    get_severity_comparison,
    get_summary_stats,
    get_unit_performance,
)


def _parse_date_range(request):
    serializer = DateRangeSerializer(data=request.query_params)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data['date_from'], serializer.validated_data['date_to']


def _cache_key(prefix, date_from, date_to):
    return f'{prefix}_{date_from.date().isoformat()}_{date_to.date().isoformat()}'


class SummaryStatsView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        date_from, date_to = _parse_date_range(request)
        cache_key = _cache_key('analytics_stats', date_from, date_to)

        result = cache.get(cache_key)
        if result is None:
            result = get_summary_stats(date_from, date_to)
            cache.set(cache_key, result, timeout=300)

        response = Response(result)
        response['Cache-Control'] = 'max-age=300'
        return response


class ResponseTimeStatsView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        date_from, date_to = _parse_date_range(request)
        cache_key = _cache_key('analytics_response_times', date_from, date_to)

        result = cache.get(cache_key)
        if result is None:
            result = get_response_time_stats(date_from, date_to)
            cache.set(cache_key, result, timeout=300)

        response = Response(result)
        response['Cache-Control'] = 'max-age=300'
        return response


class HeatmapDataView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        date_from, date_to = _parse_date_range(request)
        cache_key = _cache_key('analytics_heatmap', date_from, date_to)

        result = cache.get(cache_key)
        if result is None:
            result = get_heatmap_data(date_from, date_to)
            cache.set(cache_key, result, timeout=300)

        incident_type = request.query_params.get('incident_type')
        if incident_type:
            result = [item for item in result if item['incident_type'] == incident_type]

        response = Response(result)
        response['Cache-Control'] = 'max-age=300'
        return response


class UnitPerformanceView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        date_from, date_to = _parse_date_range(request)
        return Response(get_unit_performance(date_from, date_to))


class SeverityComparisonView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        date_from, date_to = _parse_date_range(request)
        data = get_severity_comparison(date_from, date_to)

        paginator = StandardPagination()
        page = paginator.paginate_queryset(data, request, view=self)
        return paginator.get_paginated_response(page)


class AIAccuracyView(APIView):
    permission_classes = [IsOfficialAccount]

    def get(self, request):
        date_from, date_to = _parse_date_range(request)
        return Response(get_ai_accuracy(date_from, date_to))


class CitizenRatingView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request, cluster_id):
        rating = request.data.get('rating')
        try:
            rating = int(rating)
        except (TypeError, ValueError):
            rating = None
        if rating is None or rating < 1 or rating > 5:
            return Response({'detail': 'rating must be an integer from 1 to 5.'}, status=status.HTTP_400_BAD_REQUEST)

        cluster = IncidentCluster.objects.filter(pk=cluster_id, status='closed').first()
        if not cluster:
            return Response({'detail': 'Incident not found or not closed.'}, status=status.HTTP_404_NOT_FOUND)

        if not cluster.source_reports.filter(reporter=request.user).exists():
            return Response({'detail': 'You do not have a report in this incident.'}, status=status.HTTP_403_FORBIDDEN)

        summary = IncidentReportSummary.objects.filter(incident=cluster).first()
        if not summary:
            return Response({'detail': 'No summary available for this incident.'}, status=status.HTTP_404_NOT_FOUND)

        summary.citizen_rating = rating
        summary.save(update_fields=['citizen_rating'])

        return Response({'message': 'Thank you for your feedback', 'rating': rating})
