from django.urls import path

from . import views

urlpatterns = [
    path('types/', views.ReportTypeListView.as_view(), name='report-types'),
    path('', views.ReportListCreateView.as_view(), name='report-list-create'),
    path('sos/', views.SOSReportCreateView.as_view(), name='sos-create'),
    path('witness/', views.WitnessReportCreateView.as_view(), name='witness-create'),
    path('voice/', views.VoiceReportCreateView.as_view(), name='voice-create'),
    path('my/', views.MyReportsView.as_view(), name='my-reports'),
    path('<uuid:pk>/status/', views.ReportStatusView.as_view(), name='report-status'),
    path('<uuid:pk>/', views.ReportDetailView.as_view(), name='report-detail'),
]
