class GicInvestment {
  final String id;
  final String institution;
  final double amount;
  final DateTime purchaseDate;
  final int termMonths;
  final double interestRate;
  final String notes;

  const GicInvestment({
    required this.id,
    required this.institution,
    required this.amount,
    required this.purchaseDate,
    required this.termMonths,
    required this.interestRate,
    this.notes = '',
  });

  DateTime get maturityDate => purchaseDate.add(Duration(days: termMonths * 30));

  int get daysUntilMaturity => maturityDate.difference(DateTime.now()).inDays;

  bool get isMatured => DateTime.now().isAfter(maturityDate);

  factory GicInvestment.fromMap(Map<String, dynamic> map) {
    return GicInvestment(
      id: map['id'] as String,
      institution: map['institution'] as String,
      amount: (map['amount'] as num).toDouble(),
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      termMonths: map['termMonths'] as int,
      interestRate: (map['interestRate'] as num).toDouble(),
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution': institution,
      'amount': amount,
      'purchaseDate': purchaseDate.toIso8601String(),
      'termMonths': termMonths,
      'interestRate': interestRate,
      'notes': notes,
    };
  }

  GicInvestment copyWith({
    String? id,
    String? institution,
    double? amount,
    DateTime? purchaseDate,
    int? termMonths,
    double? interestRate,
    String? notes,
  }) {
    return GicInvestment(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      amount: amount ?? this.amount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      termMonths: termMonths ?? this.termMonths,
      interestRate: interestRate ?? this.interestRate,
      notes: notes ?? this.notes,
    );
  }
}
