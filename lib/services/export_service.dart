import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<String> exportToJson() async {
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'study_planner_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0]}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);
      return file.path;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Export error: $e\n$s');
      }
      rethrow;
    }
  }

  Future<void> importFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['subjects'] == null && data['tasks'] == null) {
        throw Exception('Invalid backup format');
      }
      await DatabaseHelper.instance.importData(data);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Import error: $e\n$s');
      }
      rethrow;
    }
  }

  Future<String?> pickExportPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}
