# Claude Code Configuration

## Project Overview
SweetHome - iOS 부동산 앱 (Swift/UIKit)

## Architecture
- Clean Architecture (Application, Core, Data, Domain, Presentation)
- MVVM Pattern with RxSwift
- Dependency Injection with DIContainer

## Build & Development Commands

**중요: Claude는 빌드를 수행하지 않습니다.**
- 빌드는 시간이 오래 걸리고 리소스를 많이 사용합니다
- 코드 변경 후 빌드 검증은 사용자가 Xcode에서 직접 수행합니다

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

## Clean Architecture 적용 가이드

### 아키텍처 개요
SweetHome 프로젝트는 **Clean Architecture**를 기반으로 한 계층 분리 구조를 따릅니다.

```
Presentation Layer (UI)
    ↓ (의존)
Domain Layer (비즈니스 로직)
    ↑ (구현)
Data Layer (데이터 접근)
```

### 계층별 책임

#### 1. Domain Layer (도메인 계층)
**위치**: `SweetHome/Domain/`

도메인 계층은 비즈니스 로직의 핵심이며, **다른 계층에 의존하지 않는 순수한 Swift 코드**로 구성됩니다.

**구성 요소:**

1. **Entities** (`Domain/Entities/`)
   - 비즈니스 도메인의 핵심 모델
   - UI 프레임워크나 네트워크 라이브러리에 독립적
   - Hashable 프로토콜 준수 (DiffableDataSource 지원)
   - uniqueID를 통한 고유성 보장

   ```swift
   /// - Community.swift
   struct CommunityPost: Hashable {
       let id: String
       let title: String
       let content: String
       let creator: Creator
       let createdAt: Date

       /// - DiffableDataSource를 위한 고유 ID
       let uniqueID: String

       init(...) {
           // 초기화
           self.uniqueID = UUID().uuidString
       }
   }
   ```

2. **Repository Protocols** (`Domain/Repositories/`)
   - 데이터 접근 인터페이스 정의
   - 구체적인 구현은 Data Layer에 위임
   - RxSwift Observable 반환 (반응형 프로그래밍)

   ```swift
   /// - CommunityRepository.swift
   protocol CommunityRepository {
       /// - 커뮤니티 게시글 목록 조회
       func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse>

       /// - 커뮤니티 게시글 상세 조회
       func fetchPostDetail(postId: String) -> Observable<CommunityPostsDetailResponse>
   }
   ```

3. **UseCase Protocols & Implementations** (`Domain/UseCases/`)
   - 비즈니스 로직의 단위 작업 정의
   - Repository를 의존성 주입받아 사용
   - Data Layer의 Response를 Domain Entity로 변환

   ```swift
   /// - CommunityUseCase.swift (Protocol)
   protocol CommunityUseCase {
       func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]>
       func fetchPostDetail(postId: String) -> Observable<CommunityPostDetail>
   }

   /// - CommunityUseCaseImpl.swift (Implementation)
   final class CommunityUseCaseImpl: CommunityUseCase {
       private let repository: CommunityRepository

       init(repository: CommunityRepository) {
           self.repository = repository
       }

       func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]> {
           /// - Response를 Domain Entity로 변환
           return repository.fetchPosts(request: request)
               .map { $0.data.map { $0.toDomain } }
       }
   }
   ```

#### 2. Data Layer (데이터 계층)
**위치**: `SweetHome/Data/`

데이터 계층은 네트워크, 로컬 저장소 등 실제 데이터 소스와의 통신을 담당합니다.

**구성 요소:**

1. **Models** (`Data/Models/`)
   - API 응답 구조를 정의하는 DTO (Data Transfer Object)
   - Decodable 프로토콜 준수
   - 서버 응답의 snake_case 필드명 유지
   - **toDomain** extension을 통해 Domain Entity로 변환

   ```swift
   /// - CommunityPostsResponse.swift
   struct CommunityPostsResponse: Decodable {
       let data: [CommunityPostsDataResponse]
       let next_cursor: String
   }

   struct CommunityPostsDataResponse: Decodable {
       let post_id: String
       let title: String
       let content: String
       let created_at: String
   }

   //MARK: - Domain Conversion
   extension CommunityPostsDataResponse {
       var toDomain: CommunityPost {
           return CommunityPost(
               id: self.post_id,
               title: self.title,
               content: self.content,
               createdAt: self.created_at.toISO8601Date() ?? Date()
           )
       }
   }
   ```

