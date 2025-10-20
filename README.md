# 스위트홈 - 위치 기반 부동산 플랫폼

<img src="https://github.com/user-attachments/assets/5dcd6a48-094f-438b-a433-035ce1c84d04" width="120"/>

> 위치기반 부동산 매물 검색과 예약 결제를 통합한 부동산 플랫폼 앱

**개발 기간**: 2025. 07 - 2025. 09 (2개월) <br>
**팀 구성**: 디자이너, 백엔드, iOS 개발자 등 3명 <br>
**iOS 지원**: iOS 16+

---

## 📱 프로젝트 소개

스위트홈은 위치기반 부동산 매물 검색과 예약 결제를 통합한 부동산 플랫폼 앱입니다.

디자이너, 백엔드, iOS 개발자 등 3명이 2개월간 개발을 진행했으며 현재까지 유지보수 및 기능 개선을 이어나가고 있습니다.

---

## 🎯 주요 기능

- **위치기반 부동산 매물 검색**
- **실시간 채팅 기능 제공**
- **지도 내 매물 밀도에 따른 클러스터링**
- **부동산 매물 예약 및 결제 시스템 구현**
- **매물 즐겨찾기, 최근 검색 매물 저장**
- **커뮤니티 기능 제공**
- **소셜로그인 제공**(kakao, apple)

---

## 📸 스크린샷

<div style="display: flex; justify-content: space-around;">
  <img src="https://github.com/user-attachments/assets/c3a89825-c6d5-48d0-86ed-f18ec39d35f2" alt="홈 화면" width="200"/>
  <img src="https://github.com/user-attachments/assets/561033ce-3281-426a-a1d2-2fd161435743" alt="커뮤니티" width="200"/>
  <img src="https://github.com/user-attachments/assets/7227ea38-df43-4582-9366-466c74b52e93" alt="채팅" width="200"/>
</div>

<div style="display: flex; justify-content: space-around; margin-top: 20px;">
  <img src="https://github.com/user-attachments/assets/542476e4-e35b-430c-b916-2fe354409612" alt="매물 상세" width="200"/>
  <img src="https://github.com/user-attachments/assets/a61630ab-3098-4334-8da6-881db6e765c8" alt="지도" width="200"/>
  <img src="https://github.com/user-attachments/assets/2bf58ad8-27ce-448e-808a-4f9ecb6ccb8e" alt="채팅 목록" width="200"/>
</div>

---

## 🛠 기술 스택

### Foundation
- UIkit
- XCTest
- Swift Concurrency
- AVFoundation

### Reactive
- RxSwift

### Network
- Alamofire
- Socket.IO

### UI
- SnapKit
- Kingfisher

### Architecture
- MVVM + Clean Architecture

### Database
- CoreData

---

## 🏗 아키텍처

### Rx기반 MVVM + Clean Architecture

본 프로젝트에서는 RxSwift를 사용하여 MVVM 패턴을 적용하고 클린아키텍처로 관심사를 분리하였습니다.

비동기 데이터 스트림 처리, 테스트 가능한 코드 구조, 그리고 각 계층 간의 명확한 의존성 분리를 통해 유지보수성과 확장성을 높이고자 하였습니다.

### 아키텍처 흐름

```
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│  Presentation Layer │ ───> │    Domain Layer     │ <─── │     Data Layer      │
│                     │      │                     │      │                     │
│  - ViewController   │      │  - UseCase          │      │  - Repository       │
│  - ViewModel        │      │  - Entities         │      │  - DTOs             │
│  - View             │      │  - Protocol         │      │  - Network Layer    │
│                     │      │                     │      │  - Local Layer      │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘
```

사용자의 입력 이벤트는 ViewController에서 ViewModel로 전달되고, ViewModel은 Domain Layer의 UseCase를 통해 비즈니스 로직을 처리합니다.

처리된 데이터는 Repository를 거쳐 Data Layer에서 관리되며, 결과는 RxSwift의 Observable을 통해 다시 View로 전달되어 UI를 업데이트합니다.

