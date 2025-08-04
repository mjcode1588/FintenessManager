# Implementation Plan

- [x] 1. NavigationManager 핵심 클래스 구현


  - 네비게이션 히스토리 추적 및 관리 기능을 가진 NavigationManager 클래스 작성
  - 뒤로가기 동작 결정 로직 구현 (이전 화면으로 이동, 홈으로 이동, 앱 종료 등)
  - 라우트 히스토리 스택 관리 및 메모리 효율적인 데이터 구조 사용
  - _Requirements: 1.1, 2.1, 2.2_


- [ ] 2. NavigationState 데이터 모델 구현
  - NavigationState 클래스와 BackNavigationResult enum 정의
  - 네비게이션 상태를 나타내는 데이터 구조 작성
  - 뒤로가기 결과를 표현하는 열거형과 결과 클래스 구현


  - _Requirements: 2.1, 2.3_

- [ ] 3. BackButtonMixin 표준화 믹스인 생성
  - 모든 화면에서 사용할 수 있는 뒤로가기 처리 믹스인 작성


  - PopScope 설정을 표준화하는 헬퍼 메서드 구현
  - 화면별 커스텀 뒤로가기 동작을 지원하는 인터페이스 제공
  - _Requirements: 3.1, 3.2_



- [ ] 4. HomeExitHandler 앱 종료 처리 구현
  - 홈 화면에서의 더블 탭 종료 로직 구현
  - 종료 확인 스낵바 표시 및 타이머 관리 기능 작성
  - 2초 내 재입력 감지 및 앱 종료 처리 로직 구현


  - _Requirements: 1.3, 4.1_

- [ ] 5. NavigationWrapper 전역 래퍼 위젯 구현
  - 앱 전체 네비게이션을 관리하는 래퍼 위젯 작성

  - NavigationManager를 Provider로 제공하는 구조 구현
  - 전역 뒤로가기 이벤트 감지 및 처리 로직 추가
  - _Requirements: 2.1, 3.1_

- [-] 6. GoRouter 설정 개선

  - 기존 GoRouter 설정에서 canPop: false 제거
  - 자연스러운 네비게이션 히스토리를 위한 라우트 구조 개선
  - 부모-자식 라우트 관계를 명확히 설정하여 계층적 네비게이션 지원
  - _Requirements: 1.1, 2.2, 2.3_

- [ ] 7. 홈 화면 뒤로가기 처리 적용
  - HomeWrapper에서 기존 PopScope 로직을 새로운 시스템으로 교체
  - BackButtonMixin을 사용하여 표준화된 뒤로가기 처리 적용
  - 앱 종료 확인 로직을 HomeExitHandler로 분리하여 적용
  - _Requirements: 1.2, 1.3, 3.1_

- [x] 8. 하위 화면들의 뒤로가기 처리 개선

  - ExerciseListScreen, ExerciseRecordScreen 등 모든 하위 화면의 PopScope 수정
  - context.go('/') 대신 자연스러운 뒤로가기 동작으로 변경
  - BackButtonMixin을 각 화면에 적용하여 일관된 동작 보장
  - _Requirements: 1.1, 3.1, 3.2_


- [ ] 9. 네비게이션 히스토리 추적 기능 구현
  - 라우트 변경 시 히스토리 업데이트 로직 추가
  - GoRouter의 라우트 변경 이벤트를 감지하여 히스토리 관리
  - 메모리 효율성을 위한 히스토리 크기 제한 및 정리 로직 구현
  - _Requirements: 2.1, 2.2, 4.2_


- [ ] 10. 에러 처리 및 폴백 로직 구현
  - 유효하지 않은 라우트나 네비게이션 오류 시 홈으로 폴백하는 로직 작성
  - NavigationManager에서 예외 상황 처리 및 안전한 네비게이션 보장
  - 컨텍스트 유효성 검사 및 안전한 네비게이션 실행 로직 추가


  - _Requirements: 2.3, 4.1, 4.3_

- [ ] 11. 단위 테스트 작성
  - NavigationManager의 핵심 로직에 대한 단위 테스트 작성


  - BackButtonMixin의 동작을 검증하는 테스트 구현
  - 다양한 네비게이션 시나리오에 대한 테스트 케이스 작성
  - _Requirements: 4.1, 4.2_




- [ ] 12. 위젯 테스트 작성
  - PopScope 동작과 뒤로가기 버튼 상호작용 테스트 구현
  - 홈 화면 앱 종료 플로우 테스트 작성
  - 스낵바 표시 및 사용자 인터랙션 테스트 구현
  - _Requirements: 1.3, 3.1, 4.1_

- [ ] 13. 통합 테스트 및 최종 검증
  - 전체 네비게이션 플로우에 대한 통합 테스트 작성
  - 다양한 화면 간 이동 시나리오 테스트 구현
  - 실제 사용자 시나리오를 모방한 end-to-end 테스트 작성
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2_