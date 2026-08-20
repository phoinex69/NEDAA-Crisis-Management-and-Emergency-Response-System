/// تنبيه فوري للمواطنين (متطلب 4.5): تحذيرات الطقس والكوارث الطبيعية،
/// إغلاق الطرق أو المناطق، تعليمات السلامة والإخلاء.
class AlertModel {
  final String id;
  final String title;

  /// نوع التنبيه: weather / disaster / road / safety / other.
  final String type;
  final String message;
  final String? severity;
  final DateTime? createdAt;

  const AlertModel({
    required this.id,
    required this.title,
    required this.type,
    required this.message,
    this.severity,
    this.createdAt,
  });

  /// يبني تنبيهاً من استجابة GET /alerts.
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      message: json['message']?.toString() ?? '',
      severity: json['severity']?.toString(),
      createdAt: DateTime.tryParse(
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? ''),
    );
  }
}