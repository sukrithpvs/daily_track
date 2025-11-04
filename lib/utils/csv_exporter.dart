import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/expense.dart';

class CsvExporter {
  static const String _filePrefix = 'DailyTrack_';
  static const String _fileExtension = '.csv';

  /// Export expenses to CSV file
  static Future<CsvExportResult> exportExpenses(
    List<Expense> expenses, {
    String? customFileName,
    Directory? customDirectory,
  }) async {
    try {
      if (expenses.isEmpty) {
        return CsvExportResult.error('No expenses to export');
      }

      // Generate CSV content
      final csvContent = _generateCsvContent(expenses);

      // Get file name
      final fileName = customFileName ?? _generateFileName(expenses);

      // Get directory
      final directory = customDirectory ?? await _getExportDirectory();
      if (directory == null) {
        return CsvExportResult.error('Unable to access storage directory');
      }

      // Create file
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);

      return CsvExportResult.success(
        filePath: file.path,
        fileName: fileName,
        recordCount: expenses.length,
      );
    } catch (e) {
      return CsvExportResult.error('Export failed: $e');
    }
  }

  /// Export monthly expenses
  static Future<CsvExportResult> exportMonthlyExpenses(
    List<Expense> expenses,
    int year,
    int month,
  ) async {
    final monthName = DateFormat('MMMM_yyyy').format(DateTime(year, month));
    final fileName = '$_filePrefix$monthName$_fileExtension';
    
    return exportExpenses(expenses, customFileName: fileName);
  }

  /// Generate CSV content from expenses
  static String _generateCsvContent(List<Expense> expenses) {
    final List<List<dynamic>> rows = [];

    // Add header row - only Date, Description, Amount (no time)
    rows.add(['Date', 'Description', 'Amount']);

    // Add expense rows with simple date format
    for (final expense in expenses) {
      // Format date as simple string: "4-Nov-25"
      final day = expense.timestamp.day;
      final month = expense.timestamp.month;
      final year = expense.timestamp.year % 100; // Last 2 digits of year
      final dateStr = '$day-$month-$year';
      
      rows.add([
        dateStr,
        expense.description,
        expense.amount.toInt().toString(), // Show as whole number
      ]);
    }

    // Convert to CSV string with proper formatting
    return const ListToCsvConverter().convert(rows);
  }

  /// Generate file name based on expenses
  static String _generateFileName(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return '${_filePrefix}empty$_fileExtension';
    }

    // Sort expenses by date to get date range
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstDate = sortedExpenses.first.timestamp;
    final lastDate = sortedExpenses.last.timestamp;

    // If all expenses are from the same month, use month name
    if (firstDate.year == lastDate.year && firstDate.month == lastDate.month) {
      final monthName = DateFormat('MMMM_yyyy').format(firstDate);
      return '$_filePrefix$monthName$_fileExtension';
    }

    // If all expenses are from the same day, use date
    if (DateFormat('yyyy-MM-dd').format(firstDate) == 
        DateFormat('yyyy-MM-dd').format(lastDate)) {
      final dateStr = DateFormat('yyyy-MM-dd').format(firstDate);
      return '${_filePrefix}$dateStr$_fileExtension';
    }

    // Use date range
    final startDate = DateFormat('yyyy-MM-dd').format(firstDate);
    final endDate = DateFormat('yyyy-MM-dd').format(lastDate);
    return '$_filePrefix${startDate}_to_${endDate}$_fileExtension';
  }

  /// Get the directory for exporting files
  static Future<Directory?> _getExportDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try multiple locations for better compatibility
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads', 
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            return dir;
          }
        }

        // Create Downloads folder in external storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadDir = Directory('${externalDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      }

      // Fallback to documents directory
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      // Final fallback to app documents
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Check and request storage permissions
  static Future<bool> checkAndRequestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 11+ (API 30+), try MANAGE_EXTERNAL_STORAGE first
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        
        if (manageStatus.isGranted) {
          return true;
        }
        
        // Fallback to regular storage permission
        var status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        
        return status.isGranted;
      }

      // iOS doesn't need explicit storage permissions for app documents
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get available export formats
  static List<String> getSupportedFormats() {
    return ['CSV'];
  }

  /// Validate expenses before export
  static List<String> validateExpensesForExport(List<Expense> expenses) {
    final errors = <String>[];

    if (expenses.isEmpty) {
      errors.add('No expenses to export');
      return errors;
    }

    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      final expenseErrors = expense.validate();
      if (expenseErrors.isNotEmpty) {
        errors.add('Expense ${i + 1}: ${expenseErrors.first}');
      }
    }

    return errors;
  }

  /// Get export statistics
  static ExportStatistics getExportStatistics(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return ExportStatistics(
        totalExpenses: 0,
        totalAmount: 0.0,
        dateRange: null,
        averageAmount: 0.0,
      );
    }

    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final totalAmount = expenses.fold<double>(
      0.0, 
      (sum, expense) => sum + expense.amount,
    );

    return ExportStatistics(
      totalExpenses: expenses.length,
      totalAmount: totalAmount,
      dateRange: DateRange(
        start: sortedExpenses.first.timestamp,
        end: sortedExpenses.last.timestamp,
      ),
      averageAmount: totalAmount / expenses.length,
    );
  }
}

/// Result of CSV export operation
class CsvExportResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final int? recordCount;
  final String? errorMessage;

  const CsvExportResult._({
    required this.success,
    this.filePath,
    this.fileName,
    this.recordCount,
    this.errorMessage,
  });

  factory CsvExportResult.success({
    required String filePath,
    required String fileName,
    required int recordCount,
  }) {
    return CsvExportResult._(
      success: true,
      filePath: filePath,
      fileName: fileName,
      recordCount: recordCount,
    );
  }

  factory CsvExportResult.error(String message) {
    return CsvExportResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Statistics about the export
class ExportStatistics {
  final int totalExpenses;
  final double totalAmount;
  final DateRange? dateRange;
  final double averageAmount;

  const ExportStatistics({
    required this.totalExpenses,
    required this.totalAmount,
    required this.dateRange,
    required this.averageAmount,
  });
}

/// Date range for export
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);
  
  bool get isSameDay => 
      start.year == end.year && 
      start.month == end.month && 
      start.day == end.day;
      
  bool get isSameMonth => 
      start.year == end.year && 
      start.month == end.month;
}