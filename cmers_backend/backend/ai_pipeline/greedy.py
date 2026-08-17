from collections import Counter

from django.db.models import Sum

from dispatch.models import ResourceAssignment
from resources.models import FieldUnit
from routing.services import get_eta_for_units

REPORT_TYPE_TO_UNIT_TYPE = {
    'medical': 'ambulance',
    'accident': 'ambulance',
    'sos': 'ambulance',
    'fire': 'fire_truck',
    'flood': 'rescue_team',
    'hazmat': 'rescue_team',
    'security': 'rescue_team',
    'weather': 'shelter',
}

SEVERITY_LEVEL_NUMBERS = {'low': 1, 'moderate': 2, 'high': 3, 'critical': 4}
FALLBACK_ETA_MINUTES = 999


def _cluster_incident_type(cluster):
    if cluster.report_type:
        return cluster.report_type
    types = list(cluster.source_reports.values_list('report_type', flat=True))
    if not types:
        return None
    return Counter(types).most_common(1)[0][0]


def _cluster_victims(cluster):
    total = cluster.source_reports.aggregate(total=Sum('victims_count'))['total']
    return total or 0


def suggest_unit(cluster, severity_prediction):
    incident_type = _cluster_incident_type(cluster)
    unit_type_name = REPORT_TYPE_TO_UNIT_TYPE.get(incident_type)

    units = FieldUnit.objects.filter(status='available')
    if unit_type_name:
        matching = units.filter(unit_type__name=unit_type_name)
        if matching.exists():
            units = matching

    units = list(units)
    if not units:
        return None, None

    eta_by_unit = get_eta_for_units(units, cluster)

    victims = _cluster_victims(cluster)
    severity_level = SEVERITY_LEVEL_NUMBERS.get(
        getattr(severity_prediction, 'predicted_level', None), 1
    )

    credibility = cluster.ai_credibility_scores.order_by('-computed_at').first()
    credibility_score = credibility.score_percent if credibility and credibility.score_percent else 0

    scored = []
    for unit in units:
        eta_minutes = eta_by_unit.get(unit.id, FALLBACK_ETA_MINUTES)

        severity_weight = (severity_level / 4) * 0.45
        victims_weight = min(victims / 50, 1) * 0.30
        credibility_weight = (credibility_score / 100) * 0.15
        distance_weight = (1 / (eta_minutes + 0.1)) * 0.10
        priority = (severity_weight + victims_weight + credibility_weight + distance_weight) * 100

        scored.append((priority, eta_minutes, unit))

    scored.sort(key=lambda item: item[0], reverse=True)
    top_priority, top_eta_minutes, top_unit = scored[0]

    justification = (
        f'Nearest available {top_unit.unit_type.name}, predicted severity {severity_level}, '
        f'{victims} victims reported, credibility {round(credibility_score)}%'
    )

    assignment = ResourceAssignment.objects.create(
        cluster=cluster,
        unit=top_unit,
        priority_score=round(top_priority, 2),
        status='suggested',
        justification=justification,
        eta_minutes=int(round(top_eta_minutes)),
    )

    # Cluster stays 'active' here -- an AI *suggestion* is not a dispatch. Advancing to
    # 'assigned' happens in dispatch/views.py::_advance_cluster_to_assigned() once an
    # operator actually confirms/overrides the dispatch. Flipping it here (as before) had
    # two side effects: operators querying ?status=active could miss incidents that already
    # had a pending, unconfirmed suggestion, and find_or_create_cluster() (which only merges
    # into 'active' clusters) would spin up a redundant duplicate cluster+suggestion for any
    # corroborating report that arrived after the first suggestion was generated -- often
    # within a fraction of a second.

    second_unit = scored[1][2] if len(scored) > 1 else None
    return assignment, second_unit
