from django.urls import path

from . import views

urlpatterns = [
    path('eta/', views.ETAView.as_view(), name='routing-eta'),
]
