// GestureRule.swift — GestureKit/Models
// A GestureRule ties a specific gesture (type + zone + finger count)
// to an action. Rules are persisted to JSON.

import Foundation

/// The complete description of a gesture → action mapping.
public struct GestureRule: Codable, Identifiable, Hashable {

    public var id: UUID
    public var name: String             // User-visible label (e.g. "Left scroll → Volume")
    public var isEnabled: Bool
    public var gesture: GestureDescriptor
    public var action: ActionDescriptor
    public var sortOrder: Int           // For drag-to-reorder in ActionsView

    public init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        gesture: GestureDescriptor,
        action: ActionDescriptor,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.gesture = gesture
        self.action = action
        self.sortOrder = sortOrder
    }
}

// MARK: – GestureDescriptor

/// Describes the physical gesture the user performs.
public struct GestureDescriptor: Codable, Hashable {

    /// Category of gesture.
    public var type: GestureType

    /// Which zone of the trackpad must be active.
    public var zoneID: String   // References GestureZone.id

    /// Required number of fingers (1–5). Nil means any.
    public var fingerCount: Int?

    /// For scroll gestures: the minimum delta magnitude to fire.
    public var scrollThreshold: Double

    public init(
        type: GestureType,
        zoneID: String = GestureZone.full.id,
        fingerCount: Int? = nil,
        scrollThreshold: Double = 5.0
    ) {
        self.type = type
        self.zoneID = zoneID
        self.fingerCount = fingerCount
        self.scrollThreshold = scrollThreshold
    }
}

// MARK: – GestureType

/// The physical gesture the user performs.
public enum GestureType: String, Codable, CaseIterable, Hashable {

    // Scroll gestures
    case scrollUp    = "scroll_up"
    case scrollDown  = "scroll_down"
    case scrollLeft  = "scroll_left"
    case scrollRight = "scroll_right"

    // Tap gestures
    case tap         = "tap"
    case doubleTap   = "double_tap"

    // Swipe gestures (with finger count qualifier)
    case swipeUp     = "swipe_up"
    case swipeDown   = "swipe_down"
    case swipeLeft   = "swipe_left"
    case swipeRight  = "swipe_right"

    // Pinch / rotate
    case pinchIn     = "pinch_in"
    case pinchOut    = "pinch_out"
    case rotateLeft  = "rotate_left"
    case rotateRight = "rotate_right"

    public var displayName: String {
        switch self {
        case .scrollUp:    return "Scroll Up"
        case .scrollDown:  return "Scroll Down"
        case .scrollLeft:  return "Scroll Left"
        case .scrollRight: return "Scroll Right"
        case .tap:         return "Tap"
        case .doubleTap:   return "Double Tap"
        case .swipeUp:     return "Swipe Up"
        case .swipeDown:   return "Swipe Down"
        case .swipeLeft:   return "Swipe Left"
        case .swipeRight:  return "Swipe Right"
        case .pinchIn:     return "Pinch In"
        case .pinchOut:    return "Pinch Out"
        case .rotateLeft:  return "Rotate Left"
        case .rotateRight: return "Rotate Right"
        }
    }

    public var symbolName: String {
        switch self {
        case .scrollUp, .swipeUp:     return "arrow.up"
        case .scrollDown, .swipeDown: return "arrow.down"
        case .scrollLeft, .swipeLeft: return "arrow.left"
        case .scrollRight, .swipeRight: return "arrow.right"
        case .tap:                    return "hand.tap"
        case .doubleTap:              return "hand.tap.fill"
        case .pinchIn:                return "arrow.down.right.and.arrow.up.left"
        case .pinchOut:               return "arrow.up.left.and.arrow.down.right"
        case .rotateLeft:             return "arrow.counterclockwise"
        case .rotateRight:            return "arrow.clockwise"
        }
    }
}

// MARK: – ActionDescriptor

/// Describes the action to execute when the gesture fires.
public struct ActionDescriptor: Codable, Hashable {

    public var type: ActionType

