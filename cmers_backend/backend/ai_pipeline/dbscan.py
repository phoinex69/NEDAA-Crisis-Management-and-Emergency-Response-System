from datetime import timedelta

from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.db.models import Q
from django.utils import timezone

from incidents.models import IncidentCluster

CLUSTER_RADIUS_METERS = 500
CLUSTER_WINDOW_MINUTES = 60


def _link_report(report, cluster):
    report.cluster = cluster
    report.save(update_fields=['cluster'])
    cluster.source_reports.add(report)


def _new_cluster(report):
    cluster = IncidentCluster.objects.create(
        status='active',
        report_type=report.report_type,
        center_latitude=report.latitude,
        center_longitude=report.longitude,
        location=report.location,
        report_count=1,
    )
    _link_report(report, cluster)
    return cluster, True


def find_or_create_cluster(report):
    if not report.location:
        return _new_cluster(report)

    window_start = timezone.now() - timedelta(minutes=CLUSTER_WINDOW_MINUTES)

    candidates = (
        IncidentCluster.objects.filter(
            status='active',
            opened_at__gte=window_start,
            location__dwithin=(report.location, D(m=CLUSTER_RADIUS_METERS)),
        )
        .filter(Q(report_type=report.report_type) | Q(report_type__isnull=True))
        .annotate(distance=Distance('location', report.location))
        .order_by('distance')
    )

    cluster = candidates.first()
    if cluster:
        cluster.report_count += 1
        cluster.save(update_fields=['report_count'])
        _link_report(report, cluster)
        return cluster, False

    return _new_cluster(report)