---

## 💡 주요 기술 구현

### 1. JWT 기반 로그인 인증 - Actor를 통한 토큰 동시성 문제 해결

#### 문제 상황
앱 시작 시 홈 화면에서 오늘의 매물, 인기 매물, 토픽 등 N개의 API를 동시에 호출하는데, 모든 API가 토큰 만료(419) 응답을 받으면 각각이 독립적으로 토큰갱신을 시도하는 문제가 발생했습니다. 이로 인해 서버에 N번의 중복 토큰 갱신 요청이 발생했습니다.

#### 해결 방법
기존 Alamofire의 TokenInterceptor에서 토큰 관리 로직을 분리하였습니다. NSLock, 세마포어 같은 전통적인 동시성 제어 방식은 데드락의 위험이 있고 코드가 복잡해지는 문제가 있었습니다.

안전한 동시성 모델로 컴파일 시점에 동시성 오류를 방지할 수 있는 **Actor**를 적용했습니다.

#### Actor 도입 효과
- 토큰 갱신 상태를 체크하고 설정하는 과정이 **원자적으로 처리**
- 여러 스레드에서 동시에 토큰 갱신을 요청해도, Actor 내부에서는 순차적으로 처리
- 첫 번째 요청이 갱신을 시작하면, 나머지 요청들은 자동으로 대기 큐에 들어가서 갱신 완료를 기다림

---

### 2. GitHub Actions을 통한 CI/CD 환경 구축

GitHub Actions를 통해 배포까지의 파이프라인을 구축했습니다.

#### Test Pipeline
```
Code Push → PR Open → Workflow 트리거 → Check out → Config 설정(Git Secrets)
→ Xcode 세팅 → 시뮬레이터 실행 → 테스트 검증
```

#### Deploy Pipeline
```
Check out → Config 설정(Git Secrets) → Xcode 세팅 → Build 검증 → 배포
```

- PR시 자동으로 테스트가 실행되어 코드 품질을 검증
- 메인 브랜치 혹은 Develop 브랜치로 병합이 완료되면 Release 빌드 후 Appstore/Testflight 배포 프로세스가 시작
- XCConfig 파일, Firebase 설정, API 키 등의 민감한 정보는 **GitHub Secrets**로 암호화하여 저장
- CI 실행 시점에 동적으로 설정 파일을 생성하여 보안을 강화

---

### 3. 동시성 테스트 환경 구축

동시성 로직은 본질적으로 예측하기 어렵고 간헐적으로 문제가 나타나는 경우가 많기 때문에 실제 상황을 재현할 수 있는 테스트가 필수적이었습니다.

기존 클린 아키텍처를 적극 활용해 프로토콜을 통한 Mock List를 만들 수 있었습니다.

#### Mock 구성 요소

**1. KeyChain - 키체인 I/O 시뮬레이션**
- iOS의 KeyChain 대신 메모리 기반 저장소를 제공하여 토큰 저장과 조회 로직을 테스트
- 각 메서드 호출 횟수를 추적하는 기능을 제공하여 TokenManager가 키체인에 얼마나 자주 접근하는지 검증

**2. Network - API 호출 시뮬레이션**
- 실제 서버 API 호출 없이 토큰 갱신 네트워크 로직을 테스트할 수 있도록 Mock 응답을 제공
- 성공/실패 시나리오를 자유롭게 제어하고 네트워크 지연 시간을 시뮬레이션
- API 호출 횟수를 추적하여 동시성 처리 시 중복 호출이 발생하지 않는지 확인

**3. Session - Alamofire Session 모킹**
- 실제 HTTP 요청 없이 Alamofire의 RequestInterceptor 동작을 테스트
- TokenInterceptor가 HTTP 요청에 Authorization 헤더를 올바르게 추가하는지 검증
- 네트워크 환경에 의존하지 않고도 인터셉터의 요청 어댑팅과 재시도 로직을 안정적으로 테스트

