class WeightRecord {
  final int id;
  final DateTime date;
  final double weight; // kg
  final String? notes; // 메모

  const WeightRecord({
    required this.id,
    required this.date,
    required this.weight,
    this.notes,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      weight: json['weight'] as double,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'notes': notes,
    };
  }
}