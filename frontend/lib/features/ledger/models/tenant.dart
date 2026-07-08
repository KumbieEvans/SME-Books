class Tenant {
  final String id;
  final String companyName;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.companyName,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
