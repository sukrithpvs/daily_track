/// Transaction type enum
enum TransactionType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }
}

/// Transaction category enum
enum TransactionCategory {
  // Income categories
  salary,
  freelance,
  business,
  investment,
  gift,
  other,

  // Expense categories
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
  misc;

  String get displayName {
    switch (this) {
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.business:
        return 'Business';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.gift:
        return 'Gift';
      case TransactionCategory.other:
        return 'Other';
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.bills:
        return 'Bills';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.misc:
        return 'Miscellaneous';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.salary:
        return '💼';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.business:
        return '📈';
      case TransactionCategory.investment:
        return '💰';
      case TransactionCategory.gift:
        return '🎁';
      case TransactionCategory.other:
        return '📝';
      case TransactionCategory.food:
        return '🍽️';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.bills:
        return '📄';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.health:
        return '💊';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.misc:
        return '📦';
    }
  }

  bool get isIncomeCategory {
    return [
      TransactionCategory.salary,
      TransactionCategory.freelance,
      TransactionCategory.business,
      TransactionCategory.investment,
      TransactionCategory.gift,
      TransactionCategory.other,
    ].contains(this);
  }

  static List<TransactionCategory> getIncomeCategories() {
    return values.where((cat) => cat.isIncomeCategory).toList();
  }

  static List<TransactionCategory> getExpenseCategories() {
    return values.where((cat) => !cat.isIncomeCategory).toList();
  }
}

class MoneyTransaction {
  final int? id;
  final double amount;
  final String description;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionCategory category;

  const MoneyTransaction({
    this.id,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.category,
  });

  /// Creates a MoneyTransaction from a database map
  factory MoneyTransaction.fromMap(Map<String, dynamic> map) {
    return MoneyTransaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      type: TransactionType.values[map['type'] as int],
      category: TransactionCategory.values[map['category'] as int],
    );
  }

  /// Converts the MoneyTransaction to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.index,
      'category': category.index,
    };
  }

  /// Creates a copy of this MoneyTransaction with updated values
  MoneyTransaction copyWith({
    int? id,
    double? amount,
    String? description,
    DateTime? timestamp,
    TransactionType? type,
    TransactionCategory? category,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      category: category ?? this.category,
    );
  }

  /// Validates transaction data
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

  /// Validates the entire transaction
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

  /// Checks if the transaction is valid
  bool get isValid => validate().isEmpty;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  @override
  String toString() {
    return 'MoneyTransaction(id: $id, amount: $amount, description: $description, type: $type, category: $category, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoneyTransaction &&
        other.id == id &&
        other.amount == amount &&
        other.description == description &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        amount.hashCode ^
        description.hashCode ^
        timestamp.hashCode ^
        type.hashCode ^
        category.hashCode;
  }
}
