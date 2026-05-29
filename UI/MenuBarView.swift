// MenuBarView.swift — GestureKit/UI
// SwiftUI view rendered inside the NSStatusItem popover (optional popover mode).
// The primary menu is built in AppDelegate using NSMenu for reliability,
// but this view can be used if you prefer a SwiftUI popover instead.

import SwiftUI

struct MenuBarView: View {

    @StateObject private var ruleEngine = RuleEngine.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GestureKit")
                        .font(.headline)
                    Text(TrackpadMonitor.shared.isRunning ? "Active" : "Paused")
                        .font(.caption)
                        .foregroundColor(TrackpadMonitor.shared.isRunning ? .green : .orange)
                }
                Spacer()
            }
            .padding(14)

            Divider()

            // Quick rule toggles
            if !ruleEngine.rules.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Toggles")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                    ForEach(ruleEngine.rules.prefix(5)) { rule in
                        HStack {
                            Image(systemName: rule.action.type.symbolName)
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            Text(rule.name)
                                .font(.callout)
                                .lineLimit(1)
                            Spacer()
                            Circle()
                                .fill(rule.isEnabled ? Color.green : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                    }
                }

                Divider()
                    .padding(.top, 6)
            }

            // Actions
            Button {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Open Settings…")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit GestureKit")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .frame(width: 260)
    }
}
