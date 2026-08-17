from channels.db import database_sync_to_async
from channels.testing import WebsocketCommunicator
from django.test import TransactionTestCase

from config.asgi import application
from incidents.models import IncidentCluster
from websocket.events import broadcast_new_incident


class TestWebSocket(TransactionTestCase):
    async def test_incident_consumer_connects(self):
        communicator = WebsocketCommunicator(application, '/ws/incidents/')
        connected, _ = await communicator.connect()
        self.assertTrue(connected)

        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'connected')

        await communicator.disconnect()

    async def test_unit_consumer_connects(self):
        communicator = WebsocketCommunicator(application, '/ws/units/')
        connected, _ = await communicator.connect()
        self.assertTrue(connected)

        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'connected')

        await communicator.disconnect()

    async def test_citizen_consumer_connects(self):
        communicator = WebsocketCommunicator(application, '/ws/citizen/test-report-id/')
        connected, _ = await communicator.connect()
        self.assertTrue(connected)

        response = await communicator.receive_json_from()
        self.assertEqual(response.get('report_id'), 'test-report-id')

        await communicator.disconnect()

    async def test_broadcast_incident_received(self):
        cluster = await database_sync_to_async(IncidentCluster.objects.create)(
            center_latitude=33.5138, center_longitude=36.2765, status='active',
        )

        communicator = WebsocketCommunicator(application, '/ws/incidents/')
        connected, _ = await communicator.connect()
        self.assertTrue(connected)
        await communicator.receive_json_from()  # welcome message

        await database_sync_to_async(broadcast_new_incident)(cluster)

        event = await communicator.receive_json_from()
        self.assertEqual(event['type'], 'incident.new')
        self.assertEqual(event['data']['id'], str(cluster.id))

        await communicator.disconnect()

    async def test_ping_pong(self):
        communicator = WebsocketCommunicator(application, '/ws/incidents/')
        connected, _ = await communicator.connect()
        self.assertTrue(connected)
        await communicator.receive_json_from()  # welcome message

        await communicator.send_json_to({'type': 'ping'})
        response = await communicator.receive_json_from()
        self.assertEqual(response['type'], 'pong')

        await communicator.disconnect()
