import 'package:latlong2/latlong.dart';

/// مركز إيواء (متطلب 4.6): يُعرض على خريطة المواطنين لمعرفة أماكن الإيواء.
class ShelterModel {
  final String id;
  final String name;
  final LatLng position;
  final String? capacity;
  final String? phone;

  const ShelterModel({
    required this.id,
    required this.name,
    required this.position,
    this.capacity,
    this.phone,
  });

  /// يبني مركز إيواء من استجابة GET /shelters.
  factory ShelterModel.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map? ?? json['location'] as Map? ?? {};
    return ShelterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: LatLng(
        ((position['lat'] ?? position['latitude']) as num).toDouble(),
        ((position['lng'] ?? position['longitude']) as num).toDouble(),
      ),
      capacity: json['capacity']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  /// يحوّل مركز الإيواء إلى JSON (للكاش المحلي — متطلب 4.9).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': {'lat': position.latitude, 'lng': position.longitude},
        'capacity': capacity,
        'phone': phone,
      };
}