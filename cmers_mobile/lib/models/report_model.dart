import 'package:latlong2/latlong.dart';

import '../core/utils/time_ago.dart';

enum ReportStatus { received, underReview, assigned, inProgress, closed }

/// ربط حالة الخادم (snake_case) بحالة العرض — كل حالة خادم فعلية لها
/// حالة عرض مطابقة، بدل تجميعها كلها تحت "قيد المعالجة" (مطابق لترجمة
/// [BackendDataSource] — مسار وحيد للقيم).
ReportStatus reportStatusFromApi(String? value) {
  switch (value) {
    case 'resolved':
    case 'rejected':
    case 'closed':
      return ReportStatus.closed;
    case 'assigned':
      return ReportStatus.assigned;
    case 'in_progress':
      return ReportStatus.inProgress;
    case 'under_review':
      return ReportStatus.underReview;
    case 'received':
    case 'pending_transcription':
    default:
      return ReportStatus.received;
  }
}

/// نسبة التقدم المُشتقة من الحالة — تُعرض في شاشة التتبع
/// عند غياب قيمة صريحة من الخادم.
double reportProgressForStatus(ReportStatus status) {
  switch (status) {
    case ReportStatus.received:
      return 0.15;
    case ReportStatus.underReview:
      return 0.35;
    case ReportStatus.assigned:
      return 0.6;
    case ReportStatus.inProgress:
      return 0.8;
    case ReportStatus.closed:
      return 1.0;
  }
}

/// أنواع الطوارئ السبعة المطلوبة في وثيقة المتطلبات (4.2):
/// إسعاف / حريق / شرطة / إنقاذ / كارثة طبيعية / انهيار مبنى / ازدحام أو إغلاق طرق.
enum ReportCategory {
  ambulance,
  fire,
  police,
  rescue,
  naturalDisaster,
  buildingCollapse,
  roadClosure,
  other;

  /// الاسم المُرسل للـ Backend (camelCase).
  String get apiValue {
    switch (this) {
      case ReportCategory.ambulance:
        return 'ambulance';
      case ReportCategory.fire:
        return 'fire';
      case ReportCategory.police:
        return 'police';
      case ReportCategory.rescue:
        return 'rescue';
      case ReportCategory.naturalDisaster:
        return 'natural_disaster';
      case ReportCategory.buildingCollapse:
        return 'building_collapse';
      case ReportCategory.roadClosure:
        return 'road_closure';
      case ReportCategory.other:
        return 'other';
    }
  }

  static ReportCategory fromApiValue(String? value) {
    switch (value) {
      case 'ambulance':
        return ReportCategory.ambulance;
      case 'fire':
        return ReportCategory.fire;
      case 'police':
        return ReportCategory.police;
      case 'rescue':
        return ReportCategory.rescue;
      case 'natural_disaster':
      case 'naturalDisaster':
        return ReportCategory.naturalDisaster;
      case 'building_collapse':
      case 'buildingCollapse':
        return ReportCategory.buildingCollapse;
      case 'road_closure':
      case 'roadClosure':
        return ReportCategory.roadClosure;
      case 'other':
        return ReportCategory.other;
      default:
        return ReportCategory.fire;
    }
  }

  String get categoryLabel {
    switch (this) {
      case ReportCategory.ambulance:
        return 'إسعاف';
      case ReportCategory.fire:
        return 'حريق';
      case ReportCategory.police:
        return 'شرطة';
      case ReportCategory.rescue:
        return 'إنقاذ';
      case ReportCategory.naturalDisaster:
        return 'كارثة طبيعية';
      case ReportCategory.buildingCollapse:
        return 'انهيار مبنى';
      case ReportCategory.roadClosure:
        return 'ازدحام أو إغلاق طرق';
      case ReportCategory.other:
        return 'أخرى';
    }
  }
}

/// مستويات الخطورة الأربعة المطلوبة (4.2): حرج / مرتفع / متوسط / منخفض.
enum SeverityLevel { critical, high, medium, low }

class ReportModel {
  final String id;
  final String title;
  final String location;
  final ReportStatus status;
  final ReportCategory category;
  final SeverityLevel severity;
  final String timeAgo;
  final DateTime? createdAt;
  final String? description;
  final String? imagePath;
  final String? audioPath;
  final double? progressValue;
  final LatLng? position;

