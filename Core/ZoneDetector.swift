// ZoneDetector.swift — GestureKit/Core
// Maps a normalised trackpad point to a GestureZone.
// Also wraps the MultitouchSupport private framework for higher-fidelity
// finger position data when available.

import Foundation

// MARK: – ZoneDetector

/// Maps touch locations (in normalised [0,1] space) to GestureZone identifiers.
public final class ZoneDetector {

    public static let shared = ZoneDetector()
    private init() {
        setupMultitouchIfAvailable()
    }

    // Custom zones if loaded from disk; otherwise fall back to built-ins.
    private var customZones: [GestureZone]? = nil

    private var activeZones: [GestureZone] {
        customZones ?? GestureZone.allBuiltIn
    }

    // MARK: – Public API

    /// Returns the first zone whose rect contains the given normalised point.
    /// Falls back to `.full` if no specific zone matches.
    public func zone(at point: NormalizedPoint) -> GestureZone {
        // Search smaller (more specific) zones first.
        let sorted = activeZones.filter { $0.id != GestureZone.full.id }
            .sorted { a, b in
                (a.rect.width * a.rect.height) < (b.rect.width * b.rect.height)
            }

        return sorted.first { $0.contains(x: point.x, y: point.y) }
            ?? GestureZone.full
    }

    /// Update the list of zones (called when the user edits zones in settings).
    public func setZones(_ zones: [GestureZone]) {
        self.customZones = zones
    }

    // MARK: – MultitouchSupport Integration

    // MultitouchSupport.framework is a private Apple framework located at:
    //   /System/Library/PrivateFrameworks/MultitouchSupport.framework
    //
    // We load it dynamically so the app still runs on machines where it's unavailable.
    // When available, it gives us raw finger positions on the trackpad surface
    // (more accurate than deriving them from screen cursor coordinates).

    private var mtDeviceRef: UnsafeMutableRawPointer?
    public private(set) var multitouchAvailable = false

    // Thread-safe active touches state
    private let touchesLock = NSLock()
    private var activeTouches: [Int32: NormalizedPoint] = [:]
    
    // Remember the last position to handle inertial scrolling (events that arrive right after fingers lift)
    private var lastKnownCentroid: NormalizedPoint?
    private var lastKnownCentroidTime: Date = .distantPast

    /// Returns the average [0,1] position of all currently touching fingers.
    /// If no fingers are touching, returns the last known position (if within the last 1.0 seconds) to handle inertial scrolling momentum.
    public var currentCentroid: NormalizedPoint? {
        touchesLock.lock()
        defer { touchesLock.unlock() }

        if !activeTouches.isEmpty {
            let sumX = activeTouches.values.reduce(0.0) { $0 + $1.x }
            let sumY = activeTouches.values.reduce(0.0) { $0 + $1.y }
            let count = Double(activeTouches.count)
            let centroid = NormalizedPoint(x: sumX / count, y: sumY / count)
            
            lastKnownCentroid = centroid
            lastKnownCentroidTime = Date()
            return centroid
        }
        
        // Fallback to last known position for inertial scrolling
        if Date().timeIntervalSince(lastKnownCentroidTime) < 1.0 {
            return lastKnownCentroid
        }
        
        return nil
    }

    private func setupMultitouchIfAvailable() {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
            RTLD_LAZY
        ) else {
            print("[ZoneDetector] MultitouchSupport not available — using cursor coordinates.")
            return
        }

        let createSym = dlsym(handle, "MTDeviceCreateDefault")
        let regSym = dlsym(handle, "MTRegisterContactFrameCallback")
        let startSym = dlsym(handle, "MTDeviceStart")
        let scheduleSym = dlsym(handle, "MTDeviceScheduleOnRunLoop")

        guard let createSym, let regSym, let startSym, let scheduleSym else {
            dlclose(handle)
            return
        }

        let createDefault = unsafeBitCast(createSym, to: MTDeviceCreateDefaultFn.self)
        let registerCallback = unsafeBitCast(regSym, to: MTRegisterContactFrameCallbackFn.self)
        let startDevice = unsafeBitCast(startSym, to: MTDeviceStartFn.self)
        let scheduleOnRunLoop = unsafeBitCast(scheduleSym, to: MTDeviceScheduleOnRunLoopFn.self)

        guard let device = createDefault() else { return }
        
        self.mtDeviceRef = device
        self.multitouchAvailable = true

        registerCallback(device, mtEventCallback)
        _ = scheduleOnRunLoop(device, CFRunLoopGetMain(), RunLoop.Mode.common.rawValue as CFString)
        startDevice(device, 0)
        
        print("[ZoneDetector] MultitouchSupport loaded successfully. True trackpad zones enabled!")
    }

    /// Internal function called by the C callback to process a raw frame of contacts
    fileprivate func processContactFrame(contacts: UnsafeMutablePointer<MTContact>, numContacts: Int) {
        touchesLock.lock()
        defer { touchesLock.unlock() }

        // We receive the full state of all fingers in every frame.
        // Rebuild the active touches dictionary.
        activeTouches.removeAll(keepingCapacity: true)

        let buffer = UnsafeBufferPointer(start: contacts, count: numContacts)
        for contact in buffer {
            // state: 1 = touch down, 4 = moving, 5 = stationary, 3 = touch up (removed)
            // We only care about fingers currently on the glass (not lifted).
            if contact.state == 1 || contact.state == 4 || contact.state == 5 {
                activeTouches[contact.identifier] = NormalizedPoint(
                    x: Double(contact.x),
                    y: Double(contact.y)
                )
            }
        }
    }
}

// MARK: – MultitouchSupport C-Bridging

private struct MTContact {
    let frame: Int32
    // Swift inserts 4 bytes of padding here for 8-byte alignment of the following Double
    let timestamp: Double
    let identifier: Int32
    let state: Int32
    let unknown1: Int32
    let unknown2: Int32
    let x: Float
    let y: Float
    // We don't need the remaining fields for zone detection
}

private typealias MTDeviceCreateDefaultFn = @convention(c) () -> UnsafeMutableRawPointer?
private typealias MTContactCallbackFunction = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32, Double, Int32) -> Void
private typealias MTRegisterContactFrameCallbackFn = @convention(c) (UnsafeMutableRawPointer, MTContactCallbackFunction) -> Void
private typealias MTDeviceStartFn = @convention(c) (UnsafeMutableRawPointer, Int32) -> Void
private typealias MTDeviceScheduleOnRunLoopFn = @convention(c) (UnsafeMutableRawPointer, CFRunLoop, CFString) -> Int32

private let mtEventCallback: MTContactCallbackFunction = { device, rawContacts, numContacts, timestamp, frame in
    guard numContacts > 0 else {
        ZoneDetector.shared.processContactFrame(contacts: rawContacts.assumingMemoryBound(to: MTContact.self), numContacts: 0)
        return
    }
    
    let contactsPtr = rawContacts.assumingMemoryBound(to: MTContact.self)
    ZoneDetector.shared.processContactFrame(contacts: contactsPtr, numContacts: Int(numContacts))
}