2. **DataSources/Remote** (`Data/DataSources/Remote/`)
   - API 엔드포인트 정의
   - TargetType 프로토콜 구현 (Alamofire 기반)
   - HTTP 메서드, 파라미터, 헤더 관리

   ```swift
   /// - CommunityEndpoint.swift
   enum CommunityEndpoint: TargetType {
       case posts(parameter: CommunityPostsRequest)
       case postDetail(id: String)

       var path: String {
           switch self {
           case .posts:
               return "/v1/posts/geolocation"
           case let .postDetail(id):
               return "/v1/posts/\(id)"
           }
       }

       var method: HTTPMethod {
           switch self {
           case .posts, .postDetail:
               return .get
           }
       }
   }
   ```

3. **Repositories** (`Data/Repositories/`)
   - Domain의 Repository 프로토콜 구현
   - ApiClient를 통한 네트워크 요청 수행
   - 의존성 주입을 위한 초기화 구현

   ```swift
   /// - CommunityRepositoryImpl.swift
   final class CommunityRepositoryImpl: CommunityRepository {
       private let apiClient: ApiClientProtocol

       init(apiClient: ApiClientProtocol = ApiClient.shared) {
           self.apiClient = apiClient
       }

       func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse> {
           return apiClient.requestObservable(CommunityEndpoint.posts(parameter: request))
       }
   }
   ```

#### 3. Presentation Layer (프레젠테이션 계층)
**위치**: `SweetHome/Presentation/`

UI와 사용자 상호작용을 담당하는 계층입니다.

**구성 요소:**

1. **ViewModel** (`Presentation/[Feature]/ViewModel/`)
   - Input/Output 패턴 구현
   - UseCase를 통한 비즈니스 로직 실행
   - RxSwift를 활용한 반응형 데이터 스트림

   ```swift
   /// - CommunityViewModel.swift
   final class CommunityViewModel: ViewModelable {
       private let useCase: CommunityUseCase

       struct Input {
           let viewDidLoad: Observable<Void>
           let refresh: Observable<Void>
           let itemSelected: Observable<IndexPath>
       }

       struct Output {
           let posts: Driver<[CommunityPost]>
           let isLoading: Driver<Bool>
           let error: Driver<Error>
       }

       /// - 의존성 주입: 기본값으로 구현체 제공
       init(useCase: CommunityUseCase = CommunityUseCaseImpl(
           repository: CommunityRepositoryImpl()
       )) {
           self.useCase = useCase
       }

       func transform(input: Input) -> Output {
           // Input을 Output으로 변환
       }
   }
   ```

2. **ViewController** (`Presentation/[Feature]/View/`)
   - UI 구성 및 사용자 이벤트 처리
   - ViewModel의 Output을 구독하여 UI 업데이트
   - 화면 전환 로직 처리

3. **DataSource & Layout** (`Presentation/[Feature]/DataSource/`, `Layout/`)
   - CollectionView 관련 코드 분리 (별도 섹션 참고)

### 의존성 흐름

```
ViewController
    ↓ (의존)
ViewModel (Input/Output)
    ↓ (의존)
UseCaseImpl
    ↓ (의존)
RepositoryImpl (Data Layer)
    ↓ (의존)
ApiClient / Endpoint
```

**핵심 원칙:**
- 각 계층은 **바로 아래 계층의 인터페이스(Protocol)에만 의존**
- Data Layer는 Domain Layer를 모름 (Domain은 독립적)
- **의존성 주입**을 통해 테스트 가능성 확보

### 파일 생성 가이드 (Community 예시)

새로운 기능을 추가할 때 다음 순서로 파일을 생성합니다:

#### Step 1: Domain Layer
```
1. Domain/Entities/Feature.swift
   - 비즈니스 도메인 모델 정의

2. Domain/Repositories/FeatureRepository.swift
   - 데이터 접근 인터페이스 정의 (Protocol)

3. Domain/UseCases/FeatureUseCase.swift
   - UseCase Protocol 정의

4. Domain/UseCases/FeatureUseCaseImpl.swift
   - UseCase 구현체 (Repository에 의존)
```

#### Step 2: Data Layer
```
5. Data/Models/Feature/FeatureRequest.swift
   - API 요청 파라미터 DTO

6. Data/Models/Feature/FeatureResponse.swift
   - API 응답 DTO + toDomain extension

7. Data/DataSources/Remote/Feature/FeatureEndpoint.swift
   - API 엔드포인트 정의 (TargetType)

8. Data/Repositories/FeatureRepositoryImpl.swift
   - Repository Protocol 구현체
```

#### Step 3: Presentation Layer
```
9. Presentation/Feature/ViewModel/FeatureViewModel.swift
   - Input/Output 패턴 ViewModel

10. Presentation/Feature/View/FeatureViewController.swift
    - UI 구성 및 ViewModel 바인딩

11. Presentation/Feature/DataSource/FeatureDataSource.swift
    - DiffableDataSource 분리

12. Presentation/Feature/Layout/FeatureCollectionViewLayout.swift
    - CompositionalLayout 분리
```

