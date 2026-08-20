import 'package:latlong2/latlong.dart';

/// نقطة تجمع آمنة (متطلب 4.6): مكان تجمع المدنيين بعيداً عن الخطر.
class SafePointModel {
  final String id;
  final String name;
  final LatLng position;
  final String? description;

  const SafePointModel({
    required this.id,
    required this.name,
    required this.position,
    this.description,
  });

  /// يبني نقطة تجمع من استجابة GET /safe-points.
  factory SafePointModel.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map? ?? json['location'] as Map? ?? {};
    return SafePointModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: LatLng(
        ((position['lat'] ?? position['latitude']) as num).toDouble(),
        ((position['lng'] ?? position['longitude']) as num).toDouble(),
      ),
      description: json['description']?.toString(),
    );
  }

  /// يحوّل نقطة التجمع إلى JSON (للكاش المحلي — متطلب 4.9).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': {'lat': position.latitude, 'lng': position.longitude},
        'description': description,
      };
}