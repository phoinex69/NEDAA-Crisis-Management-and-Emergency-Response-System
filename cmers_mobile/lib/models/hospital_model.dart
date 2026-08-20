import 'package:latlong2/latlong.dart';

class HospitalModel {
  final String id;
  final String name;
  final LatLng position;
  final String? phone;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.position,
    this.phone,
  });

  /// يبني مستشفى من استجابة GET /hospitals.
  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    final pos = json['position'];
    return HospitalModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: pos is Map
          ? LatLng(
              (pos['lat'] as num).toDouble(),
              (pos['lng'] as num).toDouble(),
            )
          : const LatLng(0, 0),
      phone: json['phone']?.toString(),
    );
  }

  /// يحوّل المستشفى إلى JSON (للكاش المحلي — متطلب 4.9).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': {'lat': position.latitude, 'lng': position.longitude},
        'phone': phone,
      };
}