import ProjectDescription

let project = Project(
    name: "App",
    packages: [
        // MARK: - Reactive Programming
        .remote(url: "https://github.com/ReactiveX/RxSwift.git", requirement: .upToNextMajor(from: "6.9.0")),
        
        // MARK: - Networking
        .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.10.2")),
        .remote(url: "https://github.com/socketio/socket.io-client-swift.git", requirement: .upToNextMajor(from: "16.1.1")),
        
        // MARK: - UI & Layout
        .remote(url: "https://github.com/SnapKit/SnapKit.git", requirement: .upToNextMajor(from: "5.7.1")),
        .remote(url: "https://github.com/onevcat/Kingfisher.git", requirement: .upToNextMajor(from: "8.5.0")),
        
        // MARK: - Kakao SDK
        .remote(url: "https://github.com/kakao/kakao-ios-sdk-rx.git", requirement: .upToNextMajor(from: "2.24.6")),
        .remote(url: "https://github.com/kakao-mapsSDK/KakaoMapsSDK-SPM.git", requirement: .upToNextMajor(from: "2.12.9")),
        
        // MARK: - Firebase
        .remote(url: "https://github.com/firebase/firebase-ios-sdk.git", requirement: .upToNextMajor(from: "12.1.0")),
        
        // MARK: - Payment
        .remote(url: "https://github.com/iamport/iamport-ios.git", requirement: .upToNextMajor(from: "1.4.7"))
    ],
    targets: [
        .target(
            name: "SweetHome",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.sweethome.app",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .file(path: "Resources/Info.plist"),
            sources: ["Sources/**"],
            resources: [
                "Resources/**",
                "Sources/Data/CoreData/SweetHomeData.xcdatamodeld",
                "Sources/Application/Config/xcconfig.xcconfig"
            ],
            entitlements: "Resources/SweetHome.entitlements",
            dependencies: [
                // MARK: - Internal Modules
                // Auth 모듈 의존
                .project(target: "Auth", path: "../Auth"),
                .project(target: "AuthInterface", path: "../Auth"),
                
                // MARK: - External Dependencies
                // Reactive Programming
                    .package(product: "RxSwift"),
                .package(product: "RxCocoa"),
                
                // Networking
                .package(product: "Alamofire"),
                .package(product: "SocketIO"),
                
                // UI & Layout
                .package(product: "SnapKit"),
                .package(product: "Kingfisher"),
                
                // Kakao SDK
//                .package(product: "RxKakaoSDKAuth"),
//                .package(product: "RxKakaoSDKUser"),
//                .package(product: "RxKakaoSDKCommon"),
                .package(product: "KakaoMapsSDK-SPM"),
                
                // Firebase
                .package(product: "FirebaseMessaging"),
                .package(product: "FirebaseCore"),
                
                // Payment
                .package(product: "iamport-ios")
            ],
            settings: .settings(
                base: [
                    "GENERATE_INFOPLIST_FILE": "NO"
                ],
                configurations: [
                    .debug(name: "Debug", xcconfig: .relativeToRoot("Config/key.xcconfig")),
                    .release(name: "Release", xcconfig: .relativeToRoot("Config/key.xcconfig"))
                ]
            )
        )
    ]
)