### 네이밍 컨벤션

| 파일 타입 | 네이밍 규칙 | 예시 |
|---------|----------|------|
| Entity | `{Domain}` | `CommunityPost`, `Creator` |
| Repository Protocol | `{Domain}Repository` | `CommunityRepository` |
| Repository Impl | `{Domain}RepositoryImpl` | `CommunityRepositoryImpl` |
| UseCase Protocol | `{Domain}UseCase` | `CommunityUseCase` |
| UseCase Impl | `{Domain}UseCaseImpl` | `CommunityUseCaseImpl` |
| Response DTO | `{Domain}Response` | `CommunityPostsResponse` |
| Request DTO | `{Domain}Request` | `CommunityPostsRequest` |
| Endpoint | `{Domain}Endpoint` | `CommunityEndpoint` |
| ViewModel | `{Feature}ViewModel` | `CommunityViewModel` |

### 테스트 전략

Clean Architecture는 각 계층의 테스트를 용이하게 합니다:

1. **Domain Layer 테스트**
   - Entity 로직 테스트 (Extensions, Computed Properties)
   - UseCase 단위 테스트 (Mock Repository 사용)

2. **Data Layer 테스트**
   - DTO to Domain 변환 테스트
   - Repository 통합 테스트 (Mock ApiClient)

3. **Presentation Layer 테스트**
   - ViewModel Input/Output 테스트 (Mock UseCase)
   - UI 테스트 (XCUITest)

### 마이그레이션 가이드

기존 코드를 Clean Architecture로 마이그레이션할 때:

1. **Entity 추출**: ViewController/ViewModel에서 사용하는 모델을 Domain Entity로 분리
2. **Repository 인터페이스 정의**: 네트워크 호출을 Repository Protocol로 추상화
3. **UseCase 분리**: ViewModel의 비즈니스 로직을 UseCase로 이동
4. **Response to Domain 변환**: DTO와 Entity를 분리하고 toDomain extension 작성
5. **의존성 주입**: init 파라미터로 의존성 전달 (테스트 용이성 확보)

### 참고 구현: Community 모듈

Community 기능은 Clean Architecture의 완전한 구현 예시입니다. 새로운 기능 개발 시 Community 모듈의 구조를 참고하세요:

- **Domain**: `Domain/Entities/Community.swift`, `Domain/Repositories/CommunityRepository.swift`
- **Data**: `Data/Repositories/CommunityRepositoryImpl.swift`, `Data/Models/Community/`
- **Presentation**: `Presentation/Community/ViewModel/CommunityViewModel.swift`

## SOLID 원칙 준수

SweetHome 프로젝트는 **SOLID 원칙**을 철저히 준수하여 유지보수성, 확장성, 테스트 가능성을 확보합니다.

### 1. SRP (Single Responsibility Principle) - 단일 책임 원칙

**원칙**: 클래스는 단 하나의 책임만 가져야 하며, 변경의 이유도 단 하나여야 한다.

**적용 사례:**

```swift
/// ✅ 좋은 예: 각 클래스가 단일 책임을 가짐

/// - CommunityUseCase: 커뮤니티 비즈니스 로직만 담당
final class CommunityUseCaseImpl: CommunityUseCase {
    private let repository: CommunityRepository

    func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]> {
        return repository.fetchPosts(request: request)
            .map { $0.data.map { $0.toDomain } }
    }
}

/// - CommunityRepository: 데이터 접근만 담당
final class CommunityRepositoryImpl: CommunityRepository {
    private let apiClient: ApiClientProtocol

    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse> {
        return apiClient.requestObservable(CommunityEndpoint.posts(parameter: request))
    }
}

/// - CommunityViewModel: UI 로직과 데이터 바인딩만 담당
final class CommunityViewModel: ViewModelable {
    private let useCase: CommunityUseCase

    func transform(input: Input) -> Output {
        // Input을 Output으로 변환하는 UI 로직
    }
}
```

**위반 사례 및 해결책:**

```swift
/// ❌ 나쁜 예: AuthRepository가 너무 많은 책임을 가짐
protocol AuthRepository {
    // 네트워크 요청
    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse>

    // 로컬 저장소 관리
    func saveLoginState(isLoggedIn: Bool)
    func saveTokens(accessToken: String, refreshToken: String)
}

/// ✅ 개선 방안: 책임 분리 권장
/// - AuthRepository: 네트워크 인증만 담당
/// - AuthLocalStorage: 로컬 저장소만 담당
///
/// 현재는 Repository 패턴의 일반적인 관행을 따라
/// 네트워크와 로컬 저장소를 함께 관리하고 있으나,
/// 필요시 AuthLocalStorageProtocol로 분리 가능
```

