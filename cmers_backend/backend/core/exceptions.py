from django_ratelimit.exceptions import Ratelimited
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler


def custom_exception_handler(exc, context):
    if isinstance(exc, Ratelimited):
        return Response({
            'success': False,
            'error': 'Too many requests. Please try again later.',
            'retry_after': 3600,
        }, status=status.HTTP_429_TOO_MANY_REQUESTS)

    response = drf_exception_handler(exc, context)
    if response is None:
        return response

    original_data = response.data
    message = 'An error occurred.'
    if isinstance(original_data, dict):
        detail = original_data.get('detail')
        if detail:
            message = str(detail)
        else:
            first_key = next(iter(original_data), None)
            if first_key is not None:
                value = original_data[first_key]
                message = f'{first_key}: {value[0] if isinstance(value, list) and value else value}'
    elif isinstance(original_data, list) and original_data:
        message = str(original_data[0])

    response.data = {
        'success': False,
        'error': message,
        'details': original_data,
    }
    return response
