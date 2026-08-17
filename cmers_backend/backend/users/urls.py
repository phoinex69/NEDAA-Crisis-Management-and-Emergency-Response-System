from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Auth
    path('register/', views.RegisterView.as_view(), name='register'),
    path('verify-otp/', views.VerifyOTPView.as_view(), name='verify-otp'),
    path('resend-otp/', views.ResendOTPView.as_view(), name='resend-otp'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('password-reset/', views.PasswordResetRequestView.as_view(),
         name='password-reset'),
    path('password-reset/confirm/', views.PasswordResetConfirmView.as_view(),
         name='password-reset-confirm'),

    # Profile
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('profile/medical/', views.MedicalProfileView.as_view(),
         name='medical-profile'),
    path('profile/emergency-contacts/',
         views.EmergencyContactListView.as_view(), name='emergency-contacts'),
    path('profile/emergency-contacts/<uuid:pk>/',
         views.EmergencyContactDetailView.as_view(),
         name='emergency-contact-detail'),

    # Operator access (official JWT only)
    path('<int:user_id>/medical/', views.OperatorMedicalProfileView.as_view(),
         name='operator-medical-profile'),
]