#### 테스트 커버리지
- **Token Concurrency Tests**: 동시성 제어 로직 100% 커버리지
- **Token Manager Tests**: 토큰 관리 시스템 약 95% 커버리지
- **Token Interceptor Tests**: Alamofire 통합 부분 약 90% 커버리지

---

### 4. Actor 재진입성 문제 해결

#### 문제 발견
테스트를 거치며 예상치 못한 문제를 발견했습니다. 토큰 갱신이 여전히 두 번 호출되는 경우가 있었습니다.

Actor 메서드에서 `await`를 호출하는 순간 Actor가 일시 중단되고, 이 틈에 다른 요청이 들어와서 아직 갱신이 시작되지 않은 것으로 판단하고 갱신을 시작하는 것이었습니다.

#### 해결 방법
기존의 "체크 후 실행" 방식에서 **"예약 후 조건부 실행"** 방식으로 전환했습니다.

- 모든 요청을 먼저 대기 큐에 등록
- 갱신 조건을 원자적으로 체크하여 실행 여부를 결정
- 상태 변경 로직을 단일 지점으로 집중
- 토큰 갱신 플래그 설정과 실제 갱신 작업의 시작 사이에 suspension point가 없도록 구조를 재설계

#### 배운 점
Actor는 데이터 격리를 통해 레이스 컨디션을 방지하지만, 완벽한 원자성을 보장하지는 못했습니다.

특히 `await` 호출이 포함된 복잡한 로직에서는 재진입성으로 인해 예상치 못한 동작이 발생할 수 있습니다.

그러나 중요한 것은 한계를 인정하고 적절한 패턴으로 보완하는 것이였습니다. 상태 변경의 순서를 조정하고, 포괄적인 테스트를 통해 이런 엣지 케이스들을 미리 발견하고 대응할 수 있었습니다.

---

### 5. KakaoMap 클러스터링 구현

부동산 앱의 특성상 사용자가 넓은 지역에서 상세 지역까지 다양하게 탐색하므로, 줌 레벨에 따라 다른 클러스터링 전략을 사용했습니다.

#### 1. 광역 뷰 (Zoom Level 0 - 12) - Grid 클러스터링

<div style="display: flex; justify-content: space-around; margin-top: 20px;">
  <img src="https://github.com/user-attachments/assets/e42fa239-4b67-4744-9802-8d48da37486d" alt="그리드1" width="200"/>
  <img src="https://github.com/user-attachments/assets/b491f597-b2c3-4e80-a09d-3871e4d7e32a" alt="그리드2" width="200"/>
</div>

**전략**
- 지도를 가상의 격자로 나누어 클러스터링을 수행
- 각 매물의 위/경도 좌표를 격자 좌표로 변환해서 같은 격자 셀에 속한 매물들을 하나의 클러스터로 묶음

**장점**
- O(n)의 시간복잡도로 매물 수가 증가하더라도 성능이 선형적으로만 증가
- 격자 단위로 균등하게 클러스터가 배치되어 직관적
- 어느 동네에 매물이 많은지 직관적으로 파악 가능
- 격자 내 모든 매물의 평균 위치를 클러스터 중심으로 설정해 실제 매물 분포의 무게중심을 반영

#### 2. 중간 뷰 (Zoom Level 13 - 15) - 거리 기반 클러스터링

<div style="display: flex; justify-content: space-around; margin-top: 20px;">
  <img src="https://github.com/user-attachments/assets/137ae1a1-2849-4600-b7e3-31c013971820" alt="클러1" width="200"/>
  <img src="https://github.com/user-attachments/assets/97b8f190-4fd5-4c1d-bf91-4e5b0f201acc" alt="클러2" width="200"/>
</div>

**전략**
- DBSCAN의 거리 기반 클러스터링과 중복 처리를 위한 방문체크, 인접한 매물들의 순차적 확장 방식만 차용
- 지구 곡률을 고려한 정확한 거리 계산을 사용하여 실제 물리적 거리 기반으로 클러스터링
- 성능이 중요한 상황에서는 유클리드 거리를 통해 근사치 계산을 활용
- 최대 3번 반복하여 클러스터링 이후에도 가까운 클러스터가 있다면 추가로 병합

