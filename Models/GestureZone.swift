// GestureZone.swift — GestureKit/Models
// Defines the regions of the trackpad that GestureKit can monitor.
// Zones are normalised to the [0,1] coordinate space of the trackpad surface.

import Foundation
import CoreGraphics

/// A named region on the trackpad surface.
/// The trackpad coordinate space is:
///   - X: 0.0 (left edge) → 1.0 (right edge)
///   - Y: 0.0 (bottom / wrist edge) → 1.0 (top / screen edge)
public struct GestureZone: Codable, Identifiable, Hashable {

    public let id: String           // Stable identifier used in rule JSON
    public var name: String         // Human-readable label shown in UI
    public var rect: NormalizedRect // The region, in normalised trackpad coordinates

    // MARK: – Predefined zones

    /// The full trackpad surface (fallback catch-all zone).
    public static let full = GestureZone(
        id: "full",
        name: "Anywhere",
        rect: NormalizedRect(x: 0, y: 0, width: 1, height: 1)
    )

    public static var leftThirdWidth: Double {
        let val = UserDefaults.standard.double(forKey: "gesturekit_left_width")
        return val == 0 ? 0.40 : val
    }

    public static var rightThirdWidth: Double {
        let val = UserDefaults.standard.double(forKey: "gesturekit_right_width")
        return val == 0 ? 0.40 : val
    }

    /// Left edge of the trackpad.
    public static var leftThird: GestureZone {
        GestureZone(
            id: "left_third",
            name: "Left Side",
            rect: NormalizedRect(x: 0, y: 0, width: leftThirdWidth, height: 1)
        )
    }

    /// Right edge of the trackpad.
    public static var rightThird: GestureZone {
        GestureZone(
            id: "right_third",
            name: "Right Side",
            rect: NormalizedRect(x: 1.0 - rightThirdWidth, y: 0, width: rightThirdWidth, height: 1)
        )
    }

    /// Centre of the trackpad.
    public static var centre: GestureZone {
        GestureZone(
            id: "centre",
            name: "Centre",
            rect: NormalizedRect(x: leftThirdWidth, y: 0.20, width: 1.0 - leftThirdWidth - rightThirdWidth, height: 0.60)
        )
    }

    /// Top edge of the trackpad.
    public static let topEdge = GestureZone(
        id: "top_edge",
        name: "Top Edge",
        rect: NormalizedRect(x: 0.15, y: 0.85, width: 0.70, height: 0.15)
    )

    /// Bottom edge of the trackpad.
    public static let bottomEdge = GestureZone(
        id: "bottom_edge",
        name: "Bottom Edge",
        rect: NormalizedRect(x: 0.15, y: 0.0, width: 0.70, height: 0.15)
    )

    // MARK: – Corners

    public static let topLeft = GestureZone(
        id: "corner_top_left",
        name: "Top Left",
        rect: NormalizedRect(x: 0, y: 0.75, width: 0.25, height: 0.25)
    )

    public static let topRight = GestureZone(
        id: "corner_top_right",
        name: "Top Right",
        rect: NormalizedRect(x: 0.75, y: 0.75, width: 0.25, height: 0.25)
    )

    public static let bottomLeft = GestureZone(
        id: "corner_bottom_left",
        name: "Bottom Left",
        rect: NormalizedRect(x: 0, y: 0, width: 0.25, height: 0.25)
    )

    public static let bottomRight = GestureZone(
        id: "corner_bottom_right",
        name: "Bottom Right",
        rect: NormalizedRect(x: 0.75, y: 0, width: 0.25, height: 0.25)
    )

    /// All built-in zones ordered for display in the UI.
    public static var allBuiltIn: [GestureZone] {
        [
            .full, .leftThird, .centre, .rightThird,
            .topEdge, .bottomEdge,
            .topLeft, .topRight, .bottomLeft, .bottomRight
        ]
    }

    // MARK: – Helpers

    /// Returns true if the normalised point falls inside this zone's rect.
    public func contains(x: Double, y: Double) -> Bool {
        rect.contains(x: x, y: y)
    }
}

// MARK: – NormalizedRect

/// A rectangle whose coordinates are all in [0, 1] normalised space.
public struct NormalizedRect: Codable, Hashable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public func contains(x px: Double, y py: Double) -> Bool {
        px >= x && px <= (x + width) &&
        py >= y && py <= (y + height)
    }

    /// Convert to a CGRect scaled to an actual pixel size (e.g., for drawing in SwiftUI).
    public func toCGRect(in size: CGSize) -> CGRect {
        CGRect(
            x: x * size.width,
            y: (1 - y - height) * size.height,  // Flip Y for screen coordinates
            width: width * size.width,
            height: height * size.height
        )
    }
}
