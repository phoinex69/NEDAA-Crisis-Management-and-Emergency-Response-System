import 'package:latlong2/latlong.dart';

class DangerZoneModel {
  final String id;
  final String name;
  final List<LatLng> boundary;
  final String cause;
  final List<String> safetyInstructions;

  const DangerZoneModel({
    required this.id,
    required this.name,
    required this.boundary,
    required this.cause,
    required this.safetyInstructions,
  });

  LatLng get center {
    var lat = 0.0;
    var lng = 0.0;
    for (final point in boundary) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / boundary.length, lng / boundary.length);
  }

  /// يبني منطقة خطر من استجابة GET /zones.
  factory DangerZoneModel.fromJson(Map<String, dynamic> json) {
    return DangerZoneModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      boundary: (json['boundary'] as List? ?? [])
          .map((point) {
            final pair = point as List;
            return LatLng(
              (pair[0] as num).toDouble(),
              (pair[1] as num).toDouble(),
            );
          })
          .toList(),
      cause: json['cause']?.toString() ?? '',
      safetyInstructions:
          (json['safetyInstructions'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  /// يحوّل المنطقة إلى JSON (للكاش المحلي — متطلب 4.9).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'boundary': boundary
            .map((p) => [p.latitude, p.longitude])
            .toList(),
        'cause': cause,
        'safetyInstructions': safetyInstructions,
      };
}