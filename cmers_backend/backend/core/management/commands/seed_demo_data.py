import random
from datetime import timedelta

import bcrypt
from django.contrib.gis.geos import Point
from django.core.management.base import BaseCommand
from django.utils import timezone

from analytics.models import IncidentReportSummary
from audit.models import AuditLog
from dispatch.models import ResourceAssignment
from incidents.models import AICredibilityScore, AISeverityPrediction, IncidentCluster, StatusUpdate
from notifications.models import Notification
from reports.models import Report, VoiceRecord, WitnessReport
from resources.models import AccessRole, FieldUnit, OfficialAccount, Organization, UnitType
from users.models import EmergencyContact, MedicalProfile, User

# The real Report.report_type enum (fire/medical/accident/flood/security/hazmat/weather/sos/other) doesn't
# contain the demo script's more specific categories, so map them onto the closest real choice.
REPORT_TYPE_MAP = {
    'fire': 'fire',
    'ambulance': 'medical',
    'rescue': 'other',
    'building_collapse': 'other',
}

SEVERITY_LEVEL_NAMES = {1: 'low', 2: 'moderate', 3: 'high', 4: 'critical'}


def _hash_password(raw_password):
    return bcrypt.hashpw(raw_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def _offset(value, spread=0.002):
    return value + random.uniform(-spread, spread)


class Command(BaseCommand):
    help = 'Wipes non-lookup data and seeds a complete realistic demo dataset for NEDAA.'

    def handle(self, *args, **options):
        now = timezone.now()

        self.stdout.write('Clearing existing non-lookup data...')
        self._clear_data()

        self.stdout.write('STEP 1: Organizations')
        org_civil_defense, org_red_crescent, org_police = self._seed_organizations()

        self.stdout.write('STEP 2: Official accounts')
        admin_account, operator1_account, operator2_account, viewer_account = self._seed_official_accounts(
            org_civil_defense, org_red_crescent, org_police
        )

        self.stdout.write('STEP 3: Field units')
        units = self._seed_field_units(org_civil_defense, org_red_crescent, org_police, now)

        self.stdout.write('STEP 4: Citizen users')
        ahmed, sara, omar, lina, karim = self._seed_citizens()

        self.stdout.write('STEP 5: Incident clusters')
        cluster_a, cluster_b, cluster_c, cluster_d = self._seed_clusters(now)
        cluster_e, cluster_f, cluster_g, cluster_h = self._seed_extra_clusters(now)

        self.stdout.write('STEP 6: Reports')
        cluster_a_reports, cluster_b_reports, cluster_c_reports, cluster_d_reports = self._seed_reports(
            ahmed, sara, omar, lina, karim, cluster_a, cluster_b, cluster_c, cluster_d
        )
        self._seed_extra_reports(ahmed, sara, omar, lina, karim, cluster_e, cluster_f, cluster_g, cluster_h)

        self.stdout.write('STEP 7: Witness reports')
        self._seed_witness_reports(omar, karim, ahmed, cluster_a, cluster_c, cluster_d)

        self.stdout.write('STEP 8: AI credibility scores')
        self._seed_credibility_scores(cluster_a, cluster_b, cluster_c, cluster_d)
        self._seed_extra_credibility_scores(cluster_e, cluster_f, cluster_g, cluster_h)

        self.stdout.write('STEP 9: AI severity predictions')
        self._seed_severity_predictions(cluster_a, cluster_b, cluster_c, cluster_d)
        self._seed_extra_severity_predictions(cluster_e, cluster_f, cluster_g, cluster_h)

        self.stdout.write('STEP 10: Resource assignments')
        assignment_a, assignment_b, assignment_c, assignment_d = self._seed_assignments(
            cluster_a, cluster_b, cluster_c, cluster_d, units, operator1_account, operator2_account, now
        )
        assignment_e, assignment_f, assignment_g, assignment_h = self._seed_extra_assignments(
            cluster_e, cluster_f, cluster_g, cluster_h, units, operator1_account, operator2_account, now
        )

        self.stdout.write('STEP 11: Status updates')
        self._seed_status_updates(cluster_a, cluster_b, cluster_c, cluster_d, operator1_account, operator2_account, now)
        self._seed_extra_status_updates(
            cluster_e, cluster_f, cluster_g, cluster_h, operator1_account, operator2_account, now
        )

        self.stdout.write('STEP 12: Incident report summary')
        self._seed_report_summary(cluster_d)
        self._seed_extra_report_summary(cluster_h, now)

        self.stdout.write('STEP 13: Notifications')
        broadcast_fire = self._seed_notifications(ahmed, sara, lina, now)
        broadcast_security, broadcast_flood = self._seed_extra_notifications(ahmed, sara, omar, now)

        self.stdout.write('STEP 14: Audit logs')
        self._seed_audit_logs(
            admin_account, operator1_account, operator2_account,
            assignment_c, assignment_d, cluster_d, ahmed, broadcast_fire, now
        )
        self._seed_extra_audit_logs(
            admin_account, operator1_account, operator2_account,
            assignment_f, assignment_g, cluster_h, broadcast_security, broadcast_flood, now
        )

        self._print_summary()

    # ------------------------------------------------------------------
    # Clearing
    # ------------------------------------------------------------------
    def _clear_data(self):
        AuditLog.objects.all().delete()
        Notification.objects.all().delete()
        IncidentReportSummary.objects.all().delete()
        ResourceAssignment.objects.all().delete()
        AISeverityPrediction.objects.all().delete()
        AICredibilityScore.objects.all().delete()
        StatusUpdate.objects.all().delete()
        WitnessReport.objects.all().delete()
        VoiceRecord.objects.all().delete()
        Report.objects.all().delete()
        IncidentCluster.objects.all().delete()
        FieldUnit.objects.all().delete()
        OfficialAccount.objects.all().delete()
        EmergencyContact.objects.all().delete()
        MedicalProfile.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()
        Organization.objects.all().delete()

    # ------------------------------------------------------------------
    # STEP 1
    # ------------------------------------------------------------------
    def _seed_organizations(self):
        civil_defense = Organization.objects.create(name='Civil Defense', organization_type='government')
        red_crescent = Organization.objects.create(name='Syrian Arab Red Crescent', organization_type='ngo')
        police = Organization.objects.create(name='Damascus Police', organization_type='government')
        return civil_defense, red_crescent, police

    # ------------------------------------------------------------------
    # STEP 2
    # ------------------------------------------------------------------
    def _seed_official_accounts(self, org_civil_defense, org_red_crescent, org_police):
        role_admin, _ = AccessRole.objects.get_or_create(name='admin', defaults={'permissions': {'all': True}})
        role_operator, _ = AccessRole.objects.get_or_create(
            name='operator', defaults={'permissions': {'dispatch': True, 'view': True}}
        )
        AccessRole.objects.get_or_create(name='viewer', defaults={'permissions': {'view': True}})
        role_viewer = AccessRole.objects.get(name='viewer')

        admin_account = OfficialAccount.objects.create(
            email='admin@cmers.com', password_hash=_hash_password('Admin1234!'),
            full_name='System Admin', organization=org_civil_defense, role=role_admin, is_active=True,
        )
        operator1_account = OfficialAccount.objects.create(
            email='operator1@cmers.com', password_hash=_hash_password('Operator1234!'),
            full_name='Khalid Mansour', organization=org_civil_defense, role=role_operator, is_active=True,
        )
        operator2_account = OfficialAccount.objects.create(
            email='operator2@cmers.com', password_hash=_hash_password('Operator1234!'),
            full_name='Rania Haddad', organization=org_red_crescent, role=role_operator, is_active=True,
        )
        viewer_account = OfficialAccount.objects.create(
            email='viewer@cmers.com', password_hash=_hash_password('Viewer1234!'),
            full_name='Sami Barakat', organization=org_police, role=role_viewer, is_active=True,
        )
        return admin_account, operator1_account, operator2_account, viewer_account

    # ------------------------------------------------------------------
    # STEP 3
    # ------------------------------------------------------------------
    def _seed_field_units(self, org_civil_defense, org_red_crescent, org_police, now):
        unit_type_ambulance = UnitType.objects.get(name='ambulance')
        unit_type_fire_truck = UnitType.objects.get(name='fire_truck')
        unit_type_rescue_team = UnitType.objects.get(name='rescue_team')
        unit_type_shelter = UnitType.objects.get(name='shelter')

        def make_unit(call_sign, unit_type, org, unit_status, lat, lng):
            return FieldUnit.objects.create(
                call_sign=call_sign, unit_type=unit_type, organization=org, status=unit_status,
                current_latitude=lat, current_longitude=lng,
                current_location=Point(lng, lat, srid=4326),
                last_location_update=now,
            )

        # Status here must match each unit's most recent non-completed assignment
        # (see _seed_assignments / _seed_extra_assignments): 'suggested' means the
        # AI proposed it but nobody confirmed yet, so the unit is still genuinely
        # available; 'confirmed'/'dispatched' means it's actually out on a call, so
        # it must show 'busy'; 'completed' frees it back up. Getting this wrong is
        # what made the Units page, the map, and Dispatch disagree with each other.
        units = {
            'AMB-01': make_unit('AMB-01', unit_type_ambulance, org_civil_defense, 'available', 33.5100, 36.2900),
            'AMB-02': make_unit('AMB-02', unit_type_ambulance, org_civil_defense, 'busy', 33.5300, 36.2600),
            'FIRE-01': make_unit('FIRE-01', unit_type_fire_truck, org_civil_defense, 'available', 33.5050, 36.2700),
            'RESCUE-01': make_unit('RESCUE-01', unit_type_rescue_team, org_civil_defense, 'busy', 33.5200, 36.3000),
            'AMB-RC-01': make_unit('AMB-RC-01', unit_type_ambulance, org_red_crescent, 'busy', 33.5400, 36.2500),
            'SHELTER-01': make_unit('SHELTER-01', unit_type_shelter, org_red_crescent, 'available', 33.5150, 36.2850),
            'POLICE-01': make_unit('POLICE-01', unit_type_rescue_team, org_police, 'available', 33.5080, 36.2750),
            'POLICE-02': make_unit('POLICE-02', unit_type_rescue_team, org_police, 'busy', 33.5250, 36.2950),
        }
        return units

    # ------------------------------------------------------------------
    # STEP 4
    # ------------------------------------------------------------------
    def _seed_citizens(self):
        def make_citizen(email, full_name, phone, lang):
            user = User(
                email=email, username=email.split('@')[0], full_name=full_name,
                phone=phone, preferred_language=lang, is_verified=True,
                otp_verified=True, is_active=True,
            )
            user.set_password('Citizen1234!')
            user.save()
            return user

        ahmed = make_citizen('ahmed@citizen.com', 'Ahmed Al-Hassan', '+963911000001', 'ar')
        sara = make_citizen('sara@citizen.com', 'Sara Khalil', '+963911000002', 'ar')
        omar = make_citizen('omar@citizen.com', 'Omar Darwish', '+963911000003', 'en')
        lina = make_citizen('lina@citizen.com', 'Lina Nassir', '+963911000004', 'ar')
        karim = make_citizen('karim@citizen.com', 'Karim Yousef', '+963911000005', 'en')

        EmergencyContact.objects.create(
            user=ahmed, name='Fatima Al-Hassan', relationship='Family', phone_number='+963911000099',
        )
        MedicalProfile.objects.create(
            user=ahmed, blood_type='A+', allergies='Penicillin',
            chronic_conditions='Hypertension', medications='Amlodipine 5mg',
        )
        return ahmed, sara, omar, lina, karim

    # ------------------------------------------------------------------
    # STEP 5
    # ------------------------------------------------------------------
    def _seed_clusters(self, now):
        cluster_a = IncidentCluster.objects.create(
            center_latitude=33.5138, center_longitude=36.2765,
            location=Point(36.2765, 33.5138, srid=4326),
            report_count=8, witness_count=3, status='active', report_type='fire',
            opened_at=now - timedelta(hours=2),
        )
        cluster_b = IncidentCluster.objects.create(
            center_latitude=33.5220, center_longitude=36.2880,
            location=Point(36.2880, 33.5220, srid=4326),
            report_count=3, witness_count=1, status='assigned', report_type='medical',
            opened_at=now - timedelta(minutes=45),
        )
        cluster_c = IncidentCluster.objects.create(
            center_latitude=33.5060, center_longitude=36.2640,
            location=Point(36.2640, 33.5060, srid=4326),
            report_count=5, witness_count=2, status='in_progress', report_type='other',
            opened_at=now - timedelta(hours=3),
        )
        cluster_d = IncidentCluster.objects.create(
            center_latitude=33.5310, center_longitude=36.3010,
            location=Point(36.3010, 33.5310, srid=4326),
            report_count=12, witness_count=5, status='closed', report_type='other',
            actual_severity=4,
            opened_at=now - timedelta(hours=6),
            closed_at=now - timedelta(hours=3),
        )
        return cluster_a, cluster_b, cluster_c, cluster_d

    def _seed_extra_clusters(self, now):
        cluster_e = IncidentCluster.objects.create(
            center_latitude=33.5010, center_longitude=36.2580,
            location=Point(36.2580, 33.5010, srid=4326),
            report_count=4, witness_count=2, status='active', report_type='accident',
            opened_at=now - timedelta(hours=1),
        )
        cluster_f = IncidentCluster.objects.create(
            center_latitude=33.5280, center_longitude=36.2820,
            location=Point(36.2820, 33.5280, srid=4326),
            report_count=6, witness_count=4, status='assigned', report_type='security',
            opened_at=now - timedelta(minutes=30),
        )
        cluster_g = IncidentCluster.objects.create(
            center_latitude=33.4980, center_longitude=36.3100,
            location=Point(36.3100, 33.4980, srid=4326),
            report_count=3, witness_count=1, status='in_progress', report_type='flood',
            opened_at=now - timedelta(hours=4),
        )
        cluster_h = IncidentCluster.objects.create(
            center_latitude=33.5180, center_longitude=36.2500,
            location=Point(36.2500, 33.5180, srid=4326),
            report_count=7, witness_count=3, status='closed', report_type='security',
            actual_severity=3,
            opened_at=now - timedelta(hours=8),
            closed_at=now - timedelta(hours=5),
        )
        return cluster_e, cluster_f, cluster_g, cluster_h

    # ------------------------------------------------------------------
    # STEP 6
    # ------------------------------------------------------------------
    def _seed_reports(self, ahmed, sara, omar, lina, karim, cluster_a, cluster_b, cluster_c, cluster_d):
        def make_report(user, type_key, description, severity, victims, lat, lng, method, status_value, cluster):
            report_type = REPORT_TYPE_MAP.get(type_key, type_key)
            report = Report.objects.create(
                reporter=user, report_type=report_type, title=(description or 'Report')[:60],
                description=description, reported_severity=severity, victims_count=victims,
                status=status_value, latitude=lat, longitude=lng,
                location=Point(lng, lat, srid=4326),
                source='mobile', submission_method=method, cluster=cluster,
            )
            cluster.source_reports.add(report)
            return report

        report1 = make_report(ahmed, 'fire', 'حريق كبير في السوق القديم', 4, 6, 33.5140, 36.2770, 'form', 'received', cluster_a)
        report2 = make_report(sara, 'fire', 'دخان كثيف وألسنة نار', 3, 2, 33.5135, 36.2760, 'sos', 'received', cluster_a)
        report3 = make_report(omar, 'fire', 'Fire spreading to nearby buildings', 4, 4, 33.5142, 36.2768, 'witness', 'received', cluster_a)

        report4 = make_report(lina, 'ambulance', 'إصابات متعددة في حادث سير', 3, 3, 33.5222, 36.2882, 'form', 'assigned', cluster_b)
        report5 = make_report(karim, 'ambulance', 'Multiple injuries need urgent help', 2, 1, 33.5218, 36.2878, 'form', 'assigned', cluster_b)

        report6 = make_report(ahmed, 'rescue', 'أشخاص محاصرون تحت الأنقاض', 4, 5, 33.5062, 36.2642, 'form', 'in_progress', cluster_c)
        report7 = make_report(omar, 'building_collapse', 'Partial collapse with people trapped', 4, 3, 33.5058, 36.2638, 'form', 'in_progress', cluster_c)

        report8 = make_report(sara, 'building_collapse', 'انهيار مبنى سكني من 4 طوابق', 3, 10, 33.5312, 36.3012, 'form', 'closed', cluster_d)
        report9 = make_report(lina, 'building_collapse', 'انهيار جزئي والكثير من الضحايا', 4, 8, 33.5308, 36.3008, 'sos', 'closed', cluster_d)
        report10 = make_report(karim, 'rescue', 'People buried under rubble', 4, 6, 33.5314, 36.3014, 'form', 'closed', cluster_d)

        return (
            [report1, report2, report3],
            [report4, report5],
            [report6, report7],
            [report8, report9, report10],
        )

    def _seed_extra_reports(self, ahmed, sara, omar, lina, karim, cluster_e, cluster_f, cluster_g, cluster_h):
        def make_report(user, report_type, description, severity, victims, base_lat, base_lng, method, status_value, cluster):
            lat, lng = _offset(base_lat), _offset(base_lng)
            report = Report.objects.create(
                reporter=user, report_type=report_type, title=(description or 'Report')[:60],
                description=description, reported_severity=severity, victims_count=victims,
                status=status_value, latitude=lat, longitude=lng,
                location=Point(lng, lat, srid=4326),
                source='mobile', submission_method=method, cluster=cluster,
            )
            cluster.source_reports.add(report)
            return report

        # Cluster E -- road closure
        make_report(
            ahmed, 'accident', 'إغلاق الطريق بسبب حادث مروري كبير', 2, 0,
            cluster_e.center_latitude, cluster_e.center_longitude, 'form', 'received', cluster_e,
        )
        make_report(
            sara, 'accident', 'Road completely blocked need help', 2, 0,
            cluster_e.center_latitude, cluster_e.center_longitude, 'witness', 'received', cluster_e,
        )

        # Cluster F -- crowd incident
        make_report(
            omar, 'security', 'تجمع كبير وأعمال شغب في المنطقة', 3, 2,
            cluster_f.center_latitude, cluster_f.center_longitude, 'form', 'assigned', cluster_f,
        )
        make_report(
            lina, 'security', 'Large crowd gathering turning violent', 3, 1,
            cluster_f.center_latitude, cluster_f.center_longitude, 'sos', 'assigned', cluster_f,
        )
        make_report(
            karim, 'security', 'حالة طوارئ في الشارع الرئيسي', 3, 3,
            cluster_f.center_latitude, cluster_f.center_longitude, 'witness', 'assigned', cluster_f,
        )

        # Cluster G -- weather / flooding
        make_report(
            ahmed, 'flood', 'فيضانات وأمطار غزيرة تغرق الشوارع', 2, 1,
            cluster_g.center_latitude, cluster_g.center_longitude, 'form', 'in_progress', cluster_g,
        )
        make_report(
            karim, 'flood', 'Severe flooding blocking evacuation', 2, 0,
            cluster_g.center_latitude, cluster_g.center_longitude, 'form', 'in_progress', cluster_g,
        )

        # Cluster H -- police / security incident
        make_report(
            sara, 'security', 'حادثة أمنية تتطلب تدخل الشرطة', 3, 2,
            cluster_h.center_latitude, cluster_h.center_longitude, 'form', 'closed', cluster_h,
        )
        make_report(
            omar, 'security', 'Security incident multiple injured', 3, 4,
            cluster_h.center_latitude, cluster_h.center_longitude, 'witness', 'closed', cluster_h,
        )
        make_report(
            lina, 'sos', 'إطلاق نار في المنطقة يرجى الإسراع', 4, 1,
            cluster_h.center_latitude, cluster_h.center_longitude, 'sos', 'closed', cluster_h,
        )

    # ------------------------------------------------------------------
    # STEP 7
    # ------------------------------------------------------------------
    def _seed_witness_reports(self, omar, karim, ahmed, cluster_a, cluster_c, cluster_d):
        def make_witness(user, cluster, lat, lng):
            WitnessReport.objects.create(
                user=user, cluster=cluster, latitude=lat, longitude=lng, photo_url=None,
                witness_name=user.full_name or user.email, contact_info=user.phone or user.email or '',
                statement='Witnessed the incident firsthand.',
            )

        make_witness(omar, cluster_a, 33.5136, 36.2762)
        make_witness(karim, cluster_c, 33.5064, 36.2644)
        make_witness(ahmed, cluster_d, 33.5309, 36.3009)

    # ------------------------------------------------------------------
    # STEP 8
    # ------------------------------------------------------------------
    def _seed_credibility_scores(self, cluster_a, cluster_b, cluster_c, cluster_d):
        def make_credibility(cluster, score_percent, score_level, ai_was_correct=None):
            AICredibilityScore.objects.create(
                incident=cluster, score_percent=score_percent, score_level=score_level,
                feature_inputs={}, ai_was_correct=ai_was_correct, model_version='seed-demo',
            )

        for score in (82.5, 78.0, 85.5):
            make_credibility(cluster_a, score, 'green')
        for score in (62.0, 58.5):
            make_credibility(cluster_b, score, 'yellow')
        for score in (79.5, 83.0):
            make_credibility(cluster_c, score, 'green')
        for score in (88.0, 91.5, 85.0):
            make_credibility(cluster_d, score, 'green', ai_was_correct=True)

    def _seed_extra_credibility_scores(self, cluster_e, cluster_f, cluster_g, cluster_h):
        AICredibilityScore.objects.create(
            incident=cluster_e, score_percent=71.0, score_level='green',
            feature_inputs={}, model_version='seed-demo',
        )
        AICredibilityScore.objects.create(
            incident=cluster_f, score_percent=84.0, score_level='green',
            feature_inputs={}, model_version='seed-demo',
        )
        AICredibilityScore.objects.create(
            incident=cluster_g, score_percent=58.0, score_level='yellow',
            feature_inputs={}, model_version='seed-demo',
        )
        AICredibilityScore.objects.create(
            incident=cluster_h, score_percent=89.0, score_level='green', ai_was_correct=True,
            feature_inputs={}, model_version='seed-demo',
        )

    # ------------------------------------------------------------------
    # STEP 9
    # ------------------------------------------------------------------
    def _seed_severity_predictions(self, cluster_a, cluster_b, cluster_c, cluster_d):
        def make_prediction(cluster, level, p_low, p_med, p_high, p_crit):
            AISeverityPrediction.objects.create(
                incident=cluster, predicted_level=SEVERITY_LEVEL_NAMES[level],
                probability_low=p_low, probability_medium=p_med,
                probability_high=p_high, probability_critical=p_crit,
                model_version='seed-demo',
            )

        make_prediction(cluster_a, 4, 0.02, 0.08, 0.25, 0.65)
        make_prediction(cluster_b, 3, 0.05, 0.15, 0.58, 0.22)
        make_prediction(cluster_c, 3, 0.05, 0.17, 0.60, 0.18)
        make_prediction(cluster_d, 4, 0.02, 0.06, 0.20, 0.72)

    def _seed_extra_severity_predictions(self, cluster_e, cluster_f, cluster_g, cluster_h):
        def make_prediction(cluster, level, p_low, p_med, p_high, p_crit):
            AISeverityPrediction.objects.create(
                incident=cluster, predicted_level=SEVERITY_LEVEL_NAMES[level],
                probability_low=p_low, probability_medium=p_med,
                probability_high=p_high, probability_critical=p_crit,
                model_version='seed-demo',
            )

        make_prediction(cluster_e, 2, 0.12, 0.60, 0.25, 0.03)
        make_prediction(cluster_f, 3, 0.04, 0.13, 0.55, 0.28)
        make_prediction(cluster_g, 2, 0.12, 0.65, 0.20, 0.03)
        make_prediction(cluster_h, 3, 0.04, 0.14, 0.62, 0.20)

    # ------------------------------------------------------------------
    # STEP 10
    # ------------------------------------------------------------------
    def _seed_assignments(self, cluster_a, cluster_b, cluster_c, cluster_d, units, operator1_account, operator2_account, now):
        assignment_a = ResourceAssignment.objects.create(
            cluster=cluster_a, unit=units['AMB-01'], status='suggested',
            priority_score=87.5, eta_minutes=7,
            justification=(
                'Nearest available ambulance, predicted severity Critical, '
                '12 victims reported, credibility 82%'
            ),
        )
        assignment_b = ResourceAssignment.objects.create(
            cluster=cluster_b, unit=units['AMB-02'], status='confirmed',
            priority_score=79.2, eta_minutes=9,
            confirmed_by=operator1_account, confirmed_at=now - timedelta(minutes=30),
            justification=(
                'Nearest available ambulance, predicted severity High, '
                '4 victims reported, credibility 62%'
            ),
        )
        assignment_c = ResourceAssignment.objects.create(
            cluster=cluster_c, unit=units['RESCUE-01'], status='dispatched',
            priority_score=83.1, eta_minutes=5,
            confirmed_by=operator2_account, confirmed_at=now - timedelta(hours=2),
            justification=(
                'Only available rescue team, predicted severity High, '
                '8 victims reported, credibility 81%'
            ),
        )
        assignment_d = ResourceAssignment.objects.create(
            cluster=cluster_d, unit=units['AMB-RC-01'], status='completed',
            priority_score=91.0, eta_minutes=7,
            confirmed_by=operator1_account, confirmed_at=now - timedelta(hours=5),
            completed_at=now - timedelta(hours=3),
            justification=(
                'Nearest available ambulance, predicted severity Critical, '
                '24 victims reported, credibility 88%'
            ),
        )
        return assignment_a, assignment_b, assignment_c, assignment_d

    def _seed_extra_assignments(self, cluster_e, cluster_f, cluster_g, cluster_h, units, operator1_account, operator2_account, now):
        assignment_e = ResourceAssignment.objects.create(
            cluster=cluster_e, unit=units['POLICE-01'], status='suggested',
            priority_score=72.3, eta_minutes=round(5.2),
            justification=(
                'Nearest available rescue team, predicted severity Medium, '
                '4 victims reported, credibility 71%'
            ),
        )
        # NOTE: the spec's example used RESCUE-01 here too, but RESCUE-01 is
        # already dispatched to cluster C (also currently active/in_progress) --
        # a unit can't be actively responding to two incidents at once, so this
        # uses POLICE-02 instead (a same-type rescue_team unit, freed up after
        # completing cluster H) to keep FieldUnit.status truthful.
        assignment_f = ResourceAssignment.objects.create(
            cluster=cluster_f, unit=units['POLICE-02'], status='confirmed',
            priority_score=81.5, eta_minutes=round(7.8),
            confirmed_by=operator2_account, confirmed_at=now - timedelta(minutes=20),
            justification=(
                'Nearest available rescue team, predicted severity High, '
                '10 victims reported, credibility 84%'
            ),
        )
        assignment_g = ResourceAssignment.objects.create(
            cluster=cluster_g, unit=units['AMB-RC-01'], status='dispatched',
            priority_score=68.9, eta_minutes=round(11.2),
            confirmed_by=operator1_account, confirmed_at=now - timedelta(hours=3),
            justification=(
                'Only available ambulance, predicted severity Medium, '
                '3 victims reported, credibility 58%'
            ),
        )
        assignment_h = ResourceAssignment.objects.create(
            cluster=cluster_h, unit=units['POLICE-02'], status='completed',
            priority_score=77.4, eta_minutes=round(6.1),
            confirmed_by=operator1_account, confirmed_at=now - timedelta(hours=7),
            completed_at=now - timedelta(hours=5),
            justification=(
                'Nearest available rescue team, predicted severity High, '
                '7 victims reported, credibility 89%'
            ),
        )
        return assignment_e, assignment_f, assignment_g, assignment_h

    # ------------------------------------------------------------------
    # STEP 11
    # ------------------------------------------------------------------
    def _seed_status_updates(self, cluster_a, cluster_b, cluster_c, cluster_d, operator1_account, operator2_account, now):
        StatusUpdate.objects.create(
            incident=cluster_a, old_status='active', new_status='active',
            updated_by=operator1_account, note='Monitoring incoming reports',
            updated_at=now - timedelta(hours=1, minutes=30),
        )

        StatusUpdate.objects.create(
            incident=cluster_b, old_status='active', new_status='assigned',
            updated_by=operator1_account, note='Unit AMB-02 confirmed',
            updated_at=now - timedelta(minutes=35),
        )
        StatusUpdate.objects.create(
            incident=cluster_b, old_status='assigned', new_status='assigned',
            updated_by=operator1_account, note='Unit en route confirmed',
            updated_at=now - timedelta(minutes=25),
        )

        StatusUpdate.objects.create(
            incident=cluster_c, old_status='active', new_status='assigned',
            updated_by=operator2_account, note='RESCUE-01 dispatched',
            updated_at=now - timedelta(hours=2, minutes=45),
        )
        StatusUpdate.objects.create(
            incident=cluster_c, old_status='assigned', new_status='in_progress',
            updated_by=operator2_account, note='Unit on scene',
            updated_at=now - timedelta(hours=2),
        )

        StatusUpdate.objects.create(
            incident=cluster_d, old_status='active', new_status='assigned',
            updated_by=operator1_account, note='',
            updated_at=now - timedelta(hours=5, minutes=30),
        )
        StatusUpdate.objects.create(
            incident=cluster_d, old_status='assigned', new_status='in_progress',
            updated_by=operator1_account, note='',
            updated_at=now - timedelta(hours=5),
        )
        StatusUpdate.objects.create(
            incident=cluster_d, old_status='in_progress', new_status='closed',
            updated_by=operator1_account, note='All victims evacuated',
            updated_at=now - timedelta(hours=3),
        )

    def _seed_extra_status_updates(self, cluster_e, cluster_f, cluster_g, cluster_h, operator1_account, operator2_account, now):
        StatusUpdate.objects.create(
            incident=cluster_e, old_status='active', new_status='active',
            updated_by=operator1_account, note='Monitoring situation',
            updated_at=now - timedelta(minutes=45),
        )

        StatusUpdate.objects.create(
            incident=cluster_f, old_status='active', new_status='assigned',
            updated_by=operator2_account, note='RESCUE-01 confirmed on route',
            updated_at=now - timedelta(minutes=20),
        )

        StatusUpdate.objects.create(
            incident=cluster_g, old_status='active', new_status='assigned',
            updated_by=operator1_account, note='',
            updated_at=now - timedelta(hours=3, minutes=30),
        )
        StatusUpdate.objects.create(
            incident=cluster_g, old_status='assigned', new_status='in_progress',
            updated_by=operator1_account, note='Unit arrived at scene',
            updated_at=now - timedelta(hours=3),
        )

        StatusUpdate.objects.create(
            incident=cluster_h, old_status='active', new_status='assigned',
            updated_by=operator1_account, note='',
            updated_at=now - timedelta(hours=7),
        )
        StatusUpdate.objects.create(
            incident=cluster_h, old_status='assigned', new_status='in_progress',
            updated_by=operator1_account, note='',
            updated_at=now - timedelta(hours=6, minutes=30),
        )
        StatusUpdate.objects.create(
            incident=cluster_h, old_status='in_progress', new_status='closed',
            updated_by=operator1_account, note='Incident resolved safely',
            updated_at=now - timedelta(hours=5),
        )

    # ------------------------------------------------------------------
    # STEP 12
    # ------------------------------------------------------------------
    def _seed_report_summary(self, cluster_d):
        IncidentReportSummary.objects.create(
            incident=cluster_d, citizen_reported_severity=3, ai_predicted_severity=4,
            actual_severity=4, response_time_minutes=18.5, citizen_rating=4,
            total_reports=12, total_witnesses=5, false_report=False,
        )

    def _seed_extra_report_summary(self, cluster_h, now):
        IncidentReportSummary.objects.create(
            incident=cluster_h, citizen_reported_severity=2, ai_predicted_severity=3,
            actual_severity=3, response_time_minutes=14.2, citizen_rating=4,
            total_reports=7, total_witnesses=3, false_report=False,
        )

    # ------------------------------------------------------------------
    # STEP 13
    # ------------------------------------------------------------------
    def _seed_notifications(self, ahmed, sara, lina, now):
        def make_notification(recipient, ntype, title, message, is_read, created_at,
                               is_broadcast=False, target_lat=None, target_lng=None, target_radius=None):
            notif = Notification.objects.create(
                recipient=recipient, notification_type=ntype, title=title, message=message,
                is_read=is_read, is_broadcast=is_broadcast,
                target_latitude=target_lat, target_longitude=target_lng, target_radius_km=target_radius,
            )
            Notification.objects.filter(pk=notif.pk).update(created_at=created_at)
            return notif

        make_notification(
            ahmed, 'sos_confirm', 'SOS Alert Sent',
            'Your SOS has been received. Emergency contacts notified.',
            True, now - timedelta(hours=2),
        )
        make_notification(
            ahmed, 'report_status', 'Report Update',
            'Your report has been assigned to unit AMB-01',
            False, now - timedelta(hours=1),
        )

        make_notification(
            sara, 'danger_zone', 'Danger Zone Active',
            'تحذير: ابتعد عن منطقة السوق القديم بسبب حريق كبير',
            False, now - timedelta(hours=1, minutes=30),
        )
        make_notification(
            sara, 'report_status', 'تحديث البلاغ',
            'تم إغلاق الحادثة بنجاح',
            True, now - timedelta(hours=3),
        )

        make_notification(
            lina, 'general', 'Report Received',
            'Your report has been received and is being processed',
            True, now - timedelta(minutes=45),
        )
        make_notification(
            lina, 'report_status', 'Report Update',
            'Your report status changed to Assigned',
            False, now - timedelta(minutes=30),
        )

        broadcast_fire = make_notification(
            None, 'danger_zone', 'Fire Alert — Old Market',
            'حريق كبير في السوق القديم يرجى تجنب المنطقة',
            False, now - timedelta(hours=1, minutes=45),
            is_broadcast=True, target_lat=33.5138, target_lng=36.2765, target_radius=2.0,
        )
        make_notification(
            None, 'road_closure', 'Road Closure',
            'إغلاق شارع بغداد بسبب عمليات الإنقاذ',
            False, now - timedelta(hours=2, minutes=30),
            is_broadcast=True, target_lat=33.5060, target_lng=36.2640, target_radius=1.0,
        )

        return broadcast_fire

    def _seed_extra_notifications(self, ahmed, sara, omar, now):
        def make_notification(recipient, ntype, title, message, is_read, created_at,
                               is_broadcast=False, target_lat=None, target_lng=None, target_radius=None):
            notif = Notification.objects.create(
                recipient=recipient, notification_type=ntype, title=title, message=message,
                is_read=is_read, is_broadcast=is_broadcast,
                target_latitude=target_lat, target_longitude=target_lng, target_radius_km=target_radius,
            )
            Notification.objects.filter(pk=notif.pk).update(created_at=created_at)
            return notif

        make_notification(
            ahmed, 'danger_zone', 'تحذير منطقة خطرة',
            'ابتعد عن منطقة الشارع الرئيسي بسبب أعمال الشغب',
            False, now - timedelta(minutes=30),
        )
        make_notification(
            ahmed, 'report_status', 'تحديث البلاغ',
            'تم تعيين وحدة لبلاغك وسيصل المساعدة خلال 8 دقائق',
            False, now - timedelta(minutes=25),
        )

        make_notification(
            sara, 'road_closure', 'Road Closure Alert',
            'Baghdad Street closed due to emergency operations',
            False, now - timedelta(hours=1),
        )

        make_notification(
            omar, 'general', 'Safety Update',
            'Situation in sector 3 is under control',
            True, now - timedelta(hours=2),
        )

        broadcast_security = make_notification(
            None, 'danger_zone', 'تحذير أمني عام',
            'تجنب منطقة باب توما بسبب حادثة أمنية جارية',
            False, now - timedelta(minutes=30),
            is_broadcast=True, target_lat=33.5138, target_lng=36.2765, target_radius=3.0,
        )
        broadcast_flood = make_notification(
            None, 'road_closure', 'Multiple Road Closures',
            'Several main roads closed due to flooding. Use alternative routes',
            False, now - timedelta(hours=4),
            is_broadcast=True, target_lat=33.4980, target_lng=36.3100, target_radius=5.0,
        )

        return broadcast_security, broadcast_flood

    # ------------------------------------------------------------------
    # STEP 14
    # ------------------------------------------------------------------
    def _seed_audit_logs(self, admin_account, operator1_account, operator2_account,
                            assignment_c, assignment_d, cluster_d, ahmed, broadcast_fire, now):
        def make_audit(actor_email, actor_type, action, resource_type, resource_id, created_at, note=''):
            log = AuditLog.objects.create(
                actor_email=actor_email, actor_type=actor_type, action=action,
                resource_type=resource_type, resource_id=str(resource_id), note=note,
                ip_address='127.0.0.1',
            )
            AuditLog.objects.filter(pk=log.pk).update(created_at=created_at)

        make_audit(
            'admin@cmers.com', 'official', 'official_login', 'official_account', admin_account.id,
            now - timedelta(hours=6),
        )
        make_audit(
            'operator1@cmers.com', 'official', 'official_login', 'official_account', operator1_account.id,
            now - timedelta(hours=5, minutes=45),
        )
        make_audit(
            'operator1@cmers.com', 'official', 'dispatch_confirmed', 'assignment', assignment_d.id,
            now - timedelta(hours=5), note='AMB-RC-01 dispatched to collapse',
        )
        make_audit(
            'operator2@cmers.com', 'official', 'official_login', 'official_account', operator2_account.id,
            now - timedelta(hours=3),
        )
        make_audit(
            'operator2@cmers.com', 'official', 'dispatch_confirmed', 'assignment', assignment_c.id,
            now - timedelta(hours=2, minutes=45), note='RESCUE-01 dispatched to rescue',
        )
        make_audit(
            'operator1@cmers.com', 'official', 'incident_closed', 'cluster', cluster_d.id,
            now - timedelta(hours=3), note='All victims evacuated. Actual severity 4',
        )
        make_audit(
            'operator1@cmers.com', 'official', 'medical_card_accessed', 'medical_profile', ahmed.id,
            now - timedelta(hours=2, minutes=30), note='Accessed during active medical incident',
        )
        make_audit(
            'operator2@cmers.com', 'official', 'broadcast_sent', 'notification', broadcast_fire.id,
            now - timedelta(hours=1, minutes=45), note='Fire alert broadcast to 2km radius',
        )

    def _seed_extra_audit_logs(self, admin_account, operator1_account, operator2_account,
                                 assignment_f, assignment_g, cluster_h, broadcast_security, broadcast_flood, now):
        def make_audit(actor_email, actor_type, action, resource_type, resource_id, created_at, note=''):
            log = AuditLog.objects.create(
                actor_email=actor_email, actor_type=actor_type, action=action,
                resource_type=resource_type, resource_id=str(resource_id), note=note,
                ip_address='127.0.0.1',
            )
            AuditLog.objects.filter(pk=log.pk).update(created_at=created_at)

        make_audit(
            'operator1@cmers.com', 'official', 'official_login', 'official_account', operator1_account.id,
            now - timedelta(hours=11),
        )
        make_audit(
            'operator2@cmers.com', 'official', 'official_login', 'official_account', operator2_account.id,
            now - timedelta(hours=9),
        )
        make_audit(
            'admin@cmers.com', 'official', 'official_login', 'official_account', admin_account.id,
            now - timedelta(hours=8),
        )
        make_audit(
            'operator1@cmers.com', 'official', 'incident_closed', 'cluster', cluster_h.id,
            now - timedelta(hours=5), note='Incident resolved safely. Actual severity 3',
        )
        make_audit(
            'operator2@cmers.com', 'official', 'dispatch_confirmed', 'assignment', assignment_f.id,
            now - timedelta(minutes=20), note='RESCUE-01 confirmed for crowd incident',
        )
        make_audit(
            'operator1@cmers.com', 'official', 'dispatch_confirmed', 'assignment', assignment_g.id,
            now - timedelta(hours=3), note='AMB-RC-01 dispatched to flooding',
        )
        make_audit(
            'operator1@cmers.com', 'official', 'broadcast_sent', 'notification', broadcast_security.id,
            now - timedelta(minutes=30), note='Security alert broadcast to 3km radius',
        )
        make_audit(
            'operator2@cmers.com', 'official', 'broadcast_sent', 'notification', broadcast_flood.id,
            now - timedelta(hours=4), note='Flooding alert broadcast to 5km radius',
        )

    # ------------------------------------------------------------------
    def _print_summary(self):
        self.stdout.write('')
        self.stdout.write('=== SEED DATA COMPLETE ===')
        self.stdout.write(f'Organizations: {Organization.objects.count()}')
        self.stdout.write(f'Official accounts: {OfficialAccount.objects.count()}')
        self.stdout.write(f'Field units: {FieldUnit.objects.count()}')
        self.stdout.write(f'Citizens: {User.objects.filter(is_staff=False, is_superuser=False).count()}')
        self.stdout.write(f'Clusters: {IncidentCluster.objects.count()}')
        self.stdout.write(f'Reports: {Report.objects.count()}')
        self.stdout.write(f'Assignments: {ResourceAssignment.objects.count()}')
        self.stdout.write(f'Notifications: {Notification.objects.count()}')
        self.stdout.write(f'Audit logs: {AuditLog.objects.count()}')
        self.stdout.write('Demo data ready.')
