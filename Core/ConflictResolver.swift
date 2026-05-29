// ConflictResolver.swift — GestureKit/Core
// Detects when a user-defined gesture would conflict with a built-in macOS system gesture
// and either suppresses the user gesture or warns the user.
//
// Known macOS system gestures (Ventura+):
//   2-finger scroll (anywhere)    — natural scroll
//   2-finger pinch (anywhere)     — zoom
//   3-finger swipe up/down        — Mission Control / App Exposé  (if enabled in System Settings)
//   4-finger swipe left/right     — Switch Spaces
//   2-finger swipe left/right     — Back/Forward in browsers
//   Force click                   — Look up / data detectors
//
// Strategy: flag conflicts as warnings in the UI; we do NOT block the user from
// adding conflicting rules (power users may want to override), but we warn them.

import Foundation

public final class ConflictResolver {

    public static let shared = ConflictResolver()
    private init() {}

    // MARK: – System gesture definitions

    private struct SystemGesture {
        let type: GestureType
        let fingerCount: Int?       // nil = any finger count
        let zoneID: String?         // nil = any zone
        let description: String
    }

    private let systemGestures: [SystemGesture] = [
        // Two-finger scroll — universal, cannot conflict
        SystemGesture(type: .scrollUp,   fingerCount: 2, zoneID: nil, description: "2-finger scroll"),
        SystemGesture(type: .scrollDown, fingerCount: 2, zoneID: nil, description: "2-finger scroll"),

        // Three-finger swipes (Mission Control / App Exposé — if enabled)
        SystemGesture(type: .swipeUp,   fingerCount: 3, zoneID: nil, description: "Mission Control"),
        SystemGesture(type: .swipeDown, fingerCount: 3, zoneID: nil, description: "App Exposé"),

        // Four-finger swipes — Switch Spaces
        SystemGesture(type: .swipeLeft,  fingerCount: 4, zoneID: nil, description: "Switch Space Left"),
        SystemGesture(type: .swipeRight, fingerCount: 4, zoneID: nil, description: "Switch Space Right"),
    ]

    // MARK: – Conflict detection

    /// Returns true if this gesture exactly matches a macOS system gesture and
    /// should be suppressed (i.e., we don't have zone refinement to differentiate it).
    public func isSystemGesture(_ fired: FiredGesture) -> Bool {
        // If the rule targets a specific zone (not "full"), it's likely safe —
        // macOS doesn't discriminate by trackpad zone.
        if fired.zone.id != GestureZone.full.id { return false }

        return systemGestures.contains { sys in
            sys.type == fired.type &&
            (sys.fingerCount == nil || sys.fingerCount == fired.fingerCount)
        }
    }

    /// Returns a conflict description string if the given rule conflicts with a system gesture,
    /// or nil if there is no conflict.
    public func conflictDescription(for rule: GestureRule) -> String? {
        let desc = rule.gesture

        // Zone-specific rules don't conflict with system gestures.
        if desc.zoneID != GestureZone.full.id { return nil }

        for sys in systemGestures {
            let typeMatch = sys.type == desc.type
            let fingerMatch = sys.fingerCount == nil || sys.fingerCount == desc.fingerCount
            if typeMatch && fingerMatch {
                return "Conflicts with macOS system gesture: \(sys.description)"
            }
        }
        return nil
    }

    /// Returns all rules in the given list that have conflicts.
    public func conflicts(in rules: [GestureRule]) -> [UUID: String] {
        var result: [UUID: String] = [:]
        for rule in rules {
            if let msg = conflictDescription(for: rule) {
                result[rule.id] = msg
            }
        }
        return result
    }
}