### 2. OCP (Open/Closed Principle) - 개방/폐쇄 원칙

**원칙**: 소프트웨어 엔티티는 확장에는 열려있고, 수정에는 닫혀있어야 한다.

**적용 사례:**

```swift
/// ✅ Protocol을 통한 확장 가능성

/// - Repository Protocol 정의
protocol CommunityRepository {
    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse>
}

/// - 실제 API 구현
final class CommunityRepositoryImpl: CommunityRepository {
    private let apiClient: ApiClientProtocol

    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse> {
        return apiClient.requestObservable(CommunityEndpoint.posts(parameter: request))
    }
}

/// - Mock 구현 (테스트용) - 기존 코드 수정 없이 확장
final class MockCommunityRepository: CommunityRepository {
    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse> {
        return Observable.just(mockResponse)
    }
}

/// - Cache 구현 - 기존 코드 수정 없이 확장
final class CachedCommunityRepository: CommunityRepository {
    private let apiClient: ApiClientProtocol
    private var cache: [String: CommunityPostsResponse] = [:]

    func fetchPosts(request: CommunityPostsRequest) -> Observable<CommunityPostsResponse> {
        // 캐시 로직 추가
    }
}
```

**TargetType을 통한 Endpoint 확장:**

```swift
/// ✅ TargetType 프로토콜을 준수하여 새로운 Endpoint 추가 가능
enum CommunityEndpoint: TargetType {
    case posts(parameter: CommunityPostsRequest)
    case postDetail(id: String)
    // 새로운 케이스 추가 가능 (기존 코드 수정 없음)
}
```

### 3. LSP (Liskov Substitution Principle) - 리스코프 치환 원칙

**원칙**: 하위 타입은 상위 타입을 대체할 수 있어야 한다.

**적용 사례:**

```swift
/// ✅ Protocol 구현체들은 언제든 교체 가능

/// - UseCase를 사용하는 ViewModel
final class CommunityViewModel: ViewModelable {
    private let useCase: CommunityUseCase  // Protocol 타입

    init(useCase: CommunityUseCase = CommunityUseCaseImpl(
        repository: CommunityRepositoryImpl()
    )) {
        self.useCase = useCase
    }
}

/// - 실제 구현체
final class CommunityUseCaseImpl: CommunityUseCase {
    func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]> {
        // 실제 구현
    }
}

/// - Mock 구현체 (테스트용)
final class MockCommunityUseCase: CommunityUseCase {
    func fetchPosts(request: CommunityPostsRequest) -> Observable<[CommunityPost]> {
        // Mock 데이터 반환
        return Observable.just(mockPosts)
    }
}

/// ✅ ViewModel은 어떤 구현체를 받아도 정상 동작
let viewModel1 = CommunityViewModel(useCase: CommunityUseCaseImpl(...))
let viewModel2 = CommunityViewModel(useCase: MockCommunityUseCase())
```

**계약(Contract) 준수:**

```swift
/// ✅ Protocol의 계약을 모든 구현체가 준수
protocol AuthRepository {
    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse>
}

/// - 실제 구현: 네트워크 요청 후 LoginResponse 반환
class AuthRepositoryImpl: AuthRepository {
    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse> {
        return apiClient.requestObservable(UserEndpoint.emailLogin(request))
    }
}

/// - Mock 구현: 즉시 LoginResponse 반환 (동일한 계약 준수)
class MockAuthRepository: AuthRepository {
    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse> {
        return Observable.just(mockLoginResponse)
    }
}
```

### 4. ISP (Interface Segregation Principle) - 인터페이스 분리 원칙

**원칙**: 클라이언트는 사용하지 않는 인터페이스에 의존하지 않아야 한다.

**적용 사례:**

```swift
/// ✅ 역할별로 분리된 Protocol

/// - 데이터 소스별 Protocol 분리
protocol ApiClientProtocol {
    func requestObservable<T: Decodable>(_ target: TargetType) -> Observable<T>
}

protocol KeyChainManagerProtocol {
    func save(_ key: KeyChainKey, value: String)
    func read(_ key: KeyChainKey) -> String?
    func delete(_ key: KeyChainKey)
}

/// - 소셜 로그인별 Protocol 분리
protocol LoginSessionProtocol {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginResponse>
    func getAppleLoginError() -> Observable<SHError>
    func performKakaoLogin() -> Observable<SocialLoginResponse>
}

/// - 필요시 더 세분화 가능
protocol AppleLoginSessionProtocol {
    func performAppleLogin(presentationContext: ASAuthorizationControllerPresentationContextProviding) -> Observable<SocialLoginResponse>
    func getAppleLoginError() -> Observable<SHError>
}

protocol KakaoLoginSessionProtocol {
    func performKakaoLogin() -> Observable<SocialLoginResponse>
}
```

