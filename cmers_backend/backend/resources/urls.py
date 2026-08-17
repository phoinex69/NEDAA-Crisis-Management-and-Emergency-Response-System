from django.urls import path

from . import views

urlpatterns = [
    path('auth/login/', views.OfficialLoginView.as_view(), name='official-login'),

    path('organizations/', views.OrganizationListCreateView.as_view(), name='organization-list-create'),
    path('organizations/<int:pk>/', views.OrganizationDetailView.as_view(), name='organization-detail'),

    path('roles/', views.AccessRoleListCreateView.as_view(), name='role-list-create'),

    path('accounts/', views.OfficialAccountListCreateView.as_view(), name='account-list-create'),
    path('accounts/<int:pk>/', views.OfficialAccountDetailView.as_view(), name='account-detail'),

    path('unit-types/', views.UnitTypeListView.as_view(), name='unit-type-list'),

    path('units/', views.FieldUnitListCreateView.as_view(), name='unit-list-create'),
    path('units/<int:pk>/', views.FieldUnitDetailView.as_view(), name='unit-detail'),
    path('units/<int:pk>/location/', views.UpdateUnitLocationView.as_view(), name='unit-location'),
    path('units/<int:pk>/status/', views.UnitStatusUpdateView.as_view(), name='unit-status'),
]
