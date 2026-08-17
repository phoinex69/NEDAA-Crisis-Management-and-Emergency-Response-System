import uuid

from django.db import models


class AuditLog(models.Model):
    ACTOR_TYPE_CHOICES = [
        ('citizen', 'Citizen'),
        ('official', 'Official'),
        ('system', 'System'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor_email = models.CharField(max_length=255)
    actor_type = models.CharField(max_length=20, choices=ACTOR_TYPE_CHOICES)
    action = models.CharField(max_length=100)
    resource_type = models.CharField(max_length=100)
    resource_id = models.CharField(max_length=255)
    note = models.TextField(null=True, blank=True)
    ip_address = models.CharField(max_length=45, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'audit_logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['actor_email']),
            models.Index(fields=['action']),
            models.Index(fields=['resource_type']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f'{self.actor_email} {self.action} {self.resource_type}:{self.resource_id}'
