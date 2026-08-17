from rest_framework import serializers

from .models import Notification

BROADCAST_TYPE_CHOICES = ['danger_zone', 'road_closure', 'weather', 'general']


class NotificationSerializer(serializers.ModelSerializer):
    type = serializers.CharField(source='notification_type', read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'type', 'title', 'message', 'is_read', 'is_broadcast', 'created_at']
        read_only_fields = ['id', 'type', 'title', 'message', 'is_broadcast', 'created_at']


class BroadcastHistorySerializer(serializers.ModelSerializer):
    type = serializers.CharField(source='notification_type', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'type', 'title', 'message',
            'target_latitude', 'target_longitude', 'target_radius_km', 'created_at',
        ]
        read_only_fields = fields


class CreateBroadcastSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=BROADCAST_TYPE_CHOICES)
    title = serializers.CharField(max_length=200)
    message = serializers.CharField()
    target_latitude = serializers.FloatField(required=False, allow_null=True, default=None)
    target_longitude = serializers.FloatField(required=False, allow_null=True, default=None)
    target_radius_km = serializers.FloatField(required=False, default=2.0)

    def validate(self, attrs):
        latitude = attrs.get('target_latitude')
        longitude = attrs.get('target_longitude')
        if (latitude is None) != (longitude is None):
            raise serializers.ValidationError(
                'target_latitude and target_longitude must be provided together.'
            )
        return attrs
