// TrackpadDiagramView.swift — GestureKit/UI
// An interactive, animated trackpad diagram that shows all configurable zones.
// Tapping a zone calls `onZoneSelected` so the parent can open a rule editor.

import SwiftUI

// MARK: – TrackpadDiagramView

struct TrackpadDiagramView: View {

    /// Called when the user taps a zone in the diagram.
    var onZoneSelected: (GestureZone) -> Void = { _ in }

    // The currently hovered or selected zone for highlight.
    @State private var hoveredZoneID: String?

    // Zones to display
    var zones: [GestureZone] = GestureZone.allBuiltIn.filter { $0.id != "full" }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Trackpad body
                trackpadBody(size: geo.size)

                // Zone overlays
                ForEach(zones, id: \.id) { zone in
                    zoneOverlay(zone: zone, size: geo.size)
                }

                // Corner indicators
                cornerDots(size: geo.size)
            }
        }
        .aspectRatio(1.6, contentMode: .fit)
        .frame(maxWidth: 380)
    }

    // MARK: – Trackpad body

    @ViewBuilder
    private func trackpadBody(size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: size.width * 0.06)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.18),
                        Color(white: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.width * 0.06)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            // Inner shadow for depth
            .overlay(
                RoundedRectangle(cornerRadius: size.width * 0.06)
                    .stroke(Color.black.opacity(0.5), lineWidth: 4)
                    .blur(radius: 4)
                    .offset(y: 2)
                    .mask(RoundedRectangle(cornerRadius: size.width * 0.06).fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
            )
            // Drop shadow
            .shadow(color: .black.opacity(0.8), radius: 25, y: 15)
    }

    // MARK: – Zone overlay

    @ViewBuilder
    private func zoneOverlay(zone: GestureZone, size: CGSize) -> some View {
        let rect = zone.rect.toCGRect(in: size)
        let isHovered = hoveredZoneID == zone.id

        ZStack {
            // Fill
            RoundedRectangle(cornerRadius: 8)
                .fill(zoneColor(zone: zone, isHovered: isHovered))
                .frame(width: rect.width - 8, height: rect.height - 8)

            // Label
            let isWideAndShort = rect.width > rect.height * 2
            
            if isWideAndShort {
                HStack(spacing: 6) {
                    Image(systemName: zoneIcon(zone: zone))
                        .font(.system(size: 14, weight: .semibold))
                    Text(zone.name)
                        .font(.system(size: 11, weight: .medium))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .foregroundColor(isHovered ? .white : .white.opacity(0.7))
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: zoneIcon(zone: zone))
                        .font(.system(size: 16, weight: .semibold))
                    Text(zone.name)
                        .font(.system(size: 11, weight: .medium))
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .foregroundColor(isHovered ? .white : .white.opacity(0.7))
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
        }
        .frame(width: rect.width - 8, height: rect.height - 8)
        .position(x: rect.midX, y: rect.midY)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredZoneID = hovering ? zone.id : nil
            }
        }
        .onTapGesture {
            onZoneSelected(zone)
        }
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.25), value: isHovered)
    }

    // MARK: – Corner dots

    @ViewBuilder
    private func cornerDots(size: CGSize) -> some View {
        let r = size.width * 0.055
        let padding = size.width * 0.04

        ForEach([
            (CGPoint(x: padding + r, y: padding + r), GestureZone.topLeft),
            (CGPoint(x: size.width - padding - r, y: padding + r), GestureZone.topRight),
            (CGPoint(x: padding + r, y: size.height - padding - r), GestureZone.bottomLeft),
            (CGPoint(x: size.width - padding - r, y: size.height - padding - r), GestureZone.bottomRight),
        ], id: \.1.id) { position, zone in
            Circle()
                .fill(hoveredZoneID == zone.id
                      ? Color.accentColor
                      : Color.white.opacity(0.25))
                .frame(width: r * 2, height: r * 2)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )
                .position(position)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        hoveredZoneID = hovering ? zone.id : nil
                    }
                }
                .onTapGesture { onZoneSelected(zone) }
                .scaleEffect(hoveredZoneID == zone.id ? 1.2 : 1.0)
                .animation(.spring(response: 0.2), value: hoveredZoneID)
        }
    }

    // MARK: – Helpers

    private func zoneColor(zone: GestureZone, isHovered: Bool) -> Color {
        if isHovered { return Color.accentColor.opacity(0.45) }
        switch zone.id {
        case GestureZone.leftThird.id:   return Color.blue.opacity(0.18)
        case GestureZone.rightThird.id:  return Color.purple.opacity(0.18)
        case GestureZone.topEdge.id:     return Color.orange.opacity(0.18)
        case GestureZone.bottomEdge.id:  return Color.green.opacity(0.18)
        case GestureZone.centre.id:      return Color.white.opacity(0.06)
        default:                          return Color.white.opacity(0.08)
        }
    }

    private func zoneIcon(zone: GestureZone) -> String {
        switch zone.id {
        case GestureZone.leftThird.id:       return "speaker.wave.2"
        case GestureZone.rightThird.id:      return "sun.max"
        case GestureZone.topEdge.id:         return "keyboard"
        case GestureZone.bottomEdge.id:      return "macwindow.on.rectangle"
        case GestureZone.centre.id:          return "hand.draw"
        case GestureZone.topLeft.id:         return "arrow.up.left"
        case GestureZone.topRight.id:        return "arrow.up.right"
        case GestureZone.bottomLeft.id:      return "arrow.down.left"
        case GestureZone.bottomRight.id:     return "arrow.down.right"
        default:                              return "hand.tap"
        }
    }
}

// #Preview is not supported in Swift Package Manager builds.
// Use the app itself to preview the TrackpadDiagramView in the Gestures tab.
