import 'package:latlong2/latlong.dart';

import 'report_model.dart';

/// حمولة بلاغ محفوظة محلياً بانتظار المزامنة عند عودة الاتصال (متطلب 4.9).
class PendingReportPayload {
  final ReportCategory category;
  final SeverityLevel severity;
  final String description;
  final int? victimsCount;
  final bool isWitness;

  /// مسار الصورة والملف الصوتي على القرص (قد يختفيا بعد إعادة التشغيل).
  final String? imagePath;
  final String? audioPath;
  final double? latitude;
  final double? longitude;

  const PendingReportPayload({
    required this.category,
    required this.severity,
    required this.description,
    this.victimsCount,
    this.isWitness = false,
    this.imagePath,
    this.audioPath,
    this.latitude,
    this.longitude,
  });

  factory PendingReportPayload.fromReport({
    required ReportCategory category,
    required SeverityLevel severity,
    required String description,
    int? victimsCount,
    bool isWitness = false,
    String? imagePath,
    String? audioPath,
    LatLng? position,
  }) {
    return PendingReportPayload(
      category: category,
      severity: severity,
      description: description,
      victimsCount: victimsCount,
      isWitness: isWitness,
      imagePath: imagePath,
      audioPath: audioPath,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
  }

  LatLng? get position =>
      (latitude != null && longitude != null)
          ? LatLng(latitude!, longitude!)
          : null;

  Map<String, dynamic> toJson() => {
        'category': category.apiValue,
        'severity': severity.name,
        'description': description,
        if (victimsCount != null) 'victimsCount': victimsCount,
        'isWitness': isWitness,
        if (imagePath != null) 'imagePath': imagePath,
        if (audioPath != null) 'audioPath': audioPath,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  factory PendingReportPayload.fromJson(Map<String, dynamic> json) {
    return PendingReportPayload(
      category: ReportCategory.fromApiValue(json['category']?.toString()),
      severity: SeverityLevel.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => SeverityLevel.medium,
      ),
      description: json['description']?.toString() ?? '',
      victimsCount: (json['victimsCount'] as num?)?.toInt(),
      isWitness: json['isWitness'] == true,
      imagePath: json['imagePath']?.toString(),
      audioPath: json['audioPath']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}