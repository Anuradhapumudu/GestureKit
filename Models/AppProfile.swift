// AppProfile.swift — GestureKit/Models
// Represents a per-application gesture profile.
// When a specific app is frontmost, its profile overrides the global rules.

import Foundation
import AppKit

/// A named set of gesture rules that activates when a specific app is frontmost.
public struct AppProfile: Codable, Identifiable, Hashable {

    public var id: UUID
    public var appBundleID: String          // e.g. "com.apple.Safari"
    public var appName: String              // Display name
    public var isEnabled: Bool
    public var rules: [GestureRule]         // Rules specific to this app

    public init(
        id: UUID = UUID(),
        appBundleID: String,
        appName: String,
        isEnabled: Bool = true,
        rules: [GestureRule] = []
    ) {
        self.id = id
        self.appBundleID = appBundleID
        self.appName = appName
        self.isEnabled = isEnabled
        self.rules = rules
    }

    // MARK: – Helpers

    /// Returns the app icon from the bundle, if available.
    public var appIcon: NSImage? {
        NSWorkspace.shared.icon(forFile: appPath ?? "")
    }

    /// Tries to find the installed path of the app.
    public var appPath: String? {
        NSWorkspace.shared
            .urlForApplication(withBundleIdentifier: appBundleID)?
            .path
    }
}