    // Optional parameters — which ones are used depends on the action type.
    public var appBundleID: String?      // For launchApp
    public var shortcutName: String?     // For runShortcut
    public var appleScript: String?      // For runAppleScript
    public var keyCode: Int?             // For sendKeyboardShortcut
    public var modifiers: Int?           // For sendKeyboardShortcut (CGEventFlags raw)
    public var parameter: String?        // Generic extra parameter

    public init(
        type: ActionType,
        appBundleID: String? = nil,
        shortcutName: String? = nil,
        appleScript: String? = nil,
        keyCode: Int? = nil,
        modifiers: Int? = nil,
        parameter: String? = nil
    ) {
        self.type = type
        self.appBundleID = appBundleID
        self.shortcutName = shortcutName
        self.appleScript = appleScript
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.parameter = parameter
    }
}

// MARK: – ActionType

/// All action types GestureKit can execute.
public enum ActionType: String, Codable, CaseIterable, Hashable {

    // Media
    case volumeUp        = "volume_up"
    case volumeDown      = "volume_down"
    case volumeMute      = "volume_mute"

    // Display
    case brightnessUp        = "brightness_up"
    case brightnessDown      = "brightness_down"
    case keyboardBacklightUp   = "keyboard_backlight_up"
    case keyboardBacklightDown = "keyboard_backlight_down"

    // Media playback
    case playPause       = "play_pause"
    case nextTrack       = "next_track"
    case previousTrack   = "previous_track"

    // System UI
    case missionControl  = "mission_control"
    case expose          = "expose"
    case launchpad       = "launchpad"

    // App
    case launchApp       = "launch_app"
    case runShortcut     = "run_shortcut"
    case runAppleScript  = "run_applescript"
    case sendKeyShortcut = "send_key_shortcut"

    public var displayName: String {
        switch self {
        case .volumeUp:        return "Volume Up"
        case .volumeDown:      return "Volume Down"
        case .volumeMute:      return "Mute/Unmute"
        case .brightnessUp:          return "Brightness Up"
        case .brightnessDown:        return "Brightness Down"
        case .keyboardBacklightUp:   return "Keyboard Backlight Up"
        case .keyboardBacklightDown: return "Keyboard Backlight Down"
        case .playPause:       return "Play / Pause"
        case .nextTrack:       return "Next Track"
        case .previousTrack:   return "Previous Track"
        case .missionControl:  return "Mission Control"
        case .expose:          return "App Exposé"
        case .launchpad:       return "Launchpad"
        case .launchApp:       return "Launch App…"
        case .runShortcut:     return "Run Shortcut…"
        case .runAppleScript:  return "Run AppleScript…"
        case .sendKeyShortcut: return "Send Keyboard Shortcut…"
        }
    }

    public var symbolName: String {
        switch self {
        case .volumeUp:        return "speaker.wave.3.fill"
        case .volumeDown:      return "speaker.wave.1.fill"
        case .volumeMute:      return "speaker.slash.fill"
        case .brightnessUp:          return "sun.max.fill"
        case .brightnessDown:        return "sun.min.fill"
        case .keyboardBacklightUp:   return "light.max"
        case .keyboardBacklightDown: return "light.min"
        case .playPause:       return "playpause.fill"
        case .nextTrack:       return "forward.fill"
        case .previousTrack:   return "backward.fill"
        case .missionControl:  return "rectangle.3.group.fill"
        case .expose:          return "uiwindow.split.2x1"
        case .launchpad:       return "square.grid.3x3.fill"
        case .launchApp:       return "app.fill"
        case .runShortcut:     return "flowchart.fill"
        case .runAppleScript:  return "applescript.fill"
        case .sendKeyShortcut: return "keyboard.fill"
        }
    }

    /// Actions that require no additional parameters.
    public var requiresParameter: Bool {
        switch self {
        case .launchApp, .runShortcut, .runAppleScript, .sendKeyShortcut:
            return true
        default:
            return false
        }
    }
}
