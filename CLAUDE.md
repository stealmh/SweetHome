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

## Development Notes
- iOS 최소 버전 확인 필요
- Kakao Maps API 키 설정 확인
- Firebase 설정 파일 (GoogleService-Info.plist) 확인
- 결제 모듈 테스트 시 샌드박스 환경 사용