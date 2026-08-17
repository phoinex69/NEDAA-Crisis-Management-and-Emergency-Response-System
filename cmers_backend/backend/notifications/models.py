from django.db import models

from users.models import User


class Notification(models.Model):
    CHANNEL_CHOICES = [
        ('sms', 'SMS'),
        ('email', 'Email'),
        ('push', 'Push'),
        ('in_app', 'In App'),
    ]

    recipient = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=40, default='info')
    is_read = models.BooleanField(default=False)
    is_broadcast = models.BooleanField(default=False)
    target_latitude = models.FloatField(null=True, blank=True)
    target_longitude = models.FloatField(null=True, blank=True)
    target_radius_km = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'notifications_notification'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} for {self.recipient}'


class NotificationDelivery(models.Model):
    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name='deliveries')
    channel = models.CharField(max_length=20, choices=Notification.CHANNEL_CHOICES, default='in_app')
    status = models.CharField(max_length=20, default='queued')
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications_delivery'

    def __str__(self):
        return f'{self.notification} via {self.channel}'
