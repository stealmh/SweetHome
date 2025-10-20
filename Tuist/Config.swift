import ProjectDescription

let config = Config(
    swiftVersion: "5.9",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: true,
        disablePackageVersionLocking: false
    )
)
