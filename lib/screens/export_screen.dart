import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../models/weight_record.dart';
import '../models/exercise_record.dart';
import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../navigation/back_button_mixin.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      // 1. Fetch data from database
      final weightData = await dbHelper.getAllWeightRecords();
      final exerciseData = await dbHelper.getAllExerciseRecordsWithDetails();
      final exerciseTypes = await dbHelper.getAllExerciseTypes();

      final List<WeightRecord> weightRecords = weightData
          .map(
            (item) => WeightRecord.fromJson({
              'id': item['id'] as int,
              'weight': (item['weight'] as num?)?.toDouble() ?? 0.0,
              'date': item['date'].toString(),
            }),
          )
          .toList();

      final List<ExerciseRecord> exerciseRecords = exerciseData
          .map(
            (item) => ExerciseRecord.fromJson({
              'id': item['id'] as int,
              'exerciseTypeId': item['exercise_type_id'] as int,
              'exerciseName': item['exercise_name'] as String? ?? '',
              'date': item['date'].toString(),
              'weight': item['weight'] != null
                  ? (item['weight'] as num).toDouble()
                  : null,
              'reps': item['reps'] as int?,
              'duration': item['duration'] as int?,
              'sets': item['sets'] as int?,
              'notes': item['notes'] as String?,
            }),
          )
          .toList();

      // 2. Create Excel file
      var excel = Excel.createExcel();

      // Create Weight Sheet
      Sheet weightSheet = excel['Weight Records'];
      weightSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Weight (kg)'),
        TextCellValue('Date'),
      ]);
      for (var record in weightRecords) {
        weightSheet.appendRow([
          TextCellValue(record.id.toString()),
          TextCellValue(record.weight.toString()),
          TextCellValue(record.date.toIso8601String()),
        ]);
      }

      // Create Exercise Sheet
      Sheet exerciseSheet = excel['Exercise Records'];
      exerciseSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Exercise Type'),
        TextCellValue('Weight (kg)'),
        TextCellValue('Reps'),
        TextCellValue('Sets'),
        TextCellValue('Duration (minutes)'),
        TextCellValue('Notes'),
        TextCellValue('Date'),
      ]);
      for (var record in exerciseRecords) {
        exerciseSheet.appendRow([
          TextCellValue(record.id.toString()),
          TextCellValue(record.exerciseName),
          TextCellValue(record.weight?.toString() ?? 'N/A'),
          TextCellValue(record.reps?.toString() ?? 'N/A'),
          TextCellValue(record.sets?.toString() ?? 'N/A'),
          TextCellValue(
            record.duration != null
                ? (record.duration! / 60).toStringAsFixed(1)
                : 'N/A',
          ),
          TextCellValue(record.notes ?? 'N/A'),
          TextCellValue(record.date.toIso8601String()),
        ]);
      }

      // Create Exercise Types Sheet
      Sheet exerciseTypeSheet = excel['Exercise Types'];
      exerciseTypeSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Name'),
        TextCellValue('Category'),
        TextCellValue('Body_Part'),
        TextCellValue('Counting_Method'),
      ]);
      for (var type in exerciseTypes) {
        exerciseTypeSheet.appendRow([
          TextCellValue(type['id'].toString()),
          TextCellValue(type['name'] as String),
          TextCellValue(type['category'] as String),
          TextCellValue(type['body_part'] as String),
          TextCellValue(type['counting_method'] as String),
        ]);
      }

      // 3. Save the file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/fitness_data.xlsx';
      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        // 4. Share the file
        await Share.shareXFiles([XFile(filePath)], text: 'My Fitness Data');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported successfully to $filePath and shared.',
            ),
          ),
        );
      } else {
        throw Exception('Failed to save excel file.');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();
      final typeGroup = XTypeGroup(label: 'excel', extensions: ['xlsx']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('파일 선택이 취소되었습니다.')));
        return;
      }
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Import Exercise Types
      if (excel.sheets.containsKey('Exercise Types')) {
        final sheet = excel['Exercise Types']!;
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 5) continue; // Need at least 5 columns
          
          final typeId = row[0]?.value.toString();
          final typeName = row[1]?.value.toString() ?? '';
          final category = row[2]?.value.toString() ?? '';
          final bodyPart = row[3]?.value.toString() ?? '';
          final countingMethod = row[4]?.value.toString() ?? '';
          
          if (typeName.isNotEmpty) {
            // Check for duplicate by name first
            final existingType = await dbHelper.getExerciseTypeByName(typeName);
            if (existingType == null) {
              // Insert with all available fields
              await dbHelper.insertExerciseType({
                'name': typeName,
                'category': category,
                'body_part': bodyPart,
                'counting_method': countingMethod,
              });
            } else {
              // Update existing type with additional fields if they're missing
              final db = await dbHelper.database;
              await db.update(
                'exercise_types',
                {
                  'category': category.isNotEmpty ? category : existingType['category'],
                  'body_part': bodyPart.isNotEmpty ? bodyPart : existingType['body_part'],
                  'counting_method': countingMethod.isNotEmpty ? countingMethod : existingType['counting_method'],
                },
                where: 'id = ?',
                whereArgs: [existingType['id']],
              );
            }
          }
        }
      }

      // Import Weight Records
      if (excel.sheets.containsKey('Weight Records')) {
        final sheet = excel['Weight Records'];
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 3) continue;
          final weight = double.tryParse(row[1]?.value.toString() ?? '');
          final dateStr = row[2]?.value.toString();
          if (weight != null && dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date == null) continue;
            final existing = await dbHelper.getWeightRecordByDate(date);
            if (existing != null) continue; // 중복이면 pass
            await dbHelper.insertWeightRecord({
              'weight': weight,
              'date': dateStr,
            });
          }
        }
      }

      // Import Exercise Records
      if (excel.sheets.containsKey('Exercise Records')) {
        final sheet = excel['Exercise Records'];
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 8) continue;
          final exerciseName = row[1]?.value.toString() ?? '';
          final weight = double.tryParse(row[2]?.value.toString() ?? '');
          final reps = int.tryParse(row[3]?.value.toString() ?? '');
          final sets = int.tryParse(row[4]?.value.toString() ?? '');
          final duration = double.tryParse(row[5]?.value.toString() ?? '');
          final notes = row[6]?.value.toString();
          final dateStr = row[7]?.value.toString();

          final types = await dbHelper.getAllExerciseTypes();
          final type = types.firstWhere(
            (t) => t['name'] == exerciseName,
            orElse: () => <String, dynamic>{},
          );
          if (type.isEmpty) continue;

          // Check for duplicate exercise record
          final db = await dbHelper.database;
          final existing = await db.query(
            'exercise_records',
            where:
                'exercise_type_id = ? AND date = ? AND weight = ? AND reps = ? AND sets = ? AND duration = ?',
            whereArgs: [
              type['id'],
              dateStr,
              weight,
              reps,
              sets,
              duration != null ? (duration * 60).toInt() : null,
            ],
            limit: 1,
          );
          if (existing.isNotEmpty) continue; // 중복이면 pass

          await dbHelper.insertExerciseRecord({
            'exercise_type_id': type['id'],
            'date': dateStr,
            'weight': weight,
            'reps': reps,
            'sets': sets,
            'duration': duration != null ? (duration * 60).toInt() : null,
            'notes': notes,
          });
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('데이터가 성공적으로 가져와졌습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 가져오기 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.cyan.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.cyan.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () async {
                if (!context.mounted) return;
                
                final navigationManager = ref.read(navigationManagerProvider);
                final result = await navigationManager.handleBackNavigation(context);
                
                if (context.mounted) {
                  await navigationManager.executeNavigation(context, result);
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '데이터 내보내기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '운동 기록을 파일로 내보내세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade200, Colors.cyan.shade200],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.cyan.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _exportData(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text(
                '엑셀 파일로 내보내기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _importData(context),
            child: const Text('엑셀파일에서 데이터 가져오기'),
          ),
        ],
      ),
    );
  }
}
