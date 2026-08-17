import random
import string
from datetime import timedelta
from django.utils import timezone


def generate_otp():
    """Generate a 6-digit OTP code."""
    return ''.join(random.choices(string.digits, k=6))


def get_otp_expiry():
    """OTP expires in 10 minutes."""
    return timezone.now() + timedelta(minutes=10)


def is_otp_valid(user):
    """Check if the user's stored OTP is still within its validity window."""
    if not user.otp_code or not user.otp_expires_at:
        return False
    return timezone.now() <= user.otp_expires_at


def is_account_locked(user):
    """Check if the account is currently locked due to failed login attempts."""
    if user.locked_until and timezone.now() < user.locked_until:
        return True
    return False


def lock_account(user):
    """Lock the account for 15 minutes."""
    user.locked_until = timezone.now() + timedelta(minutes=15)
    user.failed_login_attempts = 0
    user.save(update_fields=['locked_until', 'failed_login_attempts'])


def reset_login_attempts(user):
    """Reset failed login counter on successful login."""
    user.failed_login_attempts = 0
    user.locked_until = None
    user.save(update_fields=['failed_login_attempts', 'locked_until'])
