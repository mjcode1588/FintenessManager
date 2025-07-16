import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/exercise_type.dart';
import '../providers/exercise_provider.dart';
import '../providers/database_provider.dart';

class ExerciseRecordScreen extends ConsumerStatefulWidget {
  const ExerciseRecordScreen({super.key});

  @override
  ConsumerState<ExerciseRecordScreen> createState() =>
      _ExerciseRecordScreenState();
}

class _ExerciseRecordScreenState extends ConsumerState<ExerciseRecordScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy년 MM월 dd일');
  Set<DateTime> _recordedDates = {};

  @override
  void initState() {
    super.initState();
    _fetchRecordedDates();
  }

  Future<void> _fetchRecordedDates() async {
    final allRecords = await ref
        .read(databaseProvider)
        .getAllExerciseRecordsWithDetails();
    setState(() {
      _recordedDates = allRecords
          .map((r) => DateTime.parse(r['date']).toLocal())
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet();
    });
  }

  List<Widget> _buildMarkers(DateTime day, DateTime focusedDay) {
    final isRecorded = _recordedDates.contains(
      DateTime(day.year, day.month, day.day),
    );
    if (isRecorded) {
      return [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final exerciseRecordsAsync = ref.watch(
      exerciseRecordsByDateProvider(_selectedDate),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 캘린더
            Padding(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                firstDay: DateTime(2020),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildMarkers(day, _selectedDate),
                  ),
                ),
              ),
            ),

            // 운동 기록 목록
            Expanded(
              child: exerciseRecordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '이 날짜에 운동 기록이 없습니다.\n새로운 기록을 추가해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final weight = record['weight'] as double?;
                      final reps = record['reps'] as int?;
                      final duration = record['duration'] as int?;
                      final sets = record['sets'] as int?;
                      final notes = record['notes'] as String?;
                      final exerciseName =
                          record['exercise_name'] as String? ?? '알 수 없는 운동';
                      final countingMethod =
                          record['counting_method'] as String?;
                      final weightType = record['weight_type'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(exerciseName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (countingMethod == 'reps' && reps != null)
                                Text(
                                  (weightType == 'bodyweight'
                                          ? '몸무게 없이 '
                                          : (weight != null
                                                ? '${weight}kg × '
                                                : '')) +
                                      '${reps}회 × ${sets ?? 1}세트',
                                ),
                              if (countingMethod == 'time' && duration != null)
                                Text('${duration ~/ 60}분 ${duration % 60}초'),
                              if (notes != null && notes.isNotEmpty)
                                Text('메모: $notes'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showEditRecordDialog(record),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _deleteRecord(record['id'] as int),
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('오류가 발생했습니다: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showAddRecordDialog() async {
    // 로딩 인디케이터 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final exerciseTypes = await ref.read(exerciseTypesProvider.future);

      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      if (exerciseTypes.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('먼저 운동 종류를 추가해주세요')));
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AddExerciseRecordDialog(
          exerciseTypes: exerciseTypes,
          selectedDate: _selectedDate,
          onSave: (record) {
            ref
                .read(exerciseRecordNotifierProvider.notifier)
                .addExerciseRecord(
                  exerciseTypeId: record['exerciseTypeId'],
                  date: record['date'],
                  weight: record['weight'],
                  reps: record['reps'],
                  duration: record['duration'],
                  sets: record['sets'],
                  notes: record['notes'],
                );
            ref.invalidate(exerciseRecordsByDateProvider(_selectedDate));
          },
        ),
      );
    } catch (error, stack) {
      // 로딩 인디케이터 닫기
      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $error')));
    }
  }

  Future<void> _showEditRecordDialog(Map<String, dynamic> record) async {
    final exerciseTypesAsync = ref.read(exerciseTypesProvider);

    exerciseTypesAsync.when(
      data: (exerciseTypes) {
        showDialog(
          context: context,
          builder: (context) => EditExerciseRecordDialog(
            record: record,
            exerciseTypes: exerciseTypes,
            onSave: (updatedRecord) {
              ref
                  .read(exerciseRecordNotifierProvider.notifier)
                  .updateExerciseRecord(updatedRecord);
              ref.invalidate(exerciseRecordsByDateProvider(_selectedDate));
            },
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('운동 종류를 불러오는 중...')));
      },
      error: (error, stack) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $error')));
      },
    );
  }

  Future<void> _deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 운동 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(exerciseRecordNotifierProvider.notifier)
          .deleteExerciseRecord(id);
      ref.invalidate(exerciseRecordsByDateProvider(_selectedDate));
    }
  }
}

class AddExerciseRecordDialog extends StatefulWidget {
  final List<Map<String, dynamic>> exerciseTypes;
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onSave;

