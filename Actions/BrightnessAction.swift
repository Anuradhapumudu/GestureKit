// BrightnessAction.swift — GestureKit/Actions
// Controls display brightness using the CoreDisplay private framework.
// Falls back to a shell command if the private API is unavailable.

import Foundation
import AppKit
import CoreGraphics

public enum BrightnessAction {

    // MARK: – Public API

    /// Change brightness by `delta` in [−1, +1]. One step ≈ 0.0625.
    public static func adjustBrightness(delta: Double) {
        if !adjustViaCoreDisplay(delta: delta) {
            adjustViaKeyPress(increase: delta > 0)
        }
    }

    // MARK: – CoreDisplay (private framework)

    // CoreDisplay.framework provides direct brightness control for built-in displays.
    // We dynamically load it to avoid a hard dependency on a private framework.

    private static func adjustViaCoreDisplay(delta: Double) -> Bool {
        let coreDisplayPath =
            "/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay"
        guard let handle = dlopen(coreDisplayPath, RTLD_LAZY) else { return false }
        defer { dlclose(handle) }

        typealias GetBrightnessFn = @convention(c) (UInt32) -> Double
        typealias SetBrightnessFn = @convention(c) (UInt32, Double) -> Void

        guard
            let getSym = dlsym(handle, "CGDisplayGetDisplayBrightness"),
            let setSym = dlsym(handle, "CGDisplaySetDisplayBrightness")
        else { return false }

        let getBrightness = unsafeBitCast(getSym, to: GetBrightnessFn.self)
        let setBrightness = unsafeBitCast(setSym, to: SetBrightnessFn.self)

        // CGMainDisplayID() is in CoreGraphics (imported above).
        let displayID = CGMainDisplayID()
        let current = getBrightness(displayID)
        let newValue = min(max(current + delta, 0), 1)
        setBrightness(displayID, newValue)

        return true
    }

    // MARK: – Key press fallback

    // Simulate pressing the brightness hardware key using NSEvent system-defined events.
    // NX_KEYTYPE_BRIGHTNESS_UP = 1, NX_KEYTYPE_BRIGHTNESS_DOWN = 2
    private static func adjustViaKeyPress(increase: Bool) {
        let keyType: UInt32 = increase ? 1 : 2
        sendSystemDefinedKey(keyType: keyType)
    }

    private static func sendSystemDefinedKey(keyType: UInt32) {
        // NX_SUBTYPE_AUX_CONTROL_BUTTONS = 8
        // Key-down mask = 0xa00, key-up mask = 0xb00
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyType << 16) | 0xa00),
            data2: -1
        )
        keyDown?.cgEvent?.post(tap: .cghidEventTap)

        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: NSPoint.zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0),
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyType << 16) | 0xb00),
            data2: -1
        )
        keyUp?.cgEvent?.post(tap: .cghidEventTap)
    }
}
