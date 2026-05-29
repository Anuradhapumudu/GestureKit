// RuleEngine.swift — GestureKit/Core
// Matches incoming FiredGesture events against the loaded GestureRule list
// and delegates to ActionExecutor to perform the associated action.
// Persists rules to ~/Library/Application Support/GestureKit/gestures.json.

import Foundation
import Combine

// MARK: – RuleEngine

/// Central matching engine: gesture → rule → action.
/// Marked @MainActor so that @Published properties update the UI safely.
@MainActor
public final class RuleEngine: ObservableObject {

    // The static singleton is initialized lazily on first access. Since @MainActor
    // classes can't be instantiated from nonisolated contexts in strict concurrency,
    // we mark init() nonisolated so the shared instance can be created from anywhere.
    // All mutable state is still @MainActor-protected via the class annotation.
    nonisolated public static let shared = RuleEngine()
    nonisolated private init() {}

    // MARK: – Published state (drives the UI)

    @Published public var rules: [GestureRule] = []

    // MARK: – Persistence path

    private var storageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("GestureKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("gestures.json")
    }

    // MARK: – Load / Save

    public func loadRules() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            rules = defaultRules()
            return
        }
        do {
            let data = try Data(contentsOf: storageURL)
            rules = try JSONDecoder().decode([GestureRule].self, from: data)
            print("[RuleEngine] Loaded \(rules.count) rules from disk.")
        } catch {
            print("[RuleEngine] Failed to load rules: \(error). Using defaults.")
            rules = defaultRules()
        }
    }

    public func saveRules() {
        do {
            let data = try JSONEncoder().encode(rules)
            try data.write(to: storageURL, options: .atomic)
            print("[RuleEngine] Saved \(rules.count) rules.")
        } catch {
            print("[RuleEngine] Failed to save rules: \(error)")
        }
    }

    // MARK: – Rule management

    public func addRule(_ rule: GestureRule) {
        var r = rule
        r.sortOrder = (rules.map(\.sortOrder).max() ?? -1) + 1
        rules.append(r)
        saveRules()
    }

    public func updateRule(_ rule: GestureRule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
        saveRules()
    }

    public func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        saveRules()
    }

    public func moveRules(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        for (i, _) in rules.enumerated() { rules[i].sortOrder = i }
        saveRules()
    }

    // MARK: – Gesture matching

    /// Called from TrackpadMonitor (non-isolated thread) — dispatch to main actor.
    public nonisolated func handle(gesture: FiredGesture) {
        Task { @MainActor in
            await _handle(gesture: gesture)
        }
    }

    private func _handle(gesture: FiredGesture) async {
        // Let the conflict resolver check first.
        guard !ConflictResolver.shared.isSystemGesture(gesture) else {
            print("[RuleEngine] Gesture conflicts with system gesture — skipped.")
            return
        }

        // Use the active profile's rules if one is set, else fall back to global rules.
        let activeRules = ProfileManager.shared.activeRules ?? rules

        // Rules are matched in sortOrder; first match wins.
        let sorted = activeRules
            .filter(\.isEnabled)
            .sorted { $0.sortOrder < $1.sortOrder }

        for rule in sorted {
            if matches(rule: rule, gesture: gesture) {
                print("[RuleEngine] Matched rule '\(rule.name)' → \(rule.action.type.rawValue)")
                await ActionExecutor.shared.execute(action: rule.action)
                return
            }
        }
        
        print("[RuleEngine] Unmatched gesture: \(gesture.type.rawValue) in zone: \(gesture.zone.name) (Centroid: \(String(format: "%.2f, %.2f", gesture.location.x, gesture.location.y)))")
    }

    // MARK: – Matching logic

    private func matches(rule: GestureRule, gesture: FiredGesture) -> Bool {
        let desc = rule.gesture

        // 1. Gesture type must match exactly.
        guard desc.type == gesture.type else { return false }

        // 2. Zone must match (or the rule's zone is "full" which catches everything).
        if desc.zoneID != GestureZone.full.id {
            guard gesture.zone.id == desc.zoneID else { return false }
        }

        // 3. Finger count must match if specified.
        if let requiredFingers = desc.fingerCount {
            guard gesture.fingerCount == requiredFingers else { return false }
        }

        // 4. Magnitude threshold (for scroll gestures).
        if gesture.type == .scrollUp || gesture.type == .scrollDown ||
           gesture.type == .scrollLeft || gesture.type == .scrollRight {
            guard gesture.magnitude >= desc.scrollThreshold else { return false }
        }

        return true
    }

    // MARK: – Default rules

    private func defaultRules() -> [GestureRule] {
        [
            GestureRule(
                name: "Left Scroll Up → Brightness Up",
                gesture: GestureDescriptor(type: .scrollUp, zoneID: GestureZone.leftThird.id),
                action: ActionDescriptor(type: .brightnessUp),
                sortOrder: 0
            ),
            GestureRule(
                name: "Left Scroll Down → Brightness Down",
                gesture: GestureDescriptor(type: .scrollDown, zoneID: GestureZone.leftThird.id),
                action: ActionDescriptor(type: .brightnessDown),
                sortOrder: 1
            ),
            GestureRule(
                name: "Right Scroll Up → Volume Up",
                gesture: GestureDescriptor(type: .scrollUp, zoneID: GestureZone.rightThird.id),
                action: ActionDescriptor(type: .volumeUp),
                sortOrder: 2
            ),
            GestureRule(
                name: "Right Scroll Down → Volume Down",
                gesture: GestureDescriptor(type: .scrollDown, zoneID: GestureZone.rightThird.id),
                action: ActionDescriptor(type: .volumeDown),
                sortOrder: 3
            ),
            GestureRule(
                name: "4-Finger Swipe Left → Mission Control",
                gesture: GestureDescriptor(type: .swipeLeft, zoneID: GestureZone.full.id, fingerCount: 4),
                action: ActionDescriptor(type: .missionControl),
                sortOrder: 4
            ),
            GestureRule(
                name: "4-Finger Swipe Right → Launchpad",
                gesture: GestureDescriptor(type: .swipeRight, zoneID: GestureZone.full.id, fingerCount: 4),
                action: ActionDescriptor(type: .launchpad),
                sortOrder: 5
            ),
            GestureRule(
                name: "Top Scroll Right → KB Brightness Up",
                gesture: GestureDescriptor(type: .scrollRight, zoneID: GestureZone.topEdge.id),
                action: ActionDescriptor(type: .keyboardBacklightUp),
                sortOrder: 6
            ),
            GestureRule(
                name: "Top Scroll Left → KB Brightness Down",
                gesture: GestureDescriptor(type: .scrollLeft, zoneID: GestureZone.topEdge.id),
                action: ActionDescriptor(type: .keyboardBacklightDown),
                sortOrder: 7
            ),
            GestureRule(
                name: "Bottom Scroll Up → Mission Control",
                gesture: GestureDescriptor(type: .scrollUp, zoneID: GestureZone.bottomEdge.id),
                action: ActionDescriptor(type: .missionControl),
                sortOrder: 8
            ),
            GestureRule(
                name: "Bottom Scroll Down → App Exposé",
                gesture: GestureDescriptor(type: .scrollDown, zoneID: GestureZone.bottomEdge.id),
                action: ActionDescriptor(type: .expose),
                sortOrder: 9
            )
        ]
    }
}
