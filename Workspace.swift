import ProjectDescription

let workspace = Workspace(
    name: "SweetHome",
    projects: [
        "Projects/App",
        "Projects/Auth"
    ],
    schemes: [
        .scheme(
            name: "SweetHome",
            shared: true,
            buildAction: .buildAction(targets: [
                .project(path: "Projects/App", target: "SweetHome")
            ])
        ),
        .scheme(
            name: "Auth",
            shared: true,
            buildAction: .buildAction(targets: [
                .project(path: "Projects/Auth", target: "Auth")
            ]),
            testAction: .targets([
                .testableTarget(target: .project(path: "Projects/Auth", target: "AuthTests"))
            ])
        )
    ],
    additionalFiles: [
        "README.md",
        "CLAUDE.md"
    ]
)
