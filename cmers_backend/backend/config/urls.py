from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView


def health_check(request):
    return JsonResponse({'status': 'ok', 'service': 'NEDAA Backend'}, status=200)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health_check, name='health-check'),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/v1/users/', include('users.urls')),
    path('api/v1/reports/', include('reports.urls')),
    path('api/v1/incidents/', include('incidents.urls')),
    path('api/v1/resources/', include('resources.urls')),
    path('api/v1/dispatch/', include('dispatch.urls')),
    path('api/v1/notifications/', include('notifications.urls')),
    path('api/v1/analytics/', include('analytics.urls')),
    path('api/v1/routing/', include('routing.urls')),
    path('api/v1/audit/', include('audit.urls')),
]