  /// عدد المصابين أو المتضررين تقريبياً (اختياري).
  final int? victimsCount;

  /// الجهة المستجيبة للحادث (مثال: الدفاع المدني، الإسعاف...).
  final String? respondingAgency;

  /// الزمن المتوقع لوصول فرق الإنقاذ بالدقائق.
  final int? etaMinutes;

  /// درجة مصداقية البلاغ من نموذج 6.1-B (0-100).
  final double? credibilityScore;

  /// هل أُرسل هذا البلاغ بوضع الشاهد (Witness Mode)؟
  final bool isWitness;

  ReportModel({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.category,
    required this.severity,
    required this.timeAgo,
    this.createdAt,
    this.description,
    this.imagePath,
    this.audioPath,
    this.progressValue,
    this.position,
    this.victimsCount,
    this.respondingAgency,
    this.etaMinutes,
    this.credibilityScore,
    this.isWitness = false,
  });

  /// النص النسبي للوقت: يُحسب من [createdAt] محلياً،
  /// أو يُؤخذ من الخادم (timeAgo) إن لم يتوفر التاريخ.
  String get displayTimeAgo {
    final created = createdAt;
    if (created == null) return timeAgo;
    return timeAgoFrom(created);
  }

  String get statusLabel {
    switch (status) {
      case ReportStatus.received:
        return 'تم الاستلام';
      case ReportStatus.underReview:
        return 'قيد المراجعة';
      case ReportStatus.assigned:
        return 'تم تعيين وحدة';
      case ReportStatus.inProgress:
        return 'الوحدة في الطريق';
      case ReportStatus.closed:
        return 'مغلق';
    }
  }

  String get categoryLabel => category.categoryLabel;

  String get severityLabel {
    switch (severity) {
      case SeverityLevel.critical:
        return 'حرج';
      case SeverityLevel.high:
        return 'مرتفع';
      case SeverityLevel.medium:
        return 'متوسط';
      case SeverityLevel.low:
        return 'منخفض';
    }
  }

  ReportModel copyWith({
    String? id,
    String? title,
    String? location,
    ReportStatus? status,
    ReportCategory? category,
    SeverityLevel? severity,
    String? timeAgo,
    DateTime? createdAt,
    String? description,
    String? imagePath,
    String? audioPath,
    double? progressValue,
    LatLng? position,
    int? victimsCount,
    String? respondingAgency,
    int? etaMinutes,
    double? credibilityScore,
    bool? isWitness,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      status: status ?? this.status,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      progressValue: progressValue ?? this.progressValue,
      position: position ?? this.position,
      victimsCount: victimsCount ?? this.victimsCount,
      respondingAgency: respondingAgency ?? this.respondingAgency,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      credibilityScore: credibilityScore ?? this.credibilityScore,
      isWitness: isWitness ?? this.isWitness,
    );
  }

  /// يبني بلاغاً من استجابة الخادم (GET/POST /reports) أو حمولة WebSocket.
  /// يتسامح مع صيغتي الخادم snake_case وتطبيق NEDAA camelCase.
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lng = json['longitude'];
    final status = reportStatusFromApi(json['status']?.toString());
    return ReportModel(
      id: json['id']?.toString() ?? json['report_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: status,
      category: ReportCategory.fromApiValue(
          json['category']?.toString() ?? json['report_type']?.toString()),
      severity: SeverityLevel.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => SeverityLevel.medium,
      ),
      timeAgo: json['timeAgo']?.toString() ?? 'الآن',
      createdAt: DateTime.tryParse(
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? ''),
      description: json['description']?.toString(),
      imagePath: json['imagePath']?.toString(),
      audioPath: json['audioPath']?.toString(),
      progressValue: (json['progressValue'] as num?)?.toDouble() ??
          reportProgressForStatus(status),
      position: (lat != null && lng != null)
          ? LatLng((lat as num).toDouble(), (lng as num).toDouble())
          : null,
      victimsCount: (json['victimsCount'] as num?)?.toInt() ??
          (json['victims_count'] as num?)?.toInt(),
      respondingAgency: json['respondingAgency']?.toString() ??
          json['assigned_unit']?.toString(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ??
          (json['eta_minutes'] as num?)?.toInt(),
      credibilityScore: (json['credibilityScore'] as num?)?.toDouble(),
      isWitness: json['isWitness'] == true,
    );
  }
}