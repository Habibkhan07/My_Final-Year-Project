from django.urls import path
from .auth.views import PhoneLoginView, VerifyOTPView, CompleteSignupView

# This structure mirrors your Flutter 'auth' feature folder [cite: 89, 118]
urlpatterns = [
    path('login-otp/', PhoneLoginView.as_view(), name='phone-login'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('complete-signup/', CompleteSignupView.as_view(), name='complete-signup'),
]