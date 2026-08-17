# Permission classes used in this file: core.permissions.IsCitizen (citizen JWT only, all views)

import os

from core.permissions import IsCitizen
from core.ratelimit import user_or_ip_key
from django.conf import settings
from django.contrib.gis.geos import Point
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from ai_pipeline.tasks import run_ai_pipeline_task
from notifications.services import notify_citizen
from websocket.events import broadcast_citizen_report_update

from .models import Report, VoiceRecord, WitnessReport
from .serializers import ReportCreateSerializer, ReportSerializer, WitnessReportSerializer
from .services import handle_sos_emergency_contacts, transcribe_audio_locally


REPORT_TYPE_OPTIONS = [
    {'value': 'accident', 'label': {'en': 'Accident', 'ar': 'حادث'}},
    {'value': 'fire', 'label': {'en': 'Fire', 'ar': 'حريق'}},
    {'value': 'medical', 'label': {'en': 'Medical', 'ar': 'طبي'}},
    {'value': 'flood', 'label': {'en': 'Flood', 'ar': 'فيضان'}},
    {'value': 'security', 'label': {'en': 'Security', 'ar': 'أمن'}},
    {'value': 'hazmat', 'label': {'en': 'HazMat', 'ar': 'مواد خطرة'}},
    {'value': 'weather', 'label': {'en': 'Weather', 'ar': 'طقس'}},
]


def _detect_report_type(description):
    text = (description or '').lower()
    if 'accident' in text or 'car' in text or 'crash' in text:
        return 'accident'
    if 'fire' in text or 'burn' in text:
        return 'fire'
    if 'medical' in text or 'injur' in text or 'sick' in text or 'hospital' in text:
        return 'medical'
    if 'flood' in text or 'water' in text or 'storm' in text:
        return 'flood'
    if 'security' in text or 'theft' in text or 'gun' in text or 'robbery' in text:
        return 'security'
    if 'gas' in text or 'chemical' in text or 'hazmat' in text:
        return 'hazmat'
    if 'weather' in text or 'rain' in text or 'wind' in text or 'storm' in text:
        return 'weather'
    return 'other'


class ReportTypeListView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request):
        return Response(REPORT_TYPE_OPTIONS)


@method_decorator(ratelimit(key=user_or_ip_key, rate='20/h', method='POST', block=True), name='post')
class ReportListCreateView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request):
        reports = Report.objects.filter(reporter=request.user).order_by('-created_at')
        return Response(ReportSerializer(reports, many=True).data)

    def post(self, request):
        serializer = ReportCreateSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        idempotency_key = (request.data.get('idempotency_key') or '').strip()
        if idempotency_key and Report.objects.filter(reporter=request.user, idempotency_key__iexact=idempotency_key).exists():
            return Response({'detail': 'Duplicate submission detected.'}, status=status.HTTP_409_CONFLICT)

        payload = serializer.validated_data
        report_type = payload.get('report_type') or _detect_report_type(payload.get('description') or '')
        latitude = payload.get('latitude')
        longitude = payload.get('longitude')
        point = None
        if latitude is not None and longitude is not None:
            point = Point(longitude, latitude)

        report = Report.objects.create(
            reporter=request.user,
            report_type=report_type,
            title=(payload.get('title') or (payload.get('description') or 'Report')).strip()[:200] or 'Report',
            description=payload.get('description') or '',
            reported_severity=int(payload.get('reported_severity', 1)),
            victims_count=int(payload.get('victims_count', 0)),
            status='received',
            latitude=latitude,
            longitude=longitude,
            location=point,
            source='web',
            submission_method=payload.get('submission_method', 'form'),
            idempotency_key=idempotency_key,
        )
        broadcast_citizen_report_update(report)
        notify_citizen(
            user=request.user,
            type='general',
            title='Report Received',
            message='Your report has been received and is being processed.',
        )
        run_ai_pipeline_task.delay(str(report.id))
        return Response(ReportSerializer(report).data, status=status.HTTP_201_CREATED)


class MyReportsView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request):
        reports = Report.objects.filter(reporter=request.user).order_by('-created_at')
        return Response(ReportSerializer(reports, many=True).data)


class ReportDetailView(generics.RetrieveAPIView):
    permission_classes = [IsCitizen]
    serializer_class = ReportSerializer

    def get_queryset(self):
        return Report.objects.filter(reporter=self.request.user)


