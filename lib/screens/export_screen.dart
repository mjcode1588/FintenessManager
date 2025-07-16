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

class ExportScreen extends StatelessWidget {
  final dbHelper = DatabaseHelper();

  Future<void> _exportData(BuildContext context) async {
    try {
      // 1. Fetch data from database
      final weightData = await dbHelper.getAllWeightRecords();
      final exerciseData = await dbHelper.getAllExerciseRecordsWithDetails();

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('데이터 내보내기'),
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            // go_router를 사용하는 다른 화면들과 동일하게 홈으로 이동
            Navigator.of(
              context,
            ).popUntil((route) => route.isFirst); // 기존 코드 주석처리 가능
            // context.go('/')로 홈 이동
            // go_router import 필요
            // context.go('/')
            // 아래처럼 실제로 context.go('/')로 변경
            // (go_router import가 없으면 추가)
            // context.go('/')
            // 실제 적용:
            context.go('/');
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _exportData(context),
              child: Text('운동기록 엑셀파일로 내보내기'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _importData(context),
              child: Text('엑셀파일에서 데이터 가져오기'),
            ),
          ],
        ),
      ),
    );
  }
}
