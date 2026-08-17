from django.contrib.gis.db.models.functions import Distance

from .osrm import get_route, get_table

FALLBACK_SPEED_KMH = 40
UNKNOWN_ETA_MINUTES = 9999.0  # Unit/cluster location unknown - sort last, never treat as "instant".


def _fallback_eta(unit, cluster):
    from resources.models import FieldUnit

    if not unit.current_location or not cluster.location:
        return UNKNOWN_ETA_MINUTES

    annotated = (
        FieldUnit.objects.filter(pk=unit.pk)
        .annotate(distance=Distance('current_location', cluster.location))
        .first()
    )
    if not annotated or annotated.distance is None:
        return UNKNOWN_ETA_MINUTES

    distance_km = annotated.distance.km
    return (distance_km / FALLBACK_SPEED_KMH) * 60


def get_eta(unit, cluster):
    if not unit.current_latitude or not unit.current_longitude or not cluster.center_latitude or not cluster.center_longitude:
        return _fallback_eta(unit, cluster), 'fallback'

    route = get_route(unit.current_latitude, unit.current_longitude, cluster.center_latitude, cluster.center_longitude)
    if route['found']:
        return route['duration_minutes'], 'osrm'

    return _fallback_eta(unit, cluster), 'fallback'


def get_eta_for_units(units, cluster):
    units = list(units)
    result = {}

    if not units or not cluster.center_latitude or not cluster.center_longitude:
        for unit in units:
            eta_minutes, _method = get_eta(unit, cluster)
            result[unit.id] = eta_minutes
        return result

    located_units = [u for u in units if u.current_latitude and u.current_longitude]
    if not located_units:
        for unit in units:
            eta_minutes, _method = get_eta(unit, cluster)
            result[unit.id] = eta_minutes
        return result

    origins = [(u.current_latitude, u.current_longitude) for u in located_units]
    destinations = [(cluster.center_latitude, cluster.center_longitude)]

    durations = get_table(origins, destinations)

    if durations is None:
        for unit in units:
            eta_minutes, _method = get_eta(unit, cluster)
            result[unit.id] = eta_minutes
        return result

    for unit, row in zip(located_units, durations):
        duration_seconds = row[0] if row else None
        result[unit.id] = (duration_seconds / 60) if duration_seconds is not None else _fallback_eta(unit, cluster)

    for unit in units:
        if unit.id not in result:
            eta_minutes, _method = get_eta(unit, cluster)
            result[unit.id] = eta_minutes

    return result


def get_osm_link(latitude, longitude, zoom=16):
    if latitude is None or longitude is None:
        return None
    return f'https://www.openstreetmap.org/?mlat={latitude}&mlon={longitude}&zoom={zoom}'
