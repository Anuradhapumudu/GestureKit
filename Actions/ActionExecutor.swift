// ActionExecutor.swift — GestureKit/Actions
// Dispatches ActionDescriptor values to the appropriate action implementation.
// Each action type has a dedicated file (VolumeAction, BrightnessAction, etc.)
// that performs the actual system call.

import Foundation

@MainActor
public final class ActionExecutor {

    public static let shared = ActionExecutor()
    nonisolated private init() {}

    /// Execute the described action asynchronously.
    public func execute(action: ActionDescriptor) async {
        switch action.type {
        case .volumeUp:       MediaKeyAction.sendKey(.volumeUp)
        case .volumeDown:     MediaKeyAction.sendKey(.volumeDown)
        case .volumeMute:     MediaKeyAction.sendKey(.mute)

        case .brightnessUp:          MediaKeyAction.sendKey(.brightnessUp)
        case .brightnessDown:        MediaKeyAction.sendKey(.brightnessDown)

        case .keyboardBacklightUp:   MediaKeyAction.sendKey(.illuminationUp)
        case .keyboardBacklightDown: MediaKeyAction.sendKey(.illuminationDown)

        case .playPause:      MediaKeyAction.sendKey(.playPause)
        case .nextTrack:      MediaKeyAction.sendKey(.nextTrack)
        case .previousTrack:  MediaKeyAction.sendKey(.previousTrack)

        case .missionControl: SystemUIAction.missionControl()
        case .expose:         SystemUIAction.appExpose()
        case .launchpad:      SystemUIAction.launchpad()

        case .launchApp:
            if let bundleID = action.appBundleID {
                await AppLaunchAction.launch(bundleIdentifier: bundleID)
            }

        case .runShortcut:
            if let name = action.shortcutName {
                await ShortcutAction.run(name: name)
            }

        case .runAppleScript:
            if let script = action.appleScript {
                await AppleScriptAction.run(source: script)
            }

        case .sendKeyShortcut:
            if let keyCode = action.keyCode {
                let modifiers = action.modifiers ?? 0
                KeyboardAction.sendKey(keyCode: keyCode, modifierFlags: modifiers)
            }
        }
    }
}