**특징**
- 부동산 매물들은 모두 의미있는 데이터이기 때문에 DBSCAN의 노이즈 개념은 불필요
- 사용자는 지역별 매물 현황을 파악하면서도 일부 개별 매물들을 확인 가능
- 개별 매물 탐색으로 자연스럽게 전환 가능

#### 3. 상세 뷰 (Zoom Level 16+) - 클러스터링 비활성화

<div style="display: flex; justify-content: space-around; margin-top: 20px;">
  <img src="https://github.com/user-attachments/assets/3783f489-0439-42d7-8da6-5a396935d859" alt="상세1" width="200"/>
  <img src="https://github.com/user-attachments/assets/980449cd-d284-4453-be93-32f8ec0f115c" alt="상세2" width="200"/>
</div>

**전략**
- 개별 마커만 표시
- 사용자가 지도를 확대한 상태에서는 개별 매물의 정확한 위치, 가격, 상세정보를 제공
- 개별 마커를 터치해 매물 정보에 바로 접근 가능

**최적화**
- 개별 마커 이미지를 캐싱하여 스크롤 시 부드러운 렌더링 보장
- 사용자가 지도를 이동할 때마다 해당 영역의 매물만 로드해서 메모리 사용량을 제어
- UIGraphicsImageRenderer의 포맷을 명시적으로 지정하고 CPU 기반 렌더링으로 수정하여 안전한 이미지 생성

---

### 6. 채팅에서의 데이터 소스 우선순위 문제

#### 문제 상황
실시간 메시지 수신과 서버 채팅 기록 조회가 별도로 작동하다 보니, 같은 메시지가 두 번 나타나거나 아예 누락되는 경우가 발생했습니다.

기존 콜백 방식으로 소켓, REST API, 로컬 DB 간의 데이터 흐름을 관리하면서 상태 변화 추적이 어려웠습니다.

#### 우선순위 설정

**1. CoreData (최우선)**
- 즉시 응답 가능한 로컬 캐시 역할
- 사용자가 채팅방에 진입하자마자 기존 메시지들을 빠르게 표시

**2. Socket.IO (실시간 채널)**
- 새로운 메시지 수신과 전송을 담당

**3. REST API (보조 및 동기화)**
- 초기 데이터 로딩과 네트워크 재연결 시 누락된 메시지를 보완

#### 메시지 수신 흐름
- 새로운 메시지가 도착할 때는 Socket을 통해 실시간으로 수신되어 즉시 UI에 표시되고 동시에 CoreData에 저장
- 네트워크 연결이 불안정하거나 앱이 백그라운드에 있다가 포그라운드로 복귀할 때는 REST API를 통해 누락된 메시지들을 일괄 조회하여 CoreData와 동기화

#### 메시지 송신 플로우
- 사용자가 메시지를 전송할 때는 즉시 CoreData에 임시 저장하여 사용자에게 빠른 피드백을 제공
- REST API를 통해 서버로 전송
- 서버 전송이 성공하면 임시 메시지를 정식 메시지로 업데이트하고, 실패하면 재전송 표시나 에러 상태로 변경
- **Optimistic UI 패턴**으로 네트워크 지연과 관계없이 매끄러운 채팅 경험을 제공

#### 통합 반응형 데이터 스트림 구성
- 모든 데이터 소스를 Observable 스트림으로 통합하여 관리
- 소켓 메시지, REST API 응답, 로컬 DB 변경사항을 동일한 반응형 패턴으로 처리
- BehaviorSubject와 PublishSubject를 활용한 중앙집중식 상태 관리
- flatMap과 filter 연산자로 중복 메시지를 자동 제거
- NSPredicate 기반 고유 ID 필터링으로 새로운 메시지만 저장

