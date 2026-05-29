// swift-tools-version: 5.10
// Package.swift — GestureKit
//
// Build:   swift build
// Run:     swift run   (or .build/debug/GestureKit)
// Release: swift build -c release
//
// Dependency map:
//   CoreAudio       — AudioObjectGetPropertyData / AudioObjectSetPropertyData (volume)
//   AudioToolbox    — AudioServices (AudioServicesPlaySystemSound etc.)
//   Carbon          — CGEvent, CGKeyCode, keyboard event synthesis
//   ApplicationServices — AXIsProcessTrusted (accessibility check)
//   IOKit           — HID device enumeration for future MultitouchSupport integration
//   AppKit          — NSWorkspace, NSEvent, NSRunningApplication (implicit via SwiftUI)

import PackageDescription

let package = Package(
    name: "GestureKit",
    defaultLocalization: "en",
    platforms: [
        // macOS 13 Ventura required for NavigationSplitView and SwiftUI Form(.grouped).
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "GestureKit",
            targets: ["GestureKit"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "GestureKit",
            dependencies: [],
            // Sources live at the package root — same directory as Package.swift.
            path: ".",
            // Exclude non-Swift items that SPM would otherwise try to compile.
            exclude: [
                "Resources",    // Info.plist + Assets.xcassets — not SPM resource bundles
                "README.md",
                "LICENSE",
                ".gitignore",
            ],

            linkerSettings: [
                // ── Audio ──────────────────────────────────────────────────────────────
                // CoreAudio: AudioObjectGetPropertyData / AudioObjectSetPropertyData
                //            for reading and setting the output device volume.
                .linkedFramework("CoreAudio"),
                // AudioToolbox: AudioServices, AudioServicesPlaySystemSound (alerts/beeps).
                .linkedFramework("AudioToolbox"),

                // ── Display ────────────────────────────────────────────────────────────
                // CoreGraphics: CGEvent, CGDisplayGetDisplayID, CGMainDisplayID.
                // Implicitly linked on macOS but listed here for clarity.
                .linkedFramework("CoreGraphics"),

                // ── Input & Events ─────────────────────────────────────────────────────
                // Carbon: CGKeyCode constants, keyboard event synthesis APIs.
                .linkedFramework("Carbon"),

                // ── Accessibility ──────────────────────────────────────────────────────
                // ApplicationServices: AXIsProcessTrusted / AXIsProcessTrustedWithOptions
                //                     used by AccessibilityHelper.
                .linkedFramework("ApplicationServices"),

                // ── HID / Hardware ─────────────────────────────────────────────────────
                // IOKit: IOHIDManager, IOService enumeration — used by ZoneDetector
                //        and future MultitouchSupport integration.
                .linkedFramework("IOKit"),
            ]
        )
    ]
)
