class EmergencyContactModel {
  final String id;
  final String name;
  final String relation;
  final String phone;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
  });

  /// يبني جهة اتصال من استجابة الخادم (GET/POST /contacts).
  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'phone': phone,
      };
}

class PublicEmergencyNumber {
  final String label;
  final String number;
  final String iconType;

  PublicEmergencyNumber({
    required this.label,
    required this.number,
    required this.iconType,
  });
}
