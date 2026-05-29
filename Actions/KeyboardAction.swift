// KeyboardAction.swift — GestureKit/Actions
// Simulates keyboard shortcuts and media keys using CGEvent and NSEvent.
// Also contains MediaKeyAction, SystemUIAction, and AppLaunchAction.

import Foundation
import AppKit
import CoreGraphics
import Carbon

// MARK: – KeyboardAction

public enum KeyboardAction {

    /// Post a synthetic key-down + key-up pair to the HID event tap.
    /// - Parameters:
    ///   - keyCode: The CGKeyCode (virtual key code).
    ///   - modifierFlags: A bitmask of CGEventFlags raw value.
    public static func sendKey(keyCode: Int, modifierFlags: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        let flags = CGEventFlags(rawValue: UInt64(modifierFlags))

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}

// MARK: – MediaKeyAction

/// Sends NX_SYSDEFINED media key events (play/pause, next, previous track).
public enum MediaKeyAction {

    public enum Key: Int {
        case volumeUp         = 0
        case volumeDown       = 1
        case brightnessUp     = 2
        case brightnessDown   = 3
        case mute             = 7
        case playPause        = 16
        case nextTrack        = 17
        case previousTrack    = 18
        case fastForward      = 19
        case rewind           = 20
        case illuminationUp   = 21
        case illuminationDown = 22
    }

    /// Post a media key press (key-down then key-up).
    public static func sendKey(_ key: Key) {
        postMediaKey(key, isDown: true)
        postMediaKey(key, isDown: false)
    }

    private static func postMediaKey(_ key: Key, isDown: Bool) {
        let keyCode = Int32(key.rawValue)
        // key-down: 0xa00, key-up: 0xb00  (NX event masks)
        let eventMask: Int32 = isDown ? 0xa00 : 0xb00
        let data1 = Int((keyCode << 16) | eventMask)

        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,   // NX_SUBTYPE_AUX_CONTROL_BUTTONS
            data1: data1,
            data2: -1
        )
        event?.cgEvent?.post(tap: .cghidEventTap)
    }
}

// MARK: – SystemUIAction

/// Triggers macOS system UI features via CGEvent or NSWorkspace.
public enum SystemUIAction {

    /// Open Mission Control.
    public static func missionControl() {
        sendExpose(mode: 1)
    }

    /// Trigger App Exposé for the frontmost application.
    public static func appExpose() {
        sendExpose(mode: 2)
    }

    /// Open Launchpad.
    public static func launchpad() {
        let ws = NSWorkspace.shared
        if let url = ws.urlForApplication(withBundleIdentifier: "com.apple.launchpad.launcher") {
            ws.open(url)
        } else {
            // Fallback: F4 equivalent key code
            KeyboardAction.sendKey(keyCode: 131, modifierFlags: 0)
        }
    }

    // Mission Control / App Exposé are triggered via SkyLight private framework.
    // CGSInvokeSymbolicHotKey constants: 32 = Mission Control, 33 = App Exposé
    private static func sendExpose(mode: Int32) {
        let skyLightPath = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
        guard let handle = dlopen(skyLightPath, RTLD_LAZY) else {
            fallbackExpose(mode: mode)
            return
        }
        defer { dlclose(handle) }

        typealias InvokeFn = @convention(c) (Int32) -> Void
        guard let sym = dlsym(handle, "CGSInvokeSymbolicHotKey") else {
            fallbackExpose(mode: mode)
            return
        }

        let invoke = unsafeBitCast(sym, to: InvokeFn.self)
        invoke(mode == 1 ? 32 : 33)
    }

    private static func fallbackExpose(mode: Int32) {
        // F3 = Mission Control (key code 160), F10 = App Exposé (key code 101)
        let keyCode = mode == 1 ? 160 : 101
        KeyboardAction.sendKey(keyCode: keyCode, modifierFlags: 0)
    }
}

// MARK: – AppLaunchAction

public enum AppLaunchAction {

    public static func launch(bundleIdentifier: String) async {
        let ws = NSWorkspace.shared
        if let url = ws.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            do {
                try await ws.openApplication(at: url, configuration: config)
            } catch {
                print("[AppLaunchAction] Failed to launch \(bundleIdentifier): \(error)")
            }
        } else {
            print("[AppLaunchAction] App not found: \(bundleIdentifier)")
        }
    }
}
