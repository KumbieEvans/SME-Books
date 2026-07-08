import 'package:decimal/decimal.dart';

class Tax {
  final String id;
  final String tenantId;
  final String name;
  final Decimal rate;
  final bool isActive;
  final DateTime createdAt;

  Tax({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.rate,
    required this.isActive,
    required this.createdAt,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      rate: Decimal.parse(json['rate'].toString()),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rate': rate.toString(),
      'is_active': isActive,
    };
  }
}
