# Claude Code Configuration

## Project Overview
SweetHome - iOS 부동산 앱 (Swift/UIKit)

## Architecture
- Clean Architecture (Application, Core, Data, Domain, Presentation)
- MVVM Pattern with RxSwift
- Dependency Injection with DIContainer

## Build & Development Commands
```bash
# Xcode에서 빌드 및 실행
xcodebuild -workspace SweetHome.xcodeproj -scheme SweetHome -configuration Debug build
xcodebuild -workspace SweetHome.xcodeproj -scheme SweetHome -destination 'platform=iOS Simulator,name=iPhone 15' test

# 시뮬레이터에서 실행
open -a Simulator
```

## Dependencies
- **RxSwift/RxCocoa** - Reactive Programming
- **Alamofire** - Networking
- **SnapKit** - Auto Layout
- **Kingfisher** - Image Loading
- **SocketIO** - Real-time Communication
- **KakaoSDK** - Kakao Login/Maps
- **Firebase** - Push Notifications, Analytics
- **iamport-ios** - Payment Integration

## Project Structure
```
SweetHome/
├── Application/        # App lifecycle, configuration
├── Core/              # DI, Base classes, Notifications
├── Data/              # Repositories, Network, Local storage
├── Domain/            # Entities, Use cases, Protocols
├── Presentation/      # ViewControllers, Views, ViewModels
├── Resources/         # Assets, Strings, Storyboards
└── XCConfig/         # Build configurations
```

## Key Features
- 부동산 매물 검색 및 지도 표시
- 카카오 로그인 연동
- 실시간 채팅 (Socket.IO)
- 푸시 알림 (Firebase)
- 결제 시스템 (iamport)

## Testing
```bash
# Unit Tests
xcodebuild -workspace SweetHome.xcodeproj -scheme SweetHome -destination 'platform=iOS Simulator,name=iPhone 15' test

# UI Tests
xcodebuild -workspace SweetHome.xcodeproj -scheme SweetHome -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:SweetHomeUITests
```

## Git Workflow
- Main branch: `main`
- Feature branches: `feature/#issue-description`
- Current branch: `feature/#24-test`

## Code Conventions

### CollectionView 구조
CollectionView의 DiffableDataSource와 CompositionalLayout을 ViewController에서 분리하여 책임을 나눕니다.

**파일 구조:**
```
DataSource/
└── DomainNameDataSource.swift

Layout/
└── DomainCollectionViewLayout.swift
```

**예시:**
- `DataSource/PropertyListDataSource.swift` - 매물 목록의 DiffableDataSource
- `Layout/PropertyCollectionViewLayout.swift` - 매물 목록의 CompositionalLayout
- `DataSource/ChatRoomDataSource.swift` - 채팅방 목록의 DiffableDataSource
- `Layout/ChatRoomCollectionViewLayout.swift` - 채팅방 목록의 CompositionalLayout

이를 통해 ViewController는 비즈니스 로직에 집중하고, UI 구성 요소들은 별도 파일에서 관리합니다.

### Auto Layout 규칙
- **모든 UI 배치는 SnapKit을 사용**하여 구현합니다.
- **방향성 제약조건**에서는 `left`, `right` 대신 **`leading`, `trailing`**을 사용합니다.
- 다국어 지원을 위해 RTL(Right-to-Left) 언어에 대응할 수 있도록 합니다.

**예시:**
```swift
// ✅ 권장 - $0 패턴 사용
view.snp.makeConstraints {
    $0.leading.equalToSuperview().offset(16)
    $0.trailing.equalToSuperview().offset(-16)
    $0.top.bottom.equalToSuperview()
}

// ❌ 지양 - left/right 사용
view.snp.makeConstraints {
    $0.left.equalToSuperview().offset(16)
    $0.right.equalToSuperview().offset(-16)
    $0.top.bottom.equalToSuperview()
}
```

### ViewModel 구조
- **Input/Output 패턴**을 사용하여 ViewModel을 구현합니다.
- Input은 View에서 ViewModel로의 이벤트를 정의합니다.
- Output은 ViewModel에서 View로의 데이터 스트림을 정의합니다.

**예시:**
```swift
final class PropertyListViewModel {
    struct Input {
        let viewDidLoad: Observable<Void>
        let refresh: Observable<Void>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let properties: Observable<[Property]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }

    func transform(input: Input) -> Output {
        // Input을 Output으로 변환하는 로직
    }
}
```

### 주석 컨벤션
- **일반 주석**은 `/// - ...` 형식으로 통일합니다.
- **MARK 주석**은 extension에서만 `//MARK: - ...` 형식으로 사용합니다.

**예시:**
```swift
/// - HomeViewModel: 홈 화면의 비즈니스 로직을 담당
/// - Input/Output 패턴으로 구현
final class HomeViewModel {
    /// - 뷰에서 전달되는 이벤트들
    struct Input {
        let viewDidLoad: Observable<Void>
    }

    /// - 뷰모델에서 방출하는 데이터 스트림들
    struct Output {
        let properties: Observable<[Property]>
    }
}

//MARK: - ViewModelable
extension HomeViewModel: ViewModelable {
    func transform(input: Input) -> Output {
        // 구현
    }
}
```

## Development Notes
- iOS 최소 버전 확인 필요
- Kakao Maps API 키 설정 확인
- Firebase 설정 파일 (GoogleService-Info.plist) 확인
- 결제 모듈 테스트 시 샌드박스 환경 사용

## Xcode 최적화 팁
### 인덱싱 문제 해결
```bash
# DerivedData 정리
rm -rf ~/Library/Developer/Xcode/DerivedData

# Xcode 캐시 정리
rm -rf ~/Library/Caches/com.apple.dt.Xcode*

# 프로젝트 클린 빌드
xcodebuild clean -scheme SweetHome
```

### 테스트 실행
```bash
# SweetHomeTests 스킴으로 테스트 실행
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)'

# 특정 테스트만 실행
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/HomeViewModelTests
```

### Xcode 설정 권장사항
- Xcode → Preferences → Locations → Derived Data → Advanced → Relative to Derived Data 선택
- Editor → Minimap 비활성화 (대용량 프로젝트에서 성능 향상)
- 불필요한 시뮬레이터 제거

## Extensions 테스트
프로젝트의 Core/Extensions에 있는 Extension들에 대한 포괄적인 테스트가 구현되어 있습니다.

### 테스트된 Extensions

#### Foundation Extensions
- **StringExtensionTests** (`SweetHomeTests/Extensions/StringExtensionTests.swift`)
  - 이메일 유효성 검사 (`isValidEmail`)
  - 전화번호 유효성 검사 (`isValidPhone`)
  - 비밀번호 유효성 검사 (`isValidPassword`, `passwordValidationMessage`)
  - ISO8601 날짜 변환 (`toISO8601Date`)

- **IntExtensionTests** (`SweetHomeTests/Extensions/IntExtensionTests.swift`)
  - 천단위 콤마 포맷팅 (`formattedWithComma`)
  - 가격 포맷팅 (`formattedPrice`) - 만원/억 단위 변환
  - 단위 포함 가격 포맷팅 (`formattedPriceWithUnit`)
  - **주의사항**: `formattedPrice`에서 반올림 정확성 개선 (1억1원 → "1억")

- **EncodableExtensionTests** (`SweetHomeTests/Extensions/EncodableExtensionTests.swift`)
  - Codable 구조체를 Dictionary로 변환 (`toDictionary`)
  - 중첩 객체, 배열, 옵셔널 값 처리 검증

#### UIKit Extensions
- **UIViewExtensionTests** (`SweetHomeTests/Extensions/UIViewExtensionTests.swift`)
  - 다중 서브뷰 추가 (`addSubviews`)
  - 캡슐 모양 스타일링 (`makeCapsule`, `updateCapsuleShape`)
  - UIStackView arranged subviews 추가 (`addArrangeSubviews`)

- **UIColorExtensionTests** (`SweetHomeTests/Extensions/UIColorExtensionTests.swift`)
  - Hex 문자열로 UIColor 생성 (`init(hex:)`)
  - 3자리, 6자리, 8자리 hex 지원
  - 대소문자, 프리픽스(#, 0x) 처리
  - 브랜드 색상 및 실제 사용 케이스 테스트

#### RxSwift Extensions
- **ObservableTypeExtensionTests** (`SweetHomeTests/Extensions/ObservableTypeExtensionTests.swift`)
  - SHError 변환 (`catchSHError`)
  - 에러 로깅 (`logError`)
  - 네트워크 에러 처리 시나리오 테스트

### 테스트 실행 명령어
```bash
# Extension 테스트만 실행
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/StringExtensionTests
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/IntExtensionTests
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/UIViewExtensionTests
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/UIColorExtensionTests

# 모든 Extension 테스트 실행
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/Extensions
```

### Extension 개발 가이드라인
1. **테스트 우선 개발**: Extension 수정 시 관련 테스트를 먼저 확인하고 업데이트
2. **경계값 테스트**: 특히 숫자/문자열 처리에서 경계값과 예외 케이스 검증 필수
3. **성능 테스트**: 반복 호출이 많은 Extension은 성능 테스트 포함
4. **실제 사용 케이스**: 브랜드 색상, 실제 가격 등 현실적인 테스트 데이터 사용

### 알려진 이슈
- **formattedPrice 반올림 정확성**: 기존 부동소수점 정확도 문제를 해결하여 1억1원이 "1.0억" 대신 "1억"으로 표시되도록 수정됨

## Token 관련 테스트
JWT 액세스/리프레시 토큰 관리와 Alamofire 인터셉터 기능에 대한 포괄적인 테스트가 구현되어 있습니다.

### 테스트된 Token 모듈들

#### TokenManager Tests (`SweetHomeTests/Token/TokenManagerTests.swift`)
**핵심 토큰 상태 관리 및 갱신 로직 테스트**
- **상태 관리**: 초기 상태, 갱신 중 상태, 토큰 만료 상태 관리
- **토큰 갱신**: startRefresh(), finishRefresh(), 중복 갱신 방지
- **대기 요청 관리**: pendingRequests 추가/처리/취소
- **HTTP 헤더 관리**: Authorization 헤더 자동 추가
- **에러별 재시도 로직**:
  - `419`: 액세스 토큰 만료 → 토큰 갱신 시도
  - `401, 403, 418`: 리프레시 토큰 만료 → 로그아웃 처리
  - 기타: 재시도하지 않음
- **통합 플로우**: 전체 토큰 갱신 프로세스 검증

#### TokenInterceptor Tests (`SweetHomeTests/Token/TokenInterceptorTests.swift`)
**Alamofire RequestInterceptor 구현 테스트**
- **Request Adapter**: HTTP 요청에 Authorization 헤더 자동 추가
- **Request Retry**: HTTP 응답 상태 코드별 재시도 로직
- **TokenManager 위임**: 모든 토큰 로직을 TokenManager에게 위임
- **Edge Cases**: HTTP 응답 없음, 잘못된 요청 처리
- **Mock 테스트**: Alamofire Request/Response 모킹
- **Singleton 패턴**: TokenInterceptor.shared 인스턴스 관리

#### AuthTokenManager Tests (`SweetHomeTests/Token/AuthTokenManagerTests.swift`)
**토큰 캐싱 및 편의 기능 테스트**
- **토큰 캐싱**: 키체인에서 로딩 후 메모리 캐싱으로 성능 최적화
- **SeSAC Key 관리**: API 상수 키 캐싱
- **캐시 관리**: refreshCache(), clearCache() 동작
- **알림 처리**: 토큰 만료 알림 수신 시 캐시 자동 클리어
- **성능 테스트**: 반복 조회 시 캐싱 효과 검증
- **Singleton vs Custom**: shared instance와 커스텀 인스턴스 비교

### Token 아키텍처
```
TokenInterceptor (Alamofire 계층)
    ↓ 위임
TokenManager (비즈니스 로직)
    ↓ 의존성
AuthTokenManager (캐싱 계층)
    ↓ 의존성
KeyChainManager (저장소 계층)
```

### 테스트 실행 명령어
```bash
# Token 관련 테스트만 실행
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/TokenManagerTests
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/TokenInterceptorTests
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/AuthTokenManagerTests

# 모든 Token 테스트 실행
xcodebuild test -scheme SweetHomeTests -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' -only-testing:SweetHomeTests/Token
```

### Token 테스트 특징
1. **Actor 기반 동시성**: TokenManager의 actor 구현 테스트
2. **비동기 처리**: async/await를 활용한 토큰 갱신 테스트
3. **Alamofire 모킹**: 실제 네트워크 없이 인터셉터 동작 검증
4. **키체인 모킹**: MockKeychainManager로 저장소 계층 분리
5. **알림 테스트**: NotificationCenter 기반 토큰 만료 처리
6. **성능 테스트**: 캐싱 효과와 반복 조회 성능 측정

### Token 보안 고려사항
- **토큰 만료 처리**: 자동 갱신 및 로그아웃 플로우
- **메모리 보안**: 캐시 클리어 시 민감 정보 제거
- **동시성 안전**: Actor를 통한 스레드 안전 보장
- **재시도 제한**: 무한 재시도 방지 로직
