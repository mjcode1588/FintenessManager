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
  /* 기존 목록 */
  { 'name': '바벨 벤치프레스',            'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '인클라인 바벨 벤치프레스',    'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '데드리프트',                 'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '풀업',                       'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '바벨로우',                   'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '사이드 레터럴 레이즈',       'category': 'weight', 'bodyPart': 'shoulders', 'countingMethod': 'reps' },
  { 'name': '바이셉 컬',                 'category': 'weight', 'bodyPart': 'arms',      'countingMethod': 'reps' },
  { 'name': '트라이셉 딥스',             'category': 'weight', 'bodyPart': 'arms',      'countingMethod': 'reps' },
  { 'name': '스쿼트',                     'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '레그프레스',                 'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '플랭크',                     'category': 'weight', 'bodyPart': 'core',      'countingMethod': 'time' },
  { 'name': '크런치',                     'category': 'weight', 'bodyPart': 'core',      'countingMethod': 'reps' },
  { 'name': '러닝',                       'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '사이클링',                   'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '로잉머신',                   'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '푸쉬업',                     'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '펙덱 플라이',               'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '랫풀 다운',                 'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '케이블 시티드 로우',         'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '프론트 로우',               'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '레그 익스텐션',             'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '인클라인 덤벨 벤치프레스',   'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '케이블 하이 로우',           'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '덤벨 숄더 프레스',           'category': 'weight', 'bodyPart': 'shoulders', 'countingMethod': 'reps' },
  { 'name': '머신 숄더 프레스',           'category': 'weight', 'bodyPart': 'shoulders', 'countingMethod': 'reps' },
  { 'name': '트라이셉 푸쉬 다운',         'category': 'weight', 'bodyPart': 'arms',      'countingMethod': 'reps' },

  /* 추가된 23개 */
  { 'name': '버피',                       'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '힙 쓰러스트',               'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '불가리안 스플릿 스쿼트',     'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '카프 레이즈',               'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '레그 컬',                   'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '밀리터리 프레스',           'category': 'weight', 'bodyPart': 'shoulders', 'countingMethod': 'reps' },
  { 'name': '케이블 크로스오버',         'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '체스트 프레스 머신',         'category': 'weight', 'bodyPart': 'chest',     'countingMethod': 'reps' },
  { 'name': '스텝업',                     'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '점핑 잭',                   'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '점프 로프',                 'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '마운틴 클라이머',           'category': 'cardio', 'bodyPart': 'core',      'countingMethod': 'time' },
  { 'name': '워킹 런지',                 'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' },
  { 'name': '사이드 플랭크',             'category': 'weight', 'bodyPart': 'core',      'countingMethod': 'time' },
  { 'name': '행잉 레그 레이즈',           'category': 'weight', 'bodyPart': 'core',      'countingMethod': 'reps' },
  { 'name': '하이니즈',                 'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': '배틀 로프',                 'category': 'cardio', 'bodyPart': 'cardio',    'countingMethod': 'time' },
  { 'name': 'TRX 로우',                  'category': 'weight', 'bodyPart': 'back',      'countingMethod': 'reps' },
  { 'name': '해머 컬',                   'category': 'weight', 'bodyPart': 'arms',      'countingMethod': 'reps' },
  { 'name': '트라이셉 킥백',             'category': 'weight', 'bodyPart': 'arms',      'countingMethod': 'reps' },
  { 'name': '페이스 풀',                 'category': 'weight', 'bodyPart': 'shoulders', 'countingMethod': 'reps' },
  { 'name': '리버스 플라이',             'category': 'weight', 'bodyPart': 'shoulders', 'countingMethod': 'reps' },
  { 'name': '힙 어브덕션 머신',           'category': 'weight', 'bodyPart': 'legs',      'countingMethod': 'reps' }
];
}