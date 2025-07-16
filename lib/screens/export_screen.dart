import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../models/weight_record.dart';
import '../models/exercise_record.dart';

class ExportScreen extends StatelessWidget {
  final dbHelper = DatabaseHelper();

  Future<void> _exportData(BuildContext context) async {
    try {
      // 1. Fetch data from database
      final weightData = await dbHelper.getAllWeightRecords();
      final exerciseData = await dbHelper.getAllExerciseRecordsWithDetails();

      final List<WeightRecord> weightRecords = weightData.map((item) => WeightRecord.fromJson({
        'id': item['id'] as int,
        'weight': (item['weight'] as num?)?.toDouble() ?? 0.0,
        'date': item['date'].toString(),
      })).toList();

      final List<ExerciseRecord> exerciseRecords = exerciseData.map((item) => ExerciseRecord.fromJson({
        'id': item['id'] as int,
        'exerciseTypeId': item['exercise_type_id'] as int,
        'exerciseName': item['exercise_name'] as String? ?? '',
        'date': item['date'].toString(),
        'weight': item['weight'] != null ? (item['weight'] as num).toDouble() : null,
        'reps': item['reps'] as int?,
        'duration': item['duration'] as int?,
        'sets': item['sets'] as int?,
        'notes': item['notes'] as String?,
      })).toList();

      // 2. Create Excel file
      var excel = Excel.createExcel();

      // Create Weight Sheet
      Sheet weightSheet = excel['Weight Records'];
      weightSheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Weight (kg)'),
        TextCellValue('Date')
      ]);
      for (var record in weightRecords) {
        weightSheet.appendRow([
          TextCellValue(record.id.toString()),
          TextCellValue(record.weight.toString()),
          TextCellValue(record.date.toIso8601String())
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
         TextCellValue('Date')
      ]);
      for (var record in exerciseRecords) {
        exerciseSheet.appendRow([
          TextCellValue(record.id.toString()),
          TextCellValue(record.exerciseName),
          TextCellValue(record.weight?.toString() ?? 'N/A'),
          TextCellValue(record.reps?.toString() ?? 'N/A'),
          TextCellValue(record.sets?.toString() ?? 'N/A'),
          TextCellValue(record.duration != null ? (record.duration! / 60).toStringAsFixed(1) : 'N/A'),
          TextCellValue(record.notes ?? 'N/A'),
          TextCellValue(record.date.toIso8601String())
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
          SnackBar(content: Text('Data exported successfully to $filePath and shared.')),
        );
      } else {
        throw Exception('Failed to save excel file.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
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
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _exportData(context),
          child: Text('운동기록 엑셀파일로 내보내기'),
        ),
      ),
    );
  }
}
