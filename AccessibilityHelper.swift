// AccessibilityHelper.swift — GestureKit
// Checks and requests Accessibility permission for the CGEvent tap.

import AppKit
import ApplicationServices

public enum AccessibilityHelper {

    public static var hasPermission: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Opens System Settings → Privacy & Security → Accessibility,
    /// prompting the user to grant access.
    public static func requestPermission() {
        // Passing the prompt key shows a system alert the first time.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Opens the Accessibility pane in System Settings directly.
    public static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