class ReportStatusView(APIView):
    permission_classes = [IsCitizen]

    def get(self, request, pk):
        report = Report.objects.filter(reporter=request.user, id=pk).first()
        if not report:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        assigned_unit = None
        eta_minutes = None
        message = 'No unit assigned yet.'
        if report.cluster_id:
            from dispatch.models import ResourceAssignment
            assignment = (
                ResourceAssignment.objects.filter(cluster_id=report.cluster_id, status__in=['confirmed', 'dispatched'])
                .select_related('unit')
                .order_by('-assigned_at')
                .first()
            )
            if assignment:
                assigned_unit = assignment.unit.call_sign
                eta_minutes = assignment.eta_minutes
                message = f'Unit {assigned_unit} ETA {eta_minutes} minutes.'

        return Response({
            'id': str(report.id),
            'status': report.status,
            'assigned_unit': assigned_unit,
            'eta_minutes': eta_minutes,
            'message': message,
        })


@method_decorator(ratelimit(key=user_or_ip_key, rate='10/h', method='POST', block=False), name='post')
class SOSReportCreateView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request):
        if getattr(request, 'limited', False):
            identifier = request.user.email or request.user.phone
            print(f'[RATE WARNING] SOS rate exceeded for user {identifier} — allowing anyway')

        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        point = None
        if latitude is not None and longitude is not None:
            point = Point(float(longitude), float(latitude))

        report = Report.objects.create(
            reporter=request.user,
            report_type='sos',
            title='SOS Alert',
            description='Emergency SOS alert',
            reported_severity=5,
            victims_count=int(request.data.get('victims_count', 0) or 0),
            status='received',
            latitude=latitude,
            longitude=longitude,
            location=point,
            source='sos',
            submission_method='sos',
            idempotency_key=(request.data.get('idempotency_key') or '').strip(),
        )
        handle_sos_emergency_contacts(report)
        broadcast_citizen_report_update(report)
        run_ai_pipeline_task.delay(str(report.id))
        return Response(ReportSerializer(report).data, status=status.HTTP_201_CREATED)


@method_decorator(ratelimit(key=user_or_ip_key, rate='30/h', method='POST', block=True), name='post')
class WitnessReportCreateView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request):
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        point = None
        if latitude is not None and longitude is not None:
            point = Point(float(longitude), float(latitude))

        report = Report.objects.create(
            reporter=request.user,
            report_type='security',
            title='Witness Report',
            description='Witness report submitted.',
            reported_severity=1,
            victims_count=0,
            status='received',
            latitude=latitude,
            longitude=longitude,
            location=point,
            source='witness',
            submission_method='witness',
        )
        WitnessReport.objects.create(
            report=report,
            witness_name=request.data.get('witness_name', 'Anonymous'),
            contact_info=request.data.get('contact_info', ''),
            statement=request.data.get('statement', 'Witness report submitted.')
        )
        return Response({
            'id': str(report.id),
            'status': report.status,
            'message': 'Witness report submitted.'
        }, status=status.HTTP_201_CREATED)


class VoiceReportCreateView(APIView):
    permission_classes = [IsCitizen]

    def post(self, request):
        audio_file = request.FILES.get('audio')
        if not audio_file:
            return Response({'detail': 'audio file is required.'}, status=status.HTTP_400_BAD_REQUEST)

        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        point = None
        if latitude is not None and longitude is not None:
            point = Point(float(longitude), float(latitude))

        report = Report.objects.create(
            reporter=request.user,
            report_type='other',
            title='Voice Report',
            description='',
            status='pending_transcription',
            latitude=latitude,
            longitude=longitude,
            location=point,
            source='mobile',
            submission_method='voice',
        )

        voice_dir = os.path.join(settings.MEDIA_ROOT, 'voice_reports')
        os.makedirs(voice_dir, exist_ok=True)
        filename = f'{report.id}_{audio_file.name}'
        file_path = os.path.join(voice_dir, filename)
        with open(file_path, 'wb') as destination:
            for chunk in audio_file.chunks():
                destination.write(chunk)

        audio_url = request.build_absolute_uri(f'{settings.MEDIA_URL}voice_reports/{filename}')
        transcript = transcribe_audio_locally(file_path)

        VoiceRecord.objects.create(
            report=report,
            audio_url=audio_url,
            transcript=transcript,
        )

        return Response({
            'id': str(report.id),
            'status': report.status,
            'transcript': transcript,
            'audio_url': audio_url,
        }, status=status.HTTP_201_CREATED)
