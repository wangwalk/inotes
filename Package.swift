// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "inotes",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "INotesCore", targets: ["INotesCore"]),
    .executable(name: "inotes", targets: ["inotes"]),
  ],
  dependencies: [
    .package(url: "https://github.com/steipete/Commander.git", from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "INotesCore",
      dependencies: []
    ),
    .executableTarget(
      name: "inotes",
      dependencies: [
        "INotesCore",
        .product(name: "Commander", package: "Commander"),
      ],
      exclude: [
        "Resources/Info.plist",
      ],
      linkerSettings: [
        .unsafeFlags([
          "-Xlinker", "-sectcreate",
          "-Xlinker", "__TEXT",
          "-Xlinker", "__info_plist",
          "-Xlinker", "Sources/inotes/Resources/Info.plist",
        ]),
      ]
    ),
    .testTarget(
      name: "INoteCoreTests",
      dependencies: ["INotesCore"],
      swiftSettings: [
        .unsafeFlags([
          "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
        ])
      ],
      linkerSettings: [
        .linkedFramework("Testing")
      ]
    ),
    .testTarget(
      name: "inotesTests",
      dependencies: ["inotes", "INotesCore"],
      swiftSettings: [
        .unsafeFlags([
          "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
        ])
      ],
      linkerSettings: [
        .linkedFramework("Testing")
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
