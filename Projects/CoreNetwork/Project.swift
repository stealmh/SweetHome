import ProjectDescription

let project = Project(
    name: "CoreNetwork",
    packages: [
        .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.10.2")),
        .remote(url: "https://github.com/ReactiveX/RxSwift.git", requirement: .upToNextMajor(from: "6.9.0"))
    ],
    targets: [
        .target(
            name: "CoreNetwork",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.sweethome.corenetwork",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .package(product: "Alamofire"),
                .package(product: "RxSwift"),
                .package(product: "RxCocoa")
            ]
        )
    ]
)
