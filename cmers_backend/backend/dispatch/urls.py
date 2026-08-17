from django.urls import path

from . import views

urlpatterns = [
    path('assignments/', views.AssignmentListView.as_view(), name='assignment-list'),
    path('assignments/<int:pk>/', views.AssignmentDetailView.as_view(), name='assignment-detail'),
    path('assignments/<int:pk>/confirm/', views.ConfirmDispatchView.as_view(), name='assignment-confirm'),
    path('assignments/<int:pk>/override/', views.OverrideDispatchView.as_view(), name='assignment-override'),
    path('assignments/<int:pk>/complete/', views.CompleteAssignmentView.as_view(), name='assignment-complete'),
    path('incidents/<uuid:cluster_id>/suggestion/', views.IncidentSuggestionView.as_view(), name='incident-suggestion'),
    path('incidents/<uuid:cluster_id>/units/', views.AvailableUnitsView.as_view(), name='incident-available-units'),
]