**개선 권장사항:**

```swift
/// 🔄 AuthRepository는 너무 많은 메서드를 포함
/// - 개선: 역할별로 Protocol 분리 권장

/// - 인증 전용
protocol AuthenticationRepository {
    func loginWithEmail(request: EmailLoginRequest) -> Observable<LoginResponse>
    func loginWithKakao(request: KakaoLoginRequest) -> Observable<LoginResponse>
    func loginWithApple(request: AppleLoginRequest) -> Observable<LoginResponse>
    func refreshToken() -> Observable<ReIssueResponse>
}

/// - 로컬 저장소 전용
protocol AuthStorageRepository {
    func saveLoginState(isLoggedIn: Bool)
    func isLoggedIn() -> Bool
    func saveTokens(accessToken: String, refreshToken: String)
    func clearTokens()
}
```

### 5. DIP (Dependency Inversion Principle) - 의존성 역전 원칙

**원칙**: 상위 모듈은 하위 모듈에 의존하지 않고, 둘 다 추상화에 의존해야 한다.

**적용 사례:**

```swift
/// ✅ 완벽한 DIP 준수 구조

/// [상위 레벨] ViewModel
final class CommunityViewModel: ViewModelable {
    private let useCase: CommunityUseCase  // ← Protocol(추상화)에 의존

    init(useCase: CommunityUseCase = CommunityUseCaseImpl(
        repository: CommunityRepositoryImpl()
    )) {
        self.useCase = useCase
    }
}

/// [중간 레벨] UseCase
final class CommunityUseCaseImpl: CommunityUseCase {
    private let repository: CommunityRepository  // ← Protocol(추상화)에 의존

    init(repository: CommunityRepository) {
        self.repository = repository
    }
}

/// [하위 레벨] Repository
final class CommunityRepositoryImpl: CommunityRepository {
    private let apiClient: ApiClientProtocol  // ← Protocol(추상화)에 의존

    init(apiClient: ApiClientProtocol = ApiClient.shared) {
        self.apiClient = apiClient
    }
}
```

**의존성 방향:**

```
[Presentation Layer]
    CommunityViewModel
        ↓ (의존)
    CommunityUseCase (Protocol) ← 추상화
        ↑ (구현)
    CommunityUseCaseImpl
        ↓ (의존)
    CommunityRepository (Protocol) ← 추상화
        ↑ (구현)
    CommunityRepositoryImpl

✅ 모든 계층이 구체 클래스가 아닌 Protocol(추상화)에 의존
```

**의존성 주입:**

```swift
/// ✅ 생성자 주입(Constructor Injection)으로 DIP 구현

/// - 테스트에서는 Mock 주입
let mockUseCase = MockCommunityUseCase()
let viewModel = CommunityViewModel(useCase: mockUseCase)

/// - 프로덕션에서는 실제 구현체 주입
let realUseCase = CommunityUseCaseImpl(
    repository: CommunityRepositoryImpl(
        apiClient: ApiClient.shared
    )
)
let viewModel = CommunityViewModel(useCase: realUseCase)
```

### SOLID 원칙 체크리스트

새로운 기능을 구현할 때 다음 체크리스트를 확인하세요:

- [ ] **SRP**: 각 클래스가 단일 책임만 가지는가?
- [ ] **OCP**: Protocol을 통해 확장 가능하도록 설계했는가?
- [ ] **LSP**: 구현체를 교체해도 상위 타입처럼 동작하는가?
- [ ] **ISP**: 클라이언트가 사용하지 않는 메서드를 강제하지 않는가?
- [ ] **DIP**: 구체 클래스가 아닌 Protocol(추상화)에 의존하는가?

### SOLID 위반 징후

다음과 같은 징후가 보이면 SOLID 원칙을 재검토하세요:

1. **하나의 클래스를 수정할 때 여러 이유가 있다** → SRP 위반
2. **새로운 기능 추가 시 기존 코드를 수정해야 한다** → OCP 위반
3. **하위 타입이 상위 타입과 다르게 동작한다** → LSP 위반
4. **Protocol의 일부 메서드만 사용한다** → ISP 위반
5. **구체 클래스에 직접 의존한다** → DIP 위반

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
