import requests
from django.conf import settings

OSRM_URL = settings.OSRM_URL
REQUEST_TIMEOUT_SECONDS = 5


def get_route(origin_lat, origin_lng, dest_lat, dest_lng):
    # OSRM expects coordinates as lng,lat (not lat,lng).
    url = (
        f'{OSRM_URL}/route/v1/driving/'
        f'{origin_lng},{origin_lat};{dest_lng},{dest_lat}'
        f'?overview=false&annotations=false'
    )

    try:
        response = requests.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
        data = response.json()

        if data.get('code') != 'Ok' or not data.get('routes'):
            raise ValueError(data.get('message', 'No route found.'))

        route = data['routes'][0]
        duration_seconds = float(route['duration'])
        distance_meters = float(route['distance'])

        return {
            'duration_seconds': duration_seconds,
            'duration_minutes': duration_seconds / 60,
            'distance_meters': distance_meters,
            'distance_km': distance_meters / 1000,
            'found': True,
        }
    except Exception as exc:
        print(f'[OSRM] Route not found: {exc}')
        return {
            'duration_minutes': None,
            'distance_km': None,
            'found': False,
            'error': str(exc),
        }


def get_table(origins, destinations):
    try:
        coordinates = origins + destinations
        coords_str = ';'.join(f'{lng},{lat}' for lat, lng in coordinates)

        # OSRM's table API expects sources/destinations index lists separated by ';', not ','.
        source_indexes = ';'.join(str(i) for i in range(len(origins)))
        dest_indexes = ';'.join(str(i) for i in range(len(origins), len(origins) + len(destinations)))

        url = (
            f'{OSRM_URL}/table/v1/driving/{coords_str}'
            f'?sources={source_indexes}&destinations={dest_indexes}&annotations=duration'
        )

        response = requests.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
        response.raise_for_status()
        data = response.json()

        if data.get('code') != 'Ok':
            raise ValueError(data.get('message', 'Table request failed.'))

        return data.get('durations')
    except Exception as exc:
        print(f'[OSRM] Table request failed: {exc}')
        return None
