from django.db import models

from incidents.models import IncidentCluster
from resources.models import FieldUnit, OfficialAccount
from users.models import User


class DispatchRequest(models.Model):
    STATUS_CHOICES = [
        ('requested', 'Requested'),
        ('assigned', 'Assigned'),
        ('en_route', 'En Route'),
        ('arrived', 'Arrived'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    title = models.CharField(max_length=200)
    incident = models.ForeignKey(IncidentCluster, on_delete=models.CASCADE, related_name='dispatch_requests')
    assigned_unit = models.ForeignKey(FieldUnit, on_delete=models.SET_NULL, null=True, blank=True, related_name='dispatch_requests')
    requested_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='requested_dispatches')
    priority = models.CharField(max_length=20, default='normal')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='requested')
    notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'dispatch_request'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} ({self.status})'


class ResourceAssignment(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('suggested', 'Suggested'),
        ('confirmed', 'Confirmed'),
        ('dispatched', 'Dispatched'),
        ('completed', 'Completed'),
        ('overridden', 'Overridden'),
        ('cancelled', 'Cancelled'),
    ]

    request = models.ForeignKey(
        DispatchRequest, on_delete=models.CASCADE, related_name='resource_assignments', null=True, blank=True
    )
    cluster = models.ForeignKey(
        IncidentCluster, on_delete=models.CASCADE, related_name='resource_assignments', null=True, blank=True
    )
    unit = models.ForeignKey(FieldUnit, on_delete=models.CASCADE, related_name='assignments')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_tasks')
    priority_score = models.FloatField(null=True, blank=True)
    justification = models.TextField(blank=True, default='')
    assigned_at = models.DateTimeField(auto_now_add=True)
    eta_minutes = models.IntegerField(default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    confirmed_by = models.ForeignKey(
        OfficialAccount, on_delete=models.SET_NULL, null=True, blank=True, related_name='confirmed_assignments'
    )
    confirmed_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, default='')

    class Meta:
        db_table = 'dispatch_resource_assignment'

    def __str__(self):
        return f'{self.unit} assigned to {self.cluster or self.request}'
