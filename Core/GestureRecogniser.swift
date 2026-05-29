// GestureRecogniser.swift — GestureKit/Core
// Accumulates raw trackpad event data, applies debounce / threshold logic,
// and emits a FiredGesture when a user gesture is definitively recognised.

import Foundation

// MARK: – FiredGesture

/// A gesture that has been definitively recognised and is ready to be matched
/// against the rule engine.
public struct FiredGesture {
    public let type: GestureType
    public let zone: GestureZone
    public let fingerCount: Int
    public let magnitude: Double
    public let location: NormalizedPoint
}

// MARK: – GestureRecogniser

/// Stateful recogniser that accumulates scroll/swipe deltas and emits
/// `FiredGesture` values once thresholds are met.
public final class GestureRecogniser {

    public static let shared = GestureRecogniser()
    private init() {}

    // MARK: – Configuration

    /// Minimum accumulated scroll delta before firing a scroll gesture action.
    /// Prevents accidental triggers from tiny nudges.
    public var scrollFireThreshold: Double = {
        let val = UserDefaults.standard.double(forKey: "gesturekit_scroll_threshold")
        return val == 0 ? 20.0 : val
    }()

    /// Number of seconds after firing during which the same gesture is suppressed.
    /// Prevents repeated rapid-fire triggers.
    public var cooldownSeconds: Double = 0.08

    // MARK: – Scroll accumulation state

    private var accumulatedDX: Double = 0
    private var accumulatedDY: Double = 0
    private var lastEventTime: Date = .distantPast
    private var lastFireTime: Date = .distantPast

    // MARK: – Public API

    /// Process raw scroll deltas (dx, dy). Returns a FiredGesture if the threshold is met
    /// and the cooldown has expired, otherwise returns nil.
    public func processScroll(
        dx: Double,
        dy: Double,
        location: NormalizedPoint
    ) -> FiredGesture? {
        let now = Date()
        
        // Reset accumulator if there's a long pause between scroll events
        if now.timeIntervalSince(lastEventTime) > 0.3 {
            accumulatedDX = 0
            accumulatedDY = 0
        }
        lastEventTime = now

        accumulatedDX += dx
        accumulatedDY += dy

        // Check cooldown.
        let elapsed = now.timeIntervalSince(lastFireTime)
        guard elapsed >= cooldownSeconds else { return nil }

        // Determine if any axis crossed the threshold.
        var firedType: GestureType?
        var firedMagnitude: Double = 0

        // Favour the vertical axis to prevent diagonal slop from triggering horizontal rules,
        // especially on the edges where human hands naturally arc inwards.
        if abs(accumulatedDY) >= scrollFireThreshold && abs(accumulatedDY) >= abs(accumulatedDX) * 0.5 {
            // Respect the user's Natural Scrolling setting. 
            // We use UserDefaults so they can toggle it in the Settings window.
            let isNatural = UserDefaults.standard.bool(forKey: "gesturekit_natural_scrolling")
            
            if isNatural {
                firedType = accumulatedDY < 0 ? .scrollUp : .scrollDown
            } else {
                firedType = accumulatedDY > 0 ? .scrollUp : .scrollDown
            }
            firedMagnitude = abs(accumulatedDY)
        } else if abs(accumulatedDX) >= scrollFireThreshold {
            firedType = accumulatedDX < 0 ? .scrollLeft : .scrollRight
            firedMagnitude = abs(accumulatedDX)
        }

        guard let type = firedType else { return nil }

        // Reset accumulators after firing
        accumulatedDX = 0
        accumulatedDY = 0
        lastFireTime = now

        let zone = ZoneDetector.shared.zone(at: location)

        return FiredGesture(
            type: type,
            zone: zone,
            fingerCount: 2,   // Scroll always 2-finger on MacBook trackpad
            magnitude: firedMagnitude,
            location: location
        )
    }

    /// Process a tap event. Returns a FiredGesture immediately (taps don't accumulate).
    public func processTap(location: NormalizedPoint, fingerCount: Int) -> FiredGesture? {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFireTime)
        guard elapsed >= cooldownSeconds else { return nil }

        lastFireTime = now
        let zone = ZoneDetector.shared.zone(at: location)

        return FiredGesture(
            type: fingerCount >= 2 ? .doubleTap : .tap,
            zone: zone,
            fingerCount: fingerCount,
            magnitude: 1,
            location: location
        )
    }

    /// Process a multi-finger swipe (called by IOHIDManager when 3/4-finger swipes
    /// are detected). Returns a FiredGesture if cooldown allows.
    public func processSwipe(
        type: GestureType,
        fingerCount: Int,
        location: NormalizedPoint,
        magnitude: Double
    ) -> FiredGesture? {
        let now = Date()
        guard now.timeIntervalSince(lastFireTime) >= cooldownSeconds else { return nil }
        lastFireTime = now

        let zone = ZoneDetector.shared.zone(at: location)
        return FiredGesture(
            type: type,
            zone: zone,
            fingerCount: fingerCount,
            magnitude: magnitude,
            location: location
        )
    }

    /// Reset all accumulated state (e.g., when the monitor is paused).
    public func reset() {
        accumulatedDX = 0
        accumulatedDY = 0
        lastEventTime = .distantPast
        lastFireTime = .distantPast
    }
}
