import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nidaa_app/models/report_model.dart';

void main() {
  group('ReportModel.fromJson', () {
    test('يقرأ كل الحقول الأساسية من استجابة الخادم', () {
      final json = {
        'id': 42,
        'title': 'حريق في حي المزة',
        'location': 'دمشق — المزة',
        'status': 'under_review',
        'category': 'fire',
        'severity': 'critical',
        'timeAgo': 'قبل 3 دقائق',
        'created_at': '2026-08-17T10:30:00Z',
        'description': 'دخان كثيف',
        'imagePath': '/tmp/a.png',
        'progressValue': 75,
        'latitude': 33.51,
        'longitude': 36.29,
        'victimsCount': 2,
        'respondingAgency': 'الدفاع المدني',
        'etaMinutes': 8,
        'credibilityScore': 92.5,
        'isWitness': true,
      };

      final report = ReportModel.fromJson(json);

      expect(report.id, '42');
      expect(report.title, 'حريق في حي المزة');
      expect(report.status, ReportStatus.processing);
      expect(report.category, ReportCategory.fire);
      expect(report.severity, SeverityLevel.critical);
      expect(report.createdAt, isNotNull);
      expect(report.description, 'دخان كثيف');
      expect(report.progressValue, 75);
      expect(report.position, const LatLng(33.51, 36.29));
      expect(report.victimsCount, 2);
      expect(report.respondingAgency, 'الدفاع المدني');
      expect(report.etaMinutes, 8);
      expect(report.credibilityScore, 92.5);
      expect(report.isWitness, isTrue);
    });

    test('يقع على القيم الافتراضية عند غياب الحقول', () {
      final report = ReportModel.fromJson({'id': '1'});

      expect(report.title, '');
      expect(report.status, ReportStatus.processing);
      expect(report.category, ReportCategory.fire);
      expect(report.severity, SeverityLevel.medium);
      expect(report.timeAgo, 'الآن');
      expect(report.position, isNull);
      expect(report.isWitness, isFalse);
    });

    test('يقرأ نوع الكارثة الطبيعية بصيغتيه camelCase و snake_case', () {
      expect(
        ReportModel.fromJson({'category': 'natural_disaster'}).category,
        ReportCategory.naturalDisaster,
      );
      expect(
        ReportModel.fromJson({'category': 'naturalDisaster'}).category,
        ReportCategory.naturalDisaster,
      );
    });

    test('displayTimeAgo يستخدم timeAgo عند غياب created_at', () {
      final report =
          ReportModel.fromJson({'id': '1', 'timeAgo': 'قبل 5 دقائق'});
      expect(report.displayTimeAgo, 'قبل 5 دقائق');
    });

    test('يربط حالات الخادم (snake_case) بحالات العرض', () {
      final cases = <String, ReportStatus>{
        'received': ReportStatus.processing,
        'under_review': ReportStatus.processing,
        'pending_transcription': ReportStatus.processing,
        'assigned': ReportStatus.processing,
        'in_progress': ReportStatus.processing,
        'resolved': ReportStatus.closed,
        'rejected': ReportStatus.closed,
        'closed': ReportStatus.closed,
      };
      cases.forEach((backendValue, expected) {
        expect(
          ReportModel.fromJson({'id': '1', 'status': backendValue}).status,
          expected,
          reason: 'الحالة $backendValue',
        );
      });
    });

    test('التقدم الافتراضي يُشتق من الحالة عند غياب قيمته', () {
      expect(
        ReportModel.fromJson({'id': '1', 'status': 'closed'}).progressValue,
        1.0,
      );
      expect(
        ReportModel.fromJson(
                {'id': '1', 'status': 'under_review'})
            .progressValue,
        0.55,
      );
      expect(
        ReportModel.fromJson({'id': '1', 'progressValue': 75}).progressValue,
        75,
      );
    });

    test('المُلصقات العربية سليمة للأنواع والخطورة والحالة', () {
      final report = ReportModel.fromJson({
        'id': '1',
        'status': 'closed',
        'category': 'building_collapse',
        'severity': 'high',
      });
      expect(report.statusLabel, 'مغلق');
      expect(report.categoryLabel, 'انهيار مبنى');
      expect(report.severityLabel, 'مرتفع');
    });
  });
}