// GestureKitApp.swift — GestureKit
// SwiftUI App entry point.
// Uses the @main attribute with App protocol + NSApplicationDelegateAdaptor
// to integrate with AppKit for menu bar (NSStatusItem) support.
//
// SwiftPM note: The @main attribute works with executables in SPM as long as
// this file is the only one with a top-level entry point.

import SwiftUI

@main
struct GestureKitApp: App {

    // Bridge to AppDelegate so we can set up the NSStatusItem menu bar icon
    // and perform Objective-C lifecycle calls (addObserver, etc.).
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Primary settings window — opened from the menu bar icon.
        WindowGroup("GestureKit Settings", id: "settings") {
            SettingsWindow()
                .frame(minWidth: 860, minHeight: 520)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 820, height: 580)
        .commands {
            // GestureKit has no "New Window" concept — remove the default command.
            CommandGroup(replacing: .newItem) {}
        }
    }
}