  const AddExerciseRecordDialog({
    super.key,
    required this.exerciseTypes,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<AddExerciseRecordDialog> createState() =>
      _AddExerciseRecordDialogState();
}

class _AddExerciseRecordDialogState extends State<AddExerciseRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _durationController = TextEditingController();
  final _setsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  int? _selectedExerciseTypeId;
  Map<String, dynamic>? get _selectedExerciseType =>
      widget.exerciseTypes.firstWhere(
        (e) => e['id'] == _selectedExerciseTypeId,
        orElse: () => widget.exerciseTypes.first,
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운동 기록 추가'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedExerciseTypeId,
                decoration: const InputDecoration(
                  labelText: '운동 선택',
                  border: OutlineInputBorder(),
                ),
                items: widget.exerciseTypes.map((exercise) {
                  return DropdownMenuItem(
                    value: exercise['id'] as int,
                    child: Text(exercise['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExerciseTypeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '운동을 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_selectedExerciseType?['counting_method'] == 'reps') ...[
                if (_selectedExerciseType?['weight_type'] == 'weighted')
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: '무게 (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (_selectedExerciseType?['weight_type'] == 'weighted')
                  const SizedBox(height: 16),
                TextFormField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: '횟수',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '횟수를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _setsController,
                  decoration: const InputDecoration(
                    labelText: '세트 수',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ] else if (_selectedExerciseType?['counting_method'] ==
                  'time') ...[
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: '시간 (초)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '시간을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(onPressed: _saveRecord, child: const Text('저장')),
      ],
    );
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;

    final record = {
      'exerciseTypeId': _selectedExerciseType!['id'] as int,
      'date': widget.selectedDate,
      'weight': _weightController.text.isNotEmpty
          ? double.parse(_weightController.text)
          : null,
      'reps': _repsController.text.isNotEmpty
          ? int.parse(_repsController.text)
          : null,
      'duration': _durationController.text.isNotEmpty
          ? int.parse(_durationController.text)
          : null,
      'sets': _setsController.text.isNotEmpty
          ? int.parse(_setsController.text)
          : null,
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
    };

    widget.onSave(record);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EditExerciseRecordDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> exerciseTypes;
  final Function(Map<String, dynamic>) onSave;

  const EditExerciseRecordDialog({
    super.key,
    required this.record,
    required this.exerciseTypes,
    required this.onSave,
  });

  @override
  State<EditExerciseRecordDialog> createState() =>
      _EditExerciseRecordDialogState();
}

class _EditExerciseRecordDialogState extends State<EditExerciseRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _durationController;
  late final TextEditingController _setsController;
  late final TextEditingController _notesController;

  int? _selectedExerciseTypeId;
  Map<String, dynamic>? get _selectedExerciseType =>
      widget.exerciseTypes.firstWhere(
        (e) => e['id'] == _selectedExerciseTypeId,
        orElse: () => widget.exerciseTypes.first,
      );

  @override
  void initState() {
    super.initState();

    // 기존 데이터로 컨트롤러 초기화
    final weight = widget.record['weight'] as double?;
    final reps = widget.record['reps'] as int?;
    final duration = widget.record['duration'] as int?;
    final sets = widget.record['sets'] as int?;
    final notes = widget.record['notes'] as String?;
    _selectedExerciseTypeId = widget.record['exercise_type_id'] as int;

    _weightController = TextEditingController(text: weight?.toString() ?? '');
    _repsController = TextEditingController(text: reps?.toString() ?? '');
    _durationController = TextEditingController(
      text: duration?.toString() ?? '',
    );
    _setsController = TextEditingController(text: sets?.toString() ?? '1');
    _notesController = TextEditingController(text: notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운동 기록 수정'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedExerciseTypeId,
                decoration: const InputDecoration(
                  labelText: '운동 선택',
                  border: OutlineInputBorder(),
                ),
                items: widget.exerciseTypes.map((exercise) {
                  return DropdownMenuItem(
                    value: exercise['id'] as int,
                    child: Text(exercise['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExerciseTypeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '운동을 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_selectedExerciseType?['counting_method'] == 'reps') ...[
                if (_selectedExerciseType?['weight_type'] == 'weighted')
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: '무게 (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (_selectedExerciseType?['weight_type'] == 'weighted')
                  const SizedBox(height: 16),
                TextFormField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: '횟수',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '횟수를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _setsController,
                  decoration: const InputDecoration(
                    labelText: '세트 수',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ] else if (_selectedExerciseType?['counting_method'] ==
                  'time') ...[
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: '시간 (초)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '시간을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(onPressed: _saveRecord, child: const Text('저장')),
      ],
    );
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;

    final updatedRecord = {
      'id': widget.record['id'],
      'exercise_type_id': _selectedExerciseTypeId,
      'date': widget.record['date'],
      'weight': _weightController.text.isNotEmpty
          ? double.parse(_weightController.text)
          : null,
      'reps': _repsController.text.isNotEmpty
          ? int.parse(_repsController.text)
          : null,
      'duration': _durationController.text.isNotEmpty
          ? int.parse(_durationController.text)
          : null,
      'sets': _setsController.text.isNotEmpty
          ? int.parse(_setsController.text)
          : null,
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
    };

    widget.onSave(updatedRecord);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
