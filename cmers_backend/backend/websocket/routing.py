from django.urls import re_path

from . import consumers

websocket_urlpatterns = [
    re_path(r'^ws/incidents/$', consumers.IncidentConsumer.as_asgi()),
    re_path(r'^ws/units/$', consumers.UnitConsumer.as_asgi()),
    re_path(r'^ws/citizen/(?P<report_id>[^/]+)/$', consumers.CitizenReportConsumer.as_asgi()),
]
