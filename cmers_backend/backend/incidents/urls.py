from django.urls import path

from . import views

urlpatterns = [
    path('', views.IncidentClusterListView.as_view(), name='incident-list'),
    path('<uuid:pk>/', views.IncidentClusterDetailView.as_view(), name='incident-detail'),
    path('<uuid:pk>/status/', views.UpdateIncidentStatusView.as_view(), name='incident-status'),
    path('<uuid:pk>/close/', views.CloseIncidentView.as_view(), name='incident-close'),
    path('<uuid:pk>/history/', views.IncidentStatusHistoryView.as_view(), name='incident-history'),
    path('<uuid:pk>/reports/', views.IncidentReportsView.as_view(), name='incident-reports'),
]
