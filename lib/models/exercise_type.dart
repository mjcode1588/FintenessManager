enum ExerciseCategory {
  weight,
  cardio,
}

enum WeightType {
  bodyweight,
  weighted,
}

enum BodyPart {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  cardio,
}

enum CountingMethod {
  reps,
  time,
}

// 기본 운동 종류 데이터
class DefaultExercises {
  static const List<Map<String, dynamic>> exercises = [
    // 가슴
    {
      'name': '벤치프레스',
      'category': 'weight',
      'bodyPart': 'chest',
      'countingMethod': 'reps'
    },
    {
      'name': '인클라인 벤치프레스',
      'category': 'weight',
      'bodyPart': 'chest',
      'countingMethod': 'reps'
    },
    {
      'name': '푸시업',
      'category': 'weight',
      'bodyPart': 'chest',
      'countingMethod': 'reps'
    },
    
    // 등
    {
      'name': '데드리프트',
      'category': 'weight',
      'bodyPart': 'back',
      'countingMethod': 'reps'
    },
    {
      'name': '풀업',
      'category': 'weight',
      'bodyPart': 'back',
      'countingMethod': 'reps'
    },
    {
      'name': '바벨로우',
      'category': 'weight',
      'bodyPart': 'back',
      'countingMethod': 'reps'
    },
    
    // 어깨
    {
      'name': '숄더프레스',
      'category': 'weight',
      'bodyPart': 'shoulders',
      'countingMethod': 'reps'
    },
    {
      'name': '사이드 레터럴 레이즈',
      'category': 'weight',
      'bodyPart': 'shoulders',
      'countingMethod': 'reps'
    },
    
    // 팔
    {
      'name': '바이셉 컬',
      'category': 'weight',
      'bodyPart': 'arms',
      'countingMethod': 'reps'
    },
    {
      'name': '트라이셉 딥스',
      'category': 'weight',
      'bodyPart': 'arms',
      'countingMethod': 'reps'
    },
    
    // 다리
    {
      'name': '스쿼트',
      'category': 'weight',
      'bodyPart': 'legs',
      'countingMethod': 'reps'
    },
    {
      'name': '레그프레스',
      'category': 'weight',
      'bodyPart': 'legs',
      'countingMethod': 'reps'
    },
    
    // 코어
    {
      'name': '플랭크',
      'category': 'weight',
      'bodyPart': 'core',
      'countingMethod': 'time'
    },
    {
      'name': '크런치',
      'category': 'weight',
      'bodyPart': 'core',
      'countingMethod': 'reps'
    },
    
    // 유산소
    {
      'name': '러닝',
      'category': 'cardio',
      'bodyPart': 'cardio',
      'countingMethod': 'time'
    },
    {
      'name': '사이클링',
      'category': 'cardio',
      'bodyPart': 'cardio',
      'countingMethod': 'time'
    },
    {
      'name': '로잉머신',
      'category': 'cardio',
      'bodyPart': 'cardio',
      'countingMethod': 'time'
    },
  ];
}