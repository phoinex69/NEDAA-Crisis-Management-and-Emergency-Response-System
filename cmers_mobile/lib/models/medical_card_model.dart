/// البطاقة الطبية الطارئة (متطلب 4.7) — معلومات طبية اختيارية تظهر
/// للمشغّل والمسعف فقط عند تفعيل بلاغ طبي (صلاحيات وصول مقيدة على الخادم).
class MedicalCardModel {
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final List<String> medications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const MedicalCardModel({
    this.bloodType,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.medications = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  bool get isEmpty =>
      bloodType == null &&
      allergies.isEmpty &&
      chronicDiseases.isEmpty &&
      medications.isEmpty &&
      emergencyContactName == null &&
      emergencyContactPhone == null;

  /// يبني بطاقة طبية من استجابة GET /medical-card.
  factory MedicalCardModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(Object? value) => (value as List? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    return MedicalCardModel(
      bloodType: json['bloodType']?.toString(),
      allergies: parseList(json['allergies']),
      chronicDiseases: parseList(json['chronicDiseases']),
      medications: parseList(json['medications']),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (bloodType != null) 'bloodType': bloodType,
        'allergies': allergies,
        'chronicDiseases': chronicDiseases,
        'medications': medications,
        if (emergencyContactName != null)
          'emergencyContactName': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergencyContactPhone': emergencyContactPhone,
      };
}