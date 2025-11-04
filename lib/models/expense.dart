class Expense {
  final int? id;
  final double amount;
  final String description;
  final DateTime timestamp;

  const Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  /// Creates an Expense from a database map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  /// Converts the Expense to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Creates a copy of this Expense with updated values
  Expense copyWith({
    int? id,
    double? amount,
    String? description,
    DateTime? timestamp,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Validates expense data
  static String? validateAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  /// Validates description
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Description cannot be empty';
    }
    if (description.trim().length > 100) {
      return 'Description must be less than 100 characters';
    }
    return null;
  }

  /// Validates the entire expense
  List<String> validate() {
    final errors = <String>[];
    
    final amountError = validateAmount(amount);
    if (amountError != null) {
      errors.add(amountError);
    }
    
    final descriptionError = validateDescription(description);
    if (descriptionError != null) {
      errors.add(descriptionError);
    }
    
    return errors;
  }

  /// Checks if the expense is valid
  bool get isValid => validate().isEmpty;

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, description: $description, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Expense &&
        other.id == id &&
        other.amount == amount &&
        other.description == description &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        timestamp.hashCode;
  }
}