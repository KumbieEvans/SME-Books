class Account {
  final String id;
  final String tenantId;
  final String accountNumber;
  final String name;
  final String type; // Asset, Liability, Equity, Revenue, Expense
  final DateTime createdAt;

  Account({
    required this.id,
    required this.tenantId,
    required this.accountNumber,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      accountNumber: json['account_number'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'account_number': accountNumber,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
