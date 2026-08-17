from django.urls import path

from . import views

urlpatterns = [
    path('', views.CitizenNotificationListView.as_view(), name='notification-list'),
    path('read-all/', views.MarkAllReadView.as_view(), name='notification-read-all'),
    path('unread-count/', views.UnreadCountView.as_view(), name='notification-unread-count'),
    path('broadcasts/', views.BroadcastHistoryListView.as_view(), name='notification-broadcast-history'),
    path('<int:pk>/read/', views.MarkNotificationReadView.as_view(), name='notification-read'),
    path('broadcast/', views.BroadcastAlertView.as_view(), name='notification-broadcast'),
]
