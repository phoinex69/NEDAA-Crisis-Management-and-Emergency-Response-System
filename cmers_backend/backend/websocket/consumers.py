from channels.generic.websocket import AsyncJsonWebsocketConsumer

from .auth import (
    decode_token,
    get_active_official_account,
    get_token_from_scope,
    report_belongs_to_user,
)

UNAUTHORIZED_CLOSE_CODE = 4401
FORBIDDEN_CLOSE_CODE = 4403


class BroadcastHandlersMixin:
    async def incident_new(self, event):
        await self.send_json(event['payload'])

    async def incident_updated(self, event):
        await self.send_json(event['payload'])

    async def dispatch_updated(self, event):
        await self.send_json(event['payload'])

    async def alert_danger_zone(self, event):
        await self.send_json(event['payload'])

    async def unit_location_updated(self, event):
        await self.send_json(event['payload'])


class OfficialFeedConsumerMixin:
    """Shared connect() for the incidents/units feeds: requires a valid official JWT
    (issued via /resources/auth/login/, carrying an official_account_id claim) passed as
    ?token=<access_token> on the connection URL."""

    async def connect(self):
        validated_token = decode_token(get_token_from_scope(self.scope))
        official_account = await get_active_official_account(validated_token) if validated_token else None
        if not official_account:
            await self.close(code=UNAUTHORIZED_CLOSE_CODE)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        await self.send_json({'type': 'connected', 'message': self.connected_message})

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        if content.get('type') == 'ping':
            await self.send_json({'type': 'pong'})


class IncidentConsumer(OfficialFeedConsumerMixin, BroadcastHandlersMixin, AsyncJsonWebsocketConsumer):
    group_name = 'incidents_feed'
    connected_message = 'Connected to incident feed'


class UnitConsumer(OfficialFeedConsumerMixin, BroadcastHandlersMixin, AsyncJsonWebsocketConsumer):
    group_name = 'units_feed'
    connected_message = 'Connected to unit feed'


class CitizenReportConsumer(AsyncJsonWebsocketConsumer):
    """Requires a valid citizen JWT (no official_account_id claim) belonging to the
    reporter of record for this report_id, passed as ?token=<access_token>."""

    async def connect(self):
        self.report_id = self.scope['url_route']['kwargs']['report_id']
        self.group_name = f'report_{self.report_id}'

        validated_token = decode_token(get_token_from_scope(self.scope))
        if not validated_token or validated_token.get('official_account_id'):
            await self.close(code=UNAUTHORIZED_CLOSE_CODE)
            return

        owns_report = await report_belongs_to_user(self.report_id, validated_token.get('user_id'))
        if not owns_report:
            await self.close(code=FORBIDDEN_CLOSE_CODE)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        await self.send_json({
            'type': 'connected',
            'message': 'Connected to report tracking',
            'report_id': self.report_id,
        })

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        if content.get('type') == 'ping':
            await self.send_json({'type': 'pong'})

    async def report_status_updated(self, event):
        await self.send_json(event['payload'])
