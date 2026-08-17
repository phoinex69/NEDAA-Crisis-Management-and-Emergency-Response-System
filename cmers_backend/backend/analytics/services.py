from collections import Counter

from django.db.models import Avg, Count, Max, Min

SEVERITY_STR_TO_INT = {'low': 1, 'moderate': 2, 'high': 3, 'critical': 4}

REPORT_TYPE_AR = {
    'accident': 'حادث',
    'fire': 'حريق',
    'medical': 'طبي',
    'flood': 'فيضان',
    'security': 'أمن',
    'hazmat': 'مواد خطرة',
    'weather': 'طقس',
    'sos': 'طوارئ',
    'other': 'أخرى',
}


def get_summary_stats(date_from, date_to):
    from incidents.models import IncidentCluster
    from reports.models import Report, WitnessReport

    from .models import IncidentReportSummary

    reports_qs = Report.objects.filter(created_at__range=(date_from, date_to))
    incidents_qs = IncidentCluster.objects.filter(opened_at__range=(date_from, date_to))

    total_reports = reports_qs.count()
    total_incidents = incidents_qs.count()
    active_incidents = incidents_qs.exclude(status='closed').count()
    closed_incidents = incidents_qs.filter(status='closed').count()
    false_reports = reports_qs.filter(status='rejected').count()
    false_report_rate = round((false_reports / total_reports) * 100, 2) if total_reports else 0
    total_sos = reports_qs.filter(report_type='sos').count()
    total_witnesses = WitnessReport.objects.filter(created_at__range=(date_from, date_to)).count()

    avg_response = IncidentReportSummary.objects.filter(
        response_time_minutes__isnull=False,
        incident__opened_at__range=(date_from, date_to),
    ).aggregate(avg=Avg('response_time_minutes'))['avg']

    reports_by_type = dict(
        reports_qs.order_by().values_list('report_type').annotate(count=Count('id')).values_list('report_type', 'count')
    )
    reports_by_severity = dict(
        reports_qs.order_by()
        .values_list('reported_severity')
        .annotate(count=Count('id'))
        .values_list('reported_severity', 'count')
    )
    incidents_by_status = dict(
        incidents_qs.order_by().values_list('status').annotate(count=Count('id')).values_list('status', 'count')
    )

    return {
        'total_reports': total_reports,
        'total_incidents': total_incidents,
        'active_incidents': active_incidents,
        'closed_incidents': closed_incidents,
        'false_reports': false_reports,
        'false_report_rate': false_report_rate,
        'total_sos': total_sos,
        'total_witnesses': total_witnesses,
        'avg_response_time_minutes': round(avg_response, 2) if avg_response is not None else None,
        'reports_by_type': reports_by_type,
        'reports_by_severity': reports_by_severity,
        'incidents_by_status': incidents_by_status,
    }


def get_response_time_stats(date_from, date_to):
    from .models import IncidentReportSummary

    queryset = (
        IncidentReportSummary.objects.filter(
            response_time_minutes__isnull=False,
            incident__status='closed',
            incident__opened_at__range=(date_from, date_to),
        )
        .order_by()
        .values('incident__report_type')
        .annotate(
            avg_response_minutes=Avg('response_time_minutes'),
            min_response_minutes=Min('response_time_minutes'),
            max_response_minutes=Max('response_time_minutes'),
            total_incidents=Count('id'),
        )
    )

    results = []
    for row in queryset:
        report_type = row['incident__report_type'] or 'other'
        results.append({
            'report_type': report_type,
            'report_type_ar': REPORT_TYPE_AR.get(report_type, ''),
            'avg_response_minutes': round(row['avg_response_minutes'], 2),
            'min_response_minutes': round(row['min_response_minutes'], 2),
            'max_response_minutes': round(row['max_response_minutes'], 2),
            'total_incidents': row['total_incidents'],
        })
    return results


