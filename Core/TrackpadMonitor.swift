// TrackpadMonitor.swift — GestureKit/Core
// Central service that installs a CGEvent tap to intercept trackpad events
// system-wide and routes them to the ZoneDetector and GestureRecogniser.
//
// Architecture:
//   TrackpadMonitor
//     → ZoneDetector   (maps raw coordinates to GestureZone)
//     → GestureRecogniser (identifies gesture type)
//     → RuleEngine     (matches gesture to rule and fires action)
//
// Requires: Accessibility permission (checked before starting).

import Foundation
import CoreGraphics
import AppKit

// MARK: – TrackpadMonitor

/// Singleton that owns the CGEvent tap and dispatches gesture events.
public final class TrackpadMonitor {

    nonisolated public static let shared = TrackpadMonitor()

    // MARK: – State

    /// Whether the event tap is currently running.
    public private(set) var isRunning = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {}

    // MARK: – Public API

    /// Install the CGEvent tap and begin processing trackpad events.
    public func start() {
        guard !isRunning else { return }
        guard AccessibilityHelper.hasPermission else {
            print("[TrackpadMonitor] No accessibility permission — cannot start.")
            return
        }

        // The event mask covers scroll wheel events (which trackpad scroll/swipe generates)
        // and mouse button events (for tap detection).
        // Note: We use .listenOnly here so we don't block the event stream;
        //       we still get full access to coordinates and deltas.
        let mask: CGEventMask =
            (1 << CGEventType.scrollWheel.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue)

        // We need a C-compatible callback; use a static trampoline that forwards
        // to the shared instance.
        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,       // Intercept at the HID level (before system processing)
            place: .headInsertEventTap,
            options: .listenOnly,       // Don't modify/block events
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap else {
            print("[TrackpadMonitor] Failed to create CGEvent tap. Check Accessibility permission.")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isRunning = true
        print("[TrackpadMonitor] Started — listening for trackpad events.")
    }

    /// Remove the event tap and stop processing.
    public func stop() {
        guard isRunning else { return }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        print("[TrackpadMonitor] Stopped.")
    }

    // MARK: – Event processing

    /// Called by the C trampoline for every captured CGEvent.
    fileprivate func handleEvent(_ event: CGEvent, type: CGEventType) {
        // Extract the normalised touch location.
        // CGEvent carries subtype and field data for trackpad events.
        let location = normaliseLocation(event)

        switch type {
        case .scrollWheel:
            handleScroll(event: event, location: location)

        case .leftMouseDown, .leftMouseUp:
            handleClick(event: event, type: type, location: location)

        default:
            break
        }
    }

    // MARK: – Scroll handling

    private func handleScroll(event: CGEvent, location: NormalizedPoint) {
        // CGScrollEvent fields:
        //   Field 88 = scrollWheelEventDeltaAxis1 (vertical delta, in lines)
        //   Field 89 = scrollWheelEventDeltaAxis2 (horizontal delta)
        //   Field 96 = scrollWheelEventIsContinuous (1 = trackpad, 0 = mouse wheel)
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        guard isContinuous == 1 else { return }   // Ignore physical scroll wheels

        let vertDelta  = event.getDoubleValueField(.scrollWheelEventDeltaAxis1)
        let horizDelta = event.getDoubleValueField(.scrollWheelEventDeltaAxis2)

        // Ask the gesture recogniser to accumulate and decide if a gesture has fired.
        if let fired = GestureRecogniser.shared.processScroll(
            dx: horizDelta,
            dy: vertDelta,
            location: location
        ) {
            RuleEngine.shared.handle(gesture: fired)
        }
    }

    // MARK: – Click / tap handling

    private var tapDownLocation: NormalizedPoint?
    private var tapDownTime: Date?

    private func handleClick(event: CGEvent, type: CGEventType, location: NormalizedPoint) {
        if type == .leftMouseDown {
            tapDownLocation = location
            tapDownTime = Date()
        } else if type == .leftMouseUp, let downLoc = tapDownLocation, let downTime = tapDownTime {
            let elapsed = Date().timeIntervalSince(downTime)
            let moved = hypot(location.x - downLoc.x, location.y - downLoc.y)

            // Only classify as a tap if the finger barely moved and the press was short.
            if elapsed < 0.3 && moved < 0.05 {
                let fingerCount = event.getIntegerValueField(.mouseEventClickState)
                if let fired = GestureRecogniser.shared.processTap(
                    location: downLoc,
                    fingerCount: max(1, Int(fingerCount))
                ) {
                    RuleEngine.shared.handle(gesture: fired)
                }
            }
            tapDownLocation = nil
            tapDownTime = nil
        }
    }

    // MARK: – Coordinate normalisation

    /// Convert the raw CGEvent mouse location to a [0,1] normalised trackpad coordinate.
    /// If MultitouchSupport is loaded, we query the exact centroid of active physical touches on the trackpad.
    /// If unavailable, we fall back to screen cursor coordinates as a rough proxy.
    private func normaliseLocation(_ event: CGEvent) -> NormalizedPoint {
        if ZoneDetector.shared.multitouchAvailable, let centroid = ZoneDetector.shared.currentCentroid {
            return centroid
        }

        // Fallback: screen cursor proxy
        let loc = event.location
        let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return NormalizedPoint(
            x: min(max(loc.x / screen.width, 0), 1),
            y: min(max(1.0 - loc.y / screen.height, 0), 1)
        )
    }
}

// MARK: – C Trampoline

/// CGEvent tap callback — must be a C function pointer.
/// Bridges back to the Swift instance stored in `userInfo`.
private let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passRetained(event) }
    let monitor = Unmanaged<TrackpadMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    monitor.handleEvent(event, type: type)
    return Unmanaged.passRetained(event)
}

// MARK: – NormalizedPoint

/// A point in [0,1]×[0,1] trackpad space.
public struct NormalizedPoint {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