#### 결과
- 데이터 일관성이 완전히 보장되어 메시지 중복과 누락 문제가 해결
- 선언적 방식으로 복잡한 비동기 로직을 표현할 수 있어 코드 가독성과 유지보수성이 향상
- 오프라인에서도 이전 채팅을 볼 수 있으며 온라인 복귀 시 자동으로 누락된 메시지가 복구

---

### 7. 기타 기능 구현 사항

#### 실시간 웨이브폼 최적화

<div style="display: flex; justify-content: space-around; margin-top: 20px;">
  <img src="https://github.com/user-attachments/assets/0defe468-9e88-4227-b4bd-a38a99feb2c1" alt="웨이브폼1" width="200"/>
  <img src="https://github.com/user-attachments/assets/f5c32d55-4db0-44aa-8547-23c6a8dd35fc" alt="웨이브폼2" width="200"/>
</div>

**구현 내용**
- 장시간 녹음 시 메모리 급증 방지를 위해 녹음 상태 막대를 **60개로 제한**
- **FIFO 방식의 슬라이딩 윈도우**를 적용하여 녹음 시간과 무관하게 일정한 메모리 사용량을 유지
- AVAudioRecorder의 averagePower(-60dB~0dB)를 0.0~1.0으로 정규화하여 막대 높이에 매핑
- CGAffineTransform 기반 스케일 애니메이션과 알파 변화를 조합하여 부드러운 실시간 전환 효과 구현

#### 송/수신 음성 파일 처리 정책
- **송신 파일**: 서버 업로드 완료 즉시 로컬에서 삭제
- **수신 파일**: 사용자 경험을 위해 캐싱, 재생용 임시 파일은 재생 완료 후 자동 삭제

#### 음성의 품질과 파일 크기의 균형점 모색

**포맷 선택: MPEG4-AAC**
- WAV/PCM: 무압축 포맷으로 파일 크기가 10배 이상 커짐
- MP3: 동일 비트레이트상 AAC가 더 나은 품질을 제공하며, iOS에서는 하드웨어 가속 지원으로 AAC의 인코딩 및 디코딩 성능이 우수

**샘플링 레이트: 44.1kHz**
- 8-22.05kHz: 통화 수준의 음질로 고음역대 손실로 인한 목소리 명료도 저하
- 48kHz: 과도한 품질과 파일 크기 증가 대비 체감되는 품질 향상이 미미
- **44.1kHz**: CD 품질의 음질을 가져가기에 충분하고 대부분의 모바일 스피커에서 재생 가능

#### 위치 기반 게시글 필터링

<div style="display: flex; justify-content: space-around; margin-top: 20px;">
  <img src="https://github.com/user-attachments/assets/eb757688-437f-4b8c-85da-7b9315c8419a" alt="위치1" width="200"/>
  <img src="https://github.com/user-attachments/assets/e6d436c3-6984-403e-a2da-d6ed4435296e" alt="위치2" width="200"/>
</div>

**구현 내용**
- 모든 커뮤니티 게시글에 경도(longitude)와 위도(latitude) 정보를 포함
- 커뮤니티 글 검색 시 geolocation 값을 필수 요소로 기입
- 게시글 작성 시 사용자의 현재 위치가 자동으로 태깅
- 정확한 주소가 아닌 대략적인 지역 정보(~3km)만 공유되도록 처리하여 사용자의 개인정보를 보호
- 사용자의 현재 위치를 기준으로 반경 내의 게시글만 표시

#### 이미지 캐싱 시스템
- **메모리 캐싱**: NSCache로 최근 조회 이미지를 즉시 표시
- **디스크 캐싱**: Documents 디렉토리 기반으로 앱 재시작 후에도 네트워크 요청 없이 이미지를 불러옴
- **downsample**: 표시 크기에 맞게 리샘플링하여 메모리 사용량을 최대 70% 감소
- **adaptiveCompress**: 파일 크기를 1MB 이하로 제한하면서도 시각적 품질을 유지
- **LRU 기반 캐시 정책**: 메모리 워닝 시 오래된 캐시를 자동 정리
- 디스크 캐시는 일주일 단위로 만료 처리하여 저장공간을 효율적으로 관리
