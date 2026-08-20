class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// يبني مستخدماً من استجابة الخادم (verifyOtp / login / profile).
  /// الخادم (متطلب 4.1) يرسل الاسم الكامل في `full_name` عند الدخول بكلمة المرور.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'avatarUrl': avatarUrl,
      };
}
