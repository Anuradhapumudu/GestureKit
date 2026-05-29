// AccessibilityHelper.swift — GestureKit
// Checks and requests Accessibility permission for the CGEvent tap.

import AppKit
import ApplicationServices

public enum AccessibilityHelper {

    public static var hasPermission: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        if AXIsProcessTrustedWithOptions(options as CFDictionary) {
            return true
        }
        
        // macOS TCC Database Caching Bug Fallback:
        // Sometimes AXIsProcessTrusted returns false even after the user checks the box.
        // We can bypass the cache by directly attempting to create a dummy event tap.
        // If it succeeds, we definitively have permission.
        guard let dummyTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: 1 << CGEventType.mouseMoved.rawValue,
            callback: { proxy, type, event, userInfo in return Unmanaged.passRetained(event) },
            userInfo: nil
        ) else {
            return false
        }
        
        // It succeeded! Clean up the dummy tap and return true.
        CFMachPortInvalidate(dummyTap)
        return true
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
