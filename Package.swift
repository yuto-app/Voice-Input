// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceInput",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VoiceInput", targets: ["VoiceInput"])
    ],
    targets: [
        .executableTarget(
            name: "VoiceInput",
            path: "Sources/VoiceInput",
            exclude: [
                "Resources/Info.plist"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/VoiceInput/Resources/Info.plist"
                ])
            ]
        )
    ]
)
