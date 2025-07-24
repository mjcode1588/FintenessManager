import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/exercise_type.dart';
import '../providers/exercise_provider.dart';
import '../providers/database_provider.dart';
import '../providers/weight_provider.dart';
import '../widgets/add_exercise_record_dialog.dart';
import '../navigation/back_button_mixin.dart';
import '../providers/weight_provider.dart';

class ExerciseRecordScreen extends ConsumerStatefulWidget {
  const ExerciseRecordScreen({super.key});

  @override
  ConsumerState<ExerciseRecordScreen> createState() =>
      _ExerciseRecordScreenState();
}

class _ExerciseRecordScreenState extends ConsumerState<ExerciseRecordScreen> 
    with BackButtonMixin {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy년 MM월 dd일');
  Set<DateTime> _recordedDates = {};

  String? _bodypartextension(String? part) {
    switch (part) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'legs':
        return '다리';
      case 'core':
        return '코어';
      case 'cardio':
        return '유산소';
    }
    return part;
  }

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

    return buildWithBackButton(
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.red.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody(exerciseRecordsAsync)),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade300,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddRecordDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.red.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                return IconButton(
                  onPressed: () async {
                    if (!context.mounted) return;
                    
                    final navigationManager = ref.read(navigationManagerProvider);
                    final result = await navigationManager.handleBackNavigation(context);
                    
                    if (context.mounted) {
                      await navigationManager.executeNavigation(context, result);
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '운동 기록',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  _dateFormat.format(_selectedDate),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              onPressed: _selectDate,
              icon: Icon(Icons.calendar_today, color: Colors.orange.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<Map<String, dynamic>>> exerciseRecordsAsync,
  ) {
    return Column(
      children: [
        // 커스텀 캘린더
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.red.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.orange.shade600,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.orange.shade600,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildMarkers(day, _selectedDate),
                ),
              ),
            ),
          ),
        ),

        // 운동 요약 정보
        exerciseRecordsAsync.when(
          data: (records) {
            if (records.isEmpty) return const SizedBox();

            // 부위별 운동 요약 데이터 계산
            Map<String, Map<String, dynamic>> summaryByBodyPart = {};

            for (var record in records) {
              final bodyPart = record['body_part'] as String? ?? '기타';
              final koreanBodyPart = _bodypartextension(bodyPart) ?? bodyPart;
              final weight = record['weight'] as double?;
              final reps = record['reps'] as int?;
              final sets = record['sets'] as int? ?? 1;
              final duration = record['duration'] as int?;

              if (!summaryByBodyPart.containsKey(koreanBodyPart)) {
                summaryByBodyPart[koreanBodyPart] = {
                  'count': 0,
                  'totalWeight': 0.0,
                  'totalDuration': 0,
                };
              }

              summaryByBodyPart[koreanBodyPart]?['count'] =
                  (summaryByBodyPart[koreanBodyPart]?['count'] ?? 0) + 1;

              if (weight != null) {
                summaryByBodyPart[koreanBodyPart]?['totalWeight'] =
                    (summaryByBodyPart[koreanBodyPart]?['totalWeight'] ?? 0.0) +
                    (weight * (reps ?? 1) * sets);
              }

              if (duration != null) {
                summaryByBodyPart[koreanBodyPart]?['totalDuration'] =
                    (summaryByBodyPart[koreanBodyPart]?['totalDuration'] ?? 0) +
                    duration;
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 운동 요약',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summaryByBodyPart.entries.map((entry) {
                      final totalWeight = entry.value['totalWeight'] as double;
                      final totalDuration = entry.value['totalDuration'] as int;
                      final count = entry.value['count'] as int;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (totalWeight > 0)
                              Text('총 무게: ${totalWeight.toStringAsFixed(1)}kg'),
                            if (totalDuration > 0)
                              Text(
                                '총 시간: ${totalDuration ~/ 60}분 ${totalDuration % 60}초',
                              ),
                            Text('운동 수: ${count}개'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
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
                  final countingMethod = record['counting_method'] as String?;
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
                                      ? (weight != null
                                            ? '${weight.toStringAsFixed(1)}kg (몸무게 기준) × '
                                            : '몸무게 기준 × ')
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
                            onPressed: () => _deleteRecord(record['id'] as int),
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
            error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
          ),
        ),
      ],
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
  late final TextEditingController _notesController;
  int _sets = 1;

  int? _selectedExerciseTypeId;
  Map<String, dynamic>? get _selectedExerciseType =>
      widget.exerciseTypes.firstWhere(
        (e) => e['id'] == _selectedExerciseTypeId,
        orElse: () => widget.exerciseTypes.first,
      );

  @override
  void initState() {
    super.initState();
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
    _notesController = TextEditingController(text: notes ?? '');
    _sets = sets ?? 1;
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
                  if (value == null) return '운동을 선택해주세요';
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
                Row(
                  children: [
                    Expanded(
                      child: Text('세트 수', style: TextStyle(fontSize: 16)),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (_sets > 1) _sets--;
                        });
                      },
                    ),
                    Text(_sets.toString(), style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _sets++;
                        });
                      },
                    ),
                  ],
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
      'sets': _sets,
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
    };
    widget.onSave(updatedRecord);
    Navigator.of(context).pop();
  }

  String? bodypartextension(String? part) {
    switch (part) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'legs':
        return '다리';
      case 'core':
        return '코어';
      case 'cardio':
        return '유산소';
    }
    return null;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
