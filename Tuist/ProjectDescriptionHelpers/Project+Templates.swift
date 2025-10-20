import ProjectDescription

public extension Project {
    /// - Feature 모듈 템플릿
    /// - Interface, Implementation, Testing, Tests 타겟 자동 생성
    static func feature(
        name: String,
        dependencies: [TargetDependency] = [],
        hasTesting: Bool = true
    ) -> Project {
        var targets: [Target] = []

        // 1. Interface - Public API (Protocol & Entity)
        targets.append(
            .target(
                name: "\(name)Interface",
                destinations: [.iPhone],
                product: .framework,
                bundleId: "com.sweethome.\(name.lowercased()).interface",
                deploymentTargets: .iOS("16.0"),
                infoPlist: .default,
                sources: ["Interface/Sources/**"],
                dependencies: [
                    .external(name: "RxSwift"),
                    .external(name: "RxCocoa")
                ]
            )
        )

        // 2. Implementation
        targets.append(
            .target(
                name: name,
                destinations: [.iPhone],
                product: .framework,
                bundleId: "com.sweethome.\(name.lowercased())",
                deploymentTargets: .iOS("16.0"),
                infoPlist: .default,
                sources: ["Sources/**"],
                resources: ["Resources/**"],
                dependencies: [
                    .target(name: "\(name)Interface")
                ] + dependencies
            )
        )

        // 3. Testing - Mocks & Fixtures (선택적)
        if hasTesting {
            targets.append(
                .target(
                    name: "\(name)Testing",
                    destinations: [.iPhone],
                    product: .framework,
                    bundleId: "com.sweethome.\(name.lowercased()).testing",
                    deploymentTargets: .iOS("16.0"),
                    infoPlist: .default,
                    sources: ["Testing/Sources/**"],
                    dependencies: [
                        .target(name: "\(name)Interface"),
                        .external(name: "RxSwift"),
                        .external(name: "RxTest")
                    ]
                )
            )
        }

        // 4. Tests
        targets.append(
            .target(
                name: "\(name)Tests",
                destinations: [.iPhone],
                product: .unitTests,
                bundleId: "com.sweethome.\(name.lowercased()).tests",
                deploymentTargets: .iOS("16.0"),
                infoPlist: .default,
                sources: ["Tests/**"],
                dependencies: [
                    .target(name: name),
                    .target(name: "\(name)Testing"),
                    .external(name: "RxTest")
                ]
            )
        )

        return Project(
            name: name,
            targets: targets
        )
    }
}
