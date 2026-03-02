import 'localized_text.dart';

class Branch {
  final int id;
  final LocalizedText name;
  final LocalizedText? address;
  final String? phone;
  final bool isActive;
  final int displayOrder;

  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.isActive,
    required this.displayOrder,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      name: LocalizedText.parse(json['name']),
      address: LocalizedText.parseNullable(json['address']),
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }
}
