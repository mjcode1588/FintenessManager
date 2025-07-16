import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/weight_provider.dart';

class WeightRecordScreen extends ConsumerWidget {
  const WeightRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightRecordsAsync = ref.watch(weightRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('몸무게 기록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddWeightDialog(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: weightRecordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '몸무게 기록이 없습니다.\n새로운 기록을 추가해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final dateFormat = DateFormat('yyyy년 MM월 dd일');
              final weight = record['weight'] as double;
              final dateStr = record['date'] as String;
              final notes = record['notes'] as String?;
              final date = DateTime.parse(dateStr);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.monitor_weight),
                  ),
                  title: Text(
                    '${weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateFormat.format(date)),
                      if (notes != null && notes.isNotEmpty)
                        Text('메모: $notes'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showEditWeightDialog(context, ref, record),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _showDeleteConfirmDialog(context, ref, record),
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
        error: (error, stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddWeightDialog(
        onSave: (weight, date, notes) {
          ref.read(weightRecordNotifierProvider.notifier).addWeightRecord(
            weight: weight,
            date: date,
            notes: notes,
          );
          ref.invalidate(weightRecordsProvider);
        },
      ),
    );
  }

  void _showEditWeightDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => EditWeightDialog(
        record: record,
        onSave: (updatedRecord) {
          ref.read(weightRecordNotifierProvider.notifier).updateWeightRecord(updatedRecord);
          ref.invalidate(weightRecordsProvider);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> record) {
    final weight = record['weight'] as double;
    final id = record['id'] as int;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: Text('${weight.toStringAsFixed(1)}kg 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(weightRecordNotifierProvider.notifier).deleteWeightRecord(id);
              ref.invalidate(weightRecordsProvider);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('기록이 삭제되었습니다')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class AddWeightDialog extends StatefulWidget {
  final Function(double, DateTime, String?) onSave;

  const AddWeightDialog({super.key, required this.onSave});

  @override
  State<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<AddWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    return AlertDialog(
      title: const Text('몸무게 기록 추가'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '몸무게 (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '몸무게를 입력해주세요';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return '올바른 몸무게를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '날짜',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
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
        TextButton(
          onPressed: _saveWeight,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveWeight() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightController.text);
    final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

    widget.onSave(weight, _selectedDate, notes);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EditWeightDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final Function(Map<String, dynamic>) onSave;

  const EditWeightDialog({
    super.key,
    required this.record,
    required this.onSave,
  });

  @override
  State<EditWeightDialog> createState() => _EditWeightDialogState();
}

class _EditWeightDialogState extends State<EditWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final weight = widget.record['weight'] as double;
    final notes = widget.record['notes'] as String?;
    final dateStr = widget.record['date'] as String;
    
    _weightController = TextEditingController(text: weight.toString());
    _notesController = TextEditingController(text: notes ?? '');
    _selectedDate = DateTime.parse(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    return AlertDialog(
      title: const Text('몸무게 기록 수정'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '몸무게 (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '몸무게를 입력해주세요';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return '올바른 몸무게를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '날짜',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
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
        TextButton(
          onPressed: _saveWeight,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveWeight() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightController.text);
    final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

    final updatedRecord = Map<String, dynamic>.from(widget.record);
    updatedRecord['weight'] = weight;
    updatedRecord['date'] = _selectedDate.toIso8601String();
    updatedRecord['notes'] = notes;

    widget.onSave(updatedRecord);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}