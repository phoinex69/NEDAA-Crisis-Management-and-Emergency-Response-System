from django.urls import path

from . import views

urlpatterns = [
    path('stats/', views.SummaryStatsView.as_view(), name='analytics-stats'),
    path('response-times/', views.ResponseTimeStatsView.as_view(), name='analytics-response-times'),
    path('heatmap/', views.HeatmapDataView.as_view(), name='analytics-heatmap'),
    path('units/performance/', views.UnitPerformanceView.as_view(), name='analytics-unit-performance'),
    path('severity/comparison/', views.SeverityComparisonView.as_view(), name='analytics-severity-comparison'),
    path('ai/accuracy/', views.AIAccuracyView.as_view(), name='analytics-ai-accuracy'),
    path('incidents/<uuid:cluster_id>/rate/', views.CitizenRatingView.as_view(), name='analytics-incident-rate'),
]
