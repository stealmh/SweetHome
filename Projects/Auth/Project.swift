import ProjectDescription

let project = Project(
    name: "Auth",
    packages: [
        // MARK: - Reactive Programming
        .remote(url: "https://github.com/ReactiveX/RxSwift.git", requirement: .upToNextMajor(from: "6.9.0")),

        // MARK: - Networking
        .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.10.2")),

        // MARK: - Kakao SDK
        .remote(url: "https://github.com/kakao/kakao-ios-sdk-rx.git", requirement: .upToNextMajor(from: "2.24.6"))
    ],
    targets: [
        // =======================================
        // 1. AuthInterface - Public API (Protocol만)
        // =======================================
        .target(
            name: "AuthInterface",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.sweethome.auth.interface",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Interface/Sources/**"],
            dependencies: [
                .package(product: "RxSwift"),
                .package(product: "RxCocoa")
            ]
        ),

        // =======================================
        // 2. Auth - Implementation (구현체)
        // =======================================
        .target(
            name: "Auth",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.sweethome.auth",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                // Interface 의존
                .target(name: "AuthInterface"),

                // Core 모듈 의존
                .project(target: "CoreNetwork", path: "../CoreNetwork"),

                // External 의존성
                .package(product: "RxSwift"),
                .package(product: "RxCocoa"),
                .package(product: "Alamofire"),
                .package(product: "RxKakaoSDKAuth"),
                .package(product: "RxKakaoSDKUser"),
                .package(product: "RxKakaoSDKCommon")
            ]
        ),

        // =======================================
        // 3. AuthTesting - Mock & Test Helpers
        // =======================================
        .target(
            name: "AuthTesting",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.sweethome.auth.testing",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Testing/Sources/**"],
            dependencies: [
                .target(name: "AuthInterface"),
                .package(product: "RxSwift"),
                .package(product: "RxTest")
            ]
        ),

        // =======================================
        // 4. AuthTests - Unit Tests
        // =======================================
        .target(
            name: "AuthTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.sweethome.auth.tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "Auth"),
                .target(name: "AuthTesting"),
                .package(product: "RxTest")
            ]
        )
    ]
)
