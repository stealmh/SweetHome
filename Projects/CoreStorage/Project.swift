import ProjectDescription

let project = Project(
    name: "CoreStorage",
    targets: [
        .target(
            name: "CoreStorage",
            destinations: [.iPhone],
            product: .framework,
            bundleId: "com.sweethome.corestorage",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: []
        )
    ]
)
