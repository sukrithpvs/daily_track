/// Utility class for parsing expense input text
class InputParser {
  /// Parses expense input in formats like "120 - juice" or "120 juice"
  /// Returns a map with 'amount' and 'description' keys
  static Map<String, dynamic>? parseExpenseInput(String input) {
    if (input.trim().isEmpty) {
      return null;
    }

    final trimmedInput = input.trim();
    
    // Try to parse different formats
    Map<String, dynamic>? result;
    
    // Format 1: "120 - juice" (with dash separator)
    result = _parseWithDashSeparator(trimmedInput);
    if (result != null) return result;
    
    // Format 2: "120 juice" (space separated)
    result = _parseSpaceSeparated(trimmedInput);
    if (result != null) return result;
    
    // Format 3: "120.50 coffee" (decimal amount)
    result = _parseDecimalAmount(trimmedInput);
    if (result != null) return result;
    
    return null;
  }

  /// Parse format: "120 - juice"
  static Map<String, dynamic>? _parseWithDashSeparator(String input) {
    final dashPattern = RegExp(r'^(\d+(?:\.\d+)?)\s*-\s*(.+)$');
    final match = dashPattern.firstMatch(input);
    
    if (match != null) {
      final amountStr = match.group(1);
      final description = match.group(2);
      
      if (amountStr != null && description != null) {
        final amount = double.tryParse(amountStr);
        final trimmedDescription = description.trim();
        if (amount != null && amount > 0 && trimmedDescription.isNotEmpty && trimmedDescription != '-') {
          return {
            'amount': amount,
            'description': trimmedDescription,
          };
        }
      }
    }
    
    return null;
  }

  /// Parse format: "120 juice" (space separated)
  static Map<String, dynamic>? _parseSpaceSeparated(String input) {
    final spacePattern = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$');
    final match = spacePattern.firstMatch(input);
    
    if (match != null) {
      final amountStr = match.group(1);
      final description = match.group(2);
      
      if (amountStr != null && description != null) {
        final amount = double.tryParse(amountStr);
        final trimmedDescription = description.trim();
        if (amount != null && amount > 0 && trimmedDescription.isNotEmpty && trimmedDescription != '-') {
          return {
            'amount': amount,
            'description': trimmedDescription,
          };
        }
      }
    }
    
    return null;
  }

  /// Parse format with decimal amounts
  static Map<String, dynamic>? _parseDecimalAmount(String input) {
    // This is already handled by the above methods, but kept for clarity
    return null;
  }

  /// Validates if the input format is potentially valid
  static bool isValidFormat(String input) {
    return parseExpenseInput(input) != null;
  }

  /// Gets a list of supported input format examples
  static List<String> getSupportedFormats() {
    return [
      '120 - coffee',
      '120 coffee',
      '25.50 - lunch',
      '25.50 lunch',
      '100 groceries',
    ];
  }

  /// Extracts just the amount from input if possible
  static double? extractAmount(String input) {
    final result = parseExpenseInput(input);
    return result?['amount'] as double?;
  }

  /// Extracts just the description from input if possible
  static String? extractDescription(String input) {
    final result = parseExpenseInput(input);
    return result?['description'] as String?;
  }

  /// Validates amount value
  static String? validateAmount(double? amount) {
    if (amount == null) {
      return 'Amount is required';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 999999) {
      return 'Amount is too large';
    }
    return null;
  }

  /// Validates description value
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Description is required';
    }
    if (description.trim().length > 100) {
      return 'Description must be less than 100 characters';
    }
    return null;
  }

  /// Comprehensive validation of parsed input
  static List<String> validateParsedInput(Map<String, dynamic>? parsed) {
    final errors = <String>[];
    
    if (parsed == null) {
      errors.add('Invalid input format. Use formats like "120 coffee" or "120 - coffee"');
      return errors;
    }
    
    final amount = parsed['amount'] as double?;
    final description = parsed['description'] as String?;
    
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

  /// Formats amount for display
  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  /// Cleans and normalizes input text
  static String normalizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}