import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:smartsacco/services/analytics_service.dart';


/// Service for exporting, importing, and sharing application data in various formats (JSON, CSV).
/// Handles both user-specific data exports and admin-level data exports.
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  /// Exports user data from Firestore in a structured format.
  Future<Map<String, dynamic>> exportUserData({
    required String userId,
    List<String>? dataTypes,
  }) async {
    try {

            // Initialize export structure with metadata

      final exportData = <String, dynamic>{
        'export_info': {
          'exported_at': DateTime.now().toIso8601String(),
          'user_id': userId,
          'app_version': '1.0.0',
          'data_types': dataTypes ?? ['all'],
        },
        'user_profile': {},
        'transactions': [],
        'loans': [],
        'notifications': [],
        'analytics': [],
      };

      
      // Export user profile if requested
      if (dataTypes == null || dataTypes.contains('profile')) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          exportData['user_profile'] = userDoc.data();
        }
      }

      // Export transactions
      if (dataTypes == null || dataTypes.contains('transactions')) {
        final transactionsSnapshot = await _firestore
            .collection('transactions')
            .where('memberId', isEqualTo: userId)
            .get();

        exportData['transactions'] = transactionsSnapshot.docs.map((doc) {
          final data = doc.data();
          return <String, dynamic>{'id': doc.id, ...data};
        }).toList();
      }

    // Export loans if requested

      if (dataTypes == null || dataTypes.contains('loans')) {
        final loansSnapshot = await _firestore
            .collection('loans')
            .where('memberId', isEqualTo: userId)
            .get();

        exportData['loans'] = loansSnapshot.docs.map((doc) {
          final data = doc.data();
          return <String, dynamic>{'id': doc.id, ...data};
        }).toList();
      }

      // Export notifications
      if (dataTypes == null || dataTypes.contains('notifications')) {
        final notificationsSnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();

        exportData['notifications'] = notificationsSnapshot.docs.map((doc) {
          final data = doc.data();
          return <String, dynamic>{'id': doc.id, ...data};
        }).toList();
      }

      // Export analytics data
      if (dataTypes == null || dataTypes.contains('analytics')) {
        final analyticsData = await _analytics.getAnalyticsData(userId: userId);
        exportData['analytics'] = analyticsData;
      }

      // Track analytics event for the export
      await _analytics.trackFeatureUsage(
        featureName: 'data_export',
        parameters: {
          'user_id': userId,
          'data_types': dataTypes ?? ['all'],
          'data_size': jsonEncode(exportData).length,
        },
      );

      return exportData;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      await _analytics.trackError(
        errorType: 'data_export_error',
        errorMessage: e.toString(),
      );
      return {'error': 'Failed to export data: $e'};
    }
  }

   /// Exports admin-level data from Firestore with optional date filtering.
  /// [startDate]: Optional start date for filtering data
  /// [endDate]: Optional end date for filtering data
  /// [dataTypes]: Optional list of specific data types to export
  /// Returns a map containing all requested admin data
  Future<Map<String, dynamic>> exportAdminData({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? dataTypes,
  }) async {
    try {

      // Initialize export structure with metadata
      final exportData = <String, dynamic>{
        'export_info': {
          'exported_at': DateTime.now().toIso8601String(),
          'export_type': 'admin_data',
          'app_version': '1.0.0',
          'data_types': dataTypes ?? ['all'],
          'period': {
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
          },
        },
        'users': [],
        'transactions': [],
        'loans': [],
        'analytics': [],
        'system_settings': {},
      };

   // Export users data if requested
      if (dataTypes == null || dataTypes.contains('users')) {
        Query usersQuery = _firestore.collection('users');
        if (startDate != null) {
          usersQuery = usersQuery.where(
            'joinDate',
            isGreaterThanOrEqualTo: startDate,
          );
        }
        if (endDate != null) {
          usersQuery = usersQuery.where(
            'joinDate',
            isLessThanOrEqualTo: endDate,
          );
        }

        final usersSnapshot = await usersQuery.get();
        exportData['users'] = usersSnapshot.docs.map((doc) {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            return <String, dynamic>{'id': doc.id, ...data};
          } else {
            return <String, dynamic>{'id': doc.id};
          }
        }).toList();
      }

      // Export transactions data if requested
      if (dataTypes == null || dataTypes.contains('transactions')) {
        Query transactionsQuery = _firestore.collection('transactions');
        if (startDate != null) {
          transactionsQuery = transactionsQuery.where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
          );
        }
        if (endDate != null) {
          transactionsQuery = transactionsQuery.where(
            'timestamp',
            isLessThanOrEqualTo: endDate,
          );
        }

        final transactionsSnapshot = await transactionsQuery.get();
        exportData['transactions'] = transactionsSnapshot.docs.map((doc) {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            return <String, dynamic>{'id': doc.id, ...data};
          } else {
            return <String, dynamic>{'id': doc.id};
          }
        }).toList();
      }

    // Export loans data if requested
      if (dataTypes == null || dataTypes.contains('loans')) {
        Query loansQuery = _firestore.collection('loans');
        if (startDate != null) {
          loansQuery = loansQuery.where(
            'applicationDate',
            isGreaterThanOrEqualTo: startDate,
          );
        }
        if (endDate != null) {
          loansQuery = loansQuery.where(
            'applicationDate',
            isLessThanOrEqualTo: endDate,
          );
        }

        final loansSnapshot = await loansQuery.get();
        exportData['loans'] = loansSnapshot.docs.map((doc) {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            return <String, dynamic>{'id': doc.id, ...data};
          } else {
            return <String, dynamic>{'id': doc.id};
          }
        }).toList();
      }

      // Export analytics
      if (dataTypes == null || dataTypes.contains('analytics')) {
        final analyticsData = await _analytics.getAnalyticsData(
          startDate: startDate,
          endDate: endDate,
        );
        exportData['analytics'] = analyticsData;
      }

      // Export system settings
      if (dataTypes == null || dataTypes.contains('settings')) {
        final settingsSnapshot = await _firestore
            .collection('system_settings')
            .get();
        exportData['system_settings'] = settingsSnapshot.docs.map((doc) {
          final data = doc.data();
          return <String, dynamic>{'id': doc.id, ...data};
                }).toList();
      }

      // Track export event
      await _analytics.trackFeatureUsage(
        featureName: 'admin_data_export',
        parameters: {
          'data_types': dataTypes ?? ['all'],
          'data_size': jsonEncode(exportData).length,
          'period': {
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
          },
        },
      );

      return exportData;
    } catch (e) {
      debugPrint('Error exporting admin data: $e');
      await _analytics.trackError(
        errorType: 'admin_data_export_error',
        errorMessage: e.toString(),
      );
      return {'error': 'Failed to export admin data: $e'};
    }
  }

  // Export data to file
  Future<String?> exportToFile({
    required Map<String, dynamic> data,
    required String format,
    String? fileName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'export_$timestamp';
      final finalFileName = fileName ?? defaultFileName;

      String filePath;
      String content;

      if (format.toLowerCase() == 'csv') {
        content = _convertToCsv(data);
        filePath = '${directory.path}/$finalFileName.csv';
      } else {
        content = jsonEncode(data);
        filePath = '${directory.path}/$finalFileName.json';
      }

      final file = File(filePath);
      await file.writeAsString(content);

      return filePath;
    } catch (e) {
      debugPrint('Error exporting to file: $e');
      await _analytics.trackError(
        errorType: 'file_export_error',
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Share exported data
  Future<bool> shareExportedData({
    required Map<String, dynamic> data,
    required String format,
    String? fileName,
  }) async {
    try {
      final filePath = await exportToFile(
        data: data,
        format: format,
        fileName: fileName,
      );

      if (filePath != null) {
        await Share.shareXFiles([XFile(filePath)]);

        await _analytics.trackFeatureUsage(
          featureName: 'data_share',
          parameters: {'format': format, 'file_path': filePath},
        );

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing exported data: $e');
      await _analytics.trackError(
        errorType: 'data_share_error',
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Import data from file
  Future<Map<String, dynamic>> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final content = await file.readAsString();
      Map<String, dynamic> data;

      if (filePath.endsWith('.json')) {
        data = jsonDecode(content);
      } else if (filePath.endsWith('.csv')) {
        data = _convertFromCsv(content);
      } else {
        throw Exception('Unsupported file format');
      }

      // Validate import data
      final validationResult = _validateImportData(data);
      if (!validationResult['valid']) {
        throw Exception(validationResult['error']);
      }

      await _analytics.trackFeatureUsage(
        featureName: 'data_import',
        parameters: {'file_path': filePath, 'data_size': content.length},
      );

      return data;
    } catch (e) {
      debugPrint('Error importing from file: $e');
      await _analytics.trackError(
        errorType: 'data_import_error',
        errorMessage: e.toString(),
      );
      return {'error': 'Failed to import data: $e'};
    }
  }

  // Restore user data from backup
  Future<bool> restoreUserData({
    required Map<String, dynamic> backupData,
    required String userId,
    bool overwrite = false,
  }) async {
    try {
      final batch = _firestore.batch();

      // Restore user profile
      if (backupData['user_profile'] != null) {
        final userRef = _firestore.collection('users').doc(userId);
        if (overwrite) {
          batch.set(userRef, backupData['user_profile']);
        } else {
          batch.set(
            userRef,
            backupData['user_profile'],
            SetOptions(merge: true),
          );
        }
      }

      // Restore transactions
      if (backupData['transactions'] != null) {
        for (final transaction in backupData['transactions']) {
          final transactionId = transaction['id'] as String?;
          if (transactionId != null) {
            final transactionRef = _firestore
                .collection('transactions')
                .doc(transactionId);
            final transactionData = Map<String, dynamic>.from(transaction);
            transactionData.remove('id');

            if (overwrite) {
              batch.set(transactionRef, transactionData);
            } else {
              batch.set(
                transactionRef,
                transactionData,
                SetOptions(merge: true),
              );
            }
          }
        }
      }

      // Restore loans
      if (backupData['loans'] != null) {
        for (final loan in backupData['loans']) {
          final loanId = loan['id'] as String?;
          if (loanId != null) {
            final loanRef = _firestore.collection('loans').doc(loanId);
            final loanData = Map<String, dynamic>.from(loan);
            loanData.remove('id');

            if (overwrite) {
              batch.set(loanRef, loanData);
            } else {
              batch.set(loanRef, loanData, SetOptions(merge: true));
            }
          }
        }
      }

      // Restore notifications
      if (backupData['notifications'] != null) {
        for (final notification in backupData['notifications']) {
          final notificationId = notification['id'] as String?;
          if (notificationId != null) {
            final notificationRef = _firestore
                .collection('notifications')
                .doc(notificationId);
            final notificationData = Map<String, dynamic>.from(notification);
            notificationData.remove('id');

            if (overwrite) {
              batch.set(notificationRef, notificationData);
            } else {
              batch.set(
                notificationRef,
                notificationData,
                SetOptions(merge: true),
              );
            }
          }
        }
      }

      await batch.commit();

      await _analytics.trackFeatureUsage(
        featureName: 'data_restore',
        parameters: {
          'user_id': userId,
          'overwrite': overwrite,
          'data_types': backupData.keys.toList(),
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error restoring user data: $e');
      await _analytics.trackError(
        errorType: 'data_restore_error',
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // Convert data to CSV format
  String _convertToCsv(Map<String, dynamic> data) {
    final csvData = <List<dynamic>>[];

    // Add export info
    csvData.add(['Export Info']);
    csvData.add(['Exported At', data['export_info']?['exported_at'] ?? '']);
    csvData.add(['User ID', data['export_info']?['user_id'] ?? '']);
    csvData.add(['App Version', data['export_info']?['app_version'] ?? '']);
    csvData.add([]);

    // Add user profile
    if (data['user_profile'] != null) {
      csvData.add(['User Profile']);
      final profile = data['user_profile'] as Map<String, dynamic>;
      for (final entry in profile.entries) {
        csvData.add([entry.key, entry.value]);
      }
      csvData.add([]);
    }

    // Add transactions
    if (data['transactions'] != null) {
      csvData.add(['Transactions']);
      final transactions = data['transactions'] as List<dynamic>;
      if (transactions.isNotEmpty) {
        final headers = transactions.first.keys.toList();
        csvData.add(headers);
        for (final transaction in transactions) {
          csvData.add(headers.map((header) => transaction[header]).toList());
        }
      }
      csvData.add([]);
    }

    // Add loans
    if (data['loans'] != null) {
      csvData.add(['Loans']);
      final loans = data['loans'] as List<dynamic>;
      if (loans.isNotEmpty) {
        final headers = loans.first.keys.toList();
        csvData.add(headers);
        for (final loan in loans) {
          csvData.add(headers.map((header) => loan[header]).toList());
        }
      }
      csvData.add([]);
    }

    // Use ListToCsvConverter to convert to String
    return const ListToCsvConverter().convert(csvData);
  }

  // Convert CSV to data structure
  Map<String, dynamic> _convertFromCsv(String csvContent) {
    final csvData = const CsvToListConverter().convert(csvContent);
    final data = <String, dynamic>{};

    // Parse CSV data back to structured format
    // This is a simplified implementation
    data['imported_from_csv'] = true;
    data['raw_data'] = csvData;

    return data;
  }

  // Validate import data
  Map<String, dynamic> _validateImportData(Map<String, dynamic> data) {
    try {
      // Check for required fields
      if (data['export_info'] == null) {
        return {'valid': false, 'error': 'Missing export info'};
      }

      final exportInfo = data['export_info'] as Map<String, dynamic>;
      if (exportInfo['exported_at'] == null) {
        return {'valid': false, 'error': 'Missing export timestamp'};
      }

      // Check data structure
      if (data['user_profile'] is! Map<String, dynamic>) {
        return {'valid': false, 'error': 'Invalid user profile format'};
      }

      if (data['transactions'] is! List) {
        return {'valid': false, 'error': 'Invalid transactions format'};
      }

      if (data['loans'] is! List) {
        return {'valid': false, 'error': 'Invalid loans format'};
      }

      return {'valid': true};
    } catch (e) {
      return {'valid': false, 'error': 'Data validation failed: $e'};
    }
  }

  // Get export statistics
  Map<String, dynamic> getExportStatistics(Map<String, dynamic> data) {
    final stats = <String, dynamic>{};

    stats['total_size_bytes'] = jsonEncode(data).length;
    stats['total_size_mb'] = (jsonEncode(data).length / 1024 / 1024)
        .toStringAsFixed(2);

    if (data['transactions'] != null) {
      stats['transaction_count'] = (data['transactions'] as List).length;
    }

    if (data['loans'] != null) {
      stats['loan_count'] = (data['loans'] as List).length;
    }

    if (data['notifications'] != null) {
      stats['notification_count'] = (data['notifications'] as List).length;
    }

    stats['export_timestamp'] = data['export_info']?['exported_at'];
    stats['app_version'] = data['export_info']?['app_version'];

    return stats;
  }
}
