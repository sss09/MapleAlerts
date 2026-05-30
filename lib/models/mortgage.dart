class Mortgage {
  final String id;
  final String lender;
  final double amount;
  final DateTime renewalDate;
  final double interestRate;
  final String mortgageType; // 'fixed' or 'variable'
  final String notes;

  const Mortgage({
    required this.id,
    required this.lender,
    required this.amount,
    required this.renewalDate,
    required this.interestRate,
    required this.mortgageType,
    this.notes = '',
  });

  int get daysUntilRenewal => renewalDate.difference(DateTime.now()).inDays;

  bool get isExpired => DateTime.now().isAfter(renewalDate);

  factory Mortgage.fromMap(Map<String, dynamic> map) {
    return Mortgage(
      id: map['id'] as String,
      lender: map['lender'] as String,
      amount: (map['amount'] as num).toDouble(),
      renewalDate: DateTime.parse(map['renewalDate'] as String),
      interestRate: (map['interestRate'] as num).toDouble(),
      mortgageType: map['mortgageType'] as String? ?? 'fixed',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lender': lender,
      'amount': amount,
      'renewalDate': renewalDate.toIso8601String(),
      'interestRate': interestRate,
      'mortgageType': mortgageType,
      'notes': notes,
    };
  }

  Mortgage copyWith({
    String? id,
    String? lender,
    double? amount,
    DateTime? renewalDate,
    double? interestRate,
    String? mortgageType,
    String? notes,
  }) {
    return Mortgage(
      id: id ?? this.id,
      lender: lender ?? this.lender,
      amount: amount ?? this.amount,
      renewalDate: renewalDate ?? this.renewalDate,
      interestRate: interestRate ?? this.interestRate,
      mortgageType: mortgageType ?? this.mortgageType,
      notes: notes ?? this.notes,
    );
  }
}
