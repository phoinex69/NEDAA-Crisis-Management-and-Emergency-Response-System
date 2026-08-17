import time

from django.utils.deprecation import MiddlewareMixin

from .audit import get_client_ip

LOGGED_PREFIXES = ('/api/v1/', '/ws/')


class RequestLoggingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request._start_time = time.monotonic()

    def process_response(self, request, response):
        path = request.path
        if not path.startswith(LOGGED_PREFIXES):
            return response

        start_time = getattr(request, '_start_time', None)
        elapsed_ms = round((time.monotonic() - start_time) * 1000, 1) if start_time is not None else None

        user = getattr(request, 'user', None)
        if user is not None and getattr(user, 'is_authenticated', False):
            user_label = user.email or user.phone or str(user.pk)
        else:
            user_label = 'anonymous'

        print(
            f'[REQUEST] method={request.method} path={path} user={user_label} '
            f'ip={get_client_ip(request)} status={response.status_code} time={elapsed_ms}ms'
        )
        return response