def get_heatmap_data(date_from, date_to):
    from incidents.models import IncidentCluster

    clusters = IncidentCluster.objects.filter(
        opened_at__range=(date_from, date_to),
        center_latitude__isnull=False,
        center_longitude__isnull=False,
    ).prefetch_related('ai_severity_predictions', 'source_reports')

    results = []
    for cluster in clusters:
        incident_type = cluster.report_type
        if not incident_type:
            types = list(cluster.source_reports.values_list('report_type', flat=True))
            incident_type = Counter(types).most_common(1)[0][0] if types else None

        severity = cluster.actual_severity
        if severity is None:
            prediction = cluster.ai_severity_predictions.order_by('-computed_at').first()
            severity = SEVERITY_STR_TO_INT.get(prediction.predicted_level) if prediction else None

        results.append({
            'latitude': cluster.center_latitude,
            'longitude': cluster.center_longitude,
            'weight': cluster.report_count,
            'incident_type': incident_type,
            'severity': severity,
        })
    return results


def get_unit_performance(date_from, date_to):
    from dispatch.models import ResourceAssignment
    from resources.models import FieldUnit

    results = []
    for unit in FieldUnit.objects.select_related('unit_type').all():
        assignments = ResourceAssignment.objects.filter(unit=unit, assigned_at__range=(date_from, date_to))
        avg_eta = assignments.aggregate(avg=Avg('eta_minutes'))['avg']

        results.append({
            'unit_id': unit.id,
            'call_sign': unit.call_sign,
            'unit_type': unit.unit_type.name,
            'total_assignments': assignments.count(),
            'completed_assignments': assignments.filter(status='completed').count(),
            'avg_eta_minutes': round(avg_eta, 2) if avg_eta is not None else None,
            'overridden_count': assignments.filter(status='overridden').count(),
        })
    return results


def get_severity_comparison(date_from, date_to):
    from .models import IncidentReportSummary

    queryset = (
        IncidentReportSummary.objects.filter(
            incident__status='closed',
            incident__opened_at__range=(date_from, date_to),
        )
        .select_related('incident')
        .order_by('-incident__opened_at')
    )

    results = []
    for summary in queryset:
        cluster = summary.incident
        ai_was_correct = None
        if summary.ai_predicted_severity is not None and summary.actual_severity is not None:
            ai_was_correct = summary.ai_predicted_severity == summary.actual_severity

        results.append({
            'cluster_id': str(cluster.id),
            'citizen_severity': summary.citizen_reported_severity,
            'ai_predicted_severity': summary.ai_predicted_severity,
            'actual_severity': summary.actual_severity,
            'ai_was_correct': ai_was_correct,
            'opened_at': cluster.opened_at.isoformat() if cluster.opened_at else None,
        })
    return results


def get_ai_accuracy(date_from, date_to):
    from incidents.models import AICredibilityScore

    from .models import IncidentReportSummary

    credibility_qs = AICredibilityScore.objects.filter(
        ai_was_correct__isnull=False,
        incident__opened_at__range=(date_from, date_to),
    )
    total_credibility = credibility_qs.count()
    correct_credibility = credibility_qs.filter(ai_was_correct=True).count()
    rf_accuracy_percent = round((correct_credibility / total_credibility) * 100, 2) if total_credibility else 0

    severity_qs = IncidentReportSummary.objects.filter(
        incident__status='closed',
        incident__opened_at__range=(date_from, date_to),
        ai_predicted_severity__isnull=False,
        actual_severity__isnull=False,
    )
    total_severity = severity_qs.count()
    correct_severity = sum(1 for s in severity_qs if s.ai_predicted_severity == s.actual_severity)
    xgb_accuracy_percent = round((correct_severity / total_severity) * 100, 2) if total_severity else 0

    return {
        'rf_accuracy_percent': rf_accuracy_percent,
        'xgb_accuracy_percent': xgb_accuracy_percent,
        'total_evaluated': total_credibility + total_severity,
    }
