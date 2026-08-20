import 'package:latlong2/latlong.dart';

/// مركز خدمة (شرطة/دفاع مدني...) يعرض اسمه فقط على الخريطة،
/// ويُجلب من الـ Backend حسب موقع المستخدم.
class ServiceCenterModel {
  final String id;
  final String name;
  final LatLng position;

  const ServiceCenterModel({
    required this.id,
    required this.name,
    required this.position,
  });

  /// يبني مركزاً من استجابة GET /centers.
  factory ServiceCenterModel.fromJson(Map<String, dynamic> json) {
    final pos = json['position'];
    return ServiceCenterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: pos is Map
          ? LatLng(
              (pos['lat'] as num).toDouble(),
              (pos['lng'] as num).toDouble(),
            )
          : const LatLng(0, 0),
    );
  }

  /// يحوّل المركز إلى JSON (للكاش المحلي — متطلب 4.9).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': {'lat': position.latitude, 'lng': position.longitude},
      };
}