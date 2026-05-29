// GesturesView.swift — GestureKit/UI
// Shows the interactive trackpad diagram and a summary of rules per zone.
// Tapping a zone opens an inline rule editor for that zone.

import SwiftUI

struct GesturesView: View {

    @StateObject private var ruleEngine = RuleEngine.shared

    @State private var selectedZone: GestureZone?
    @State private var showRuleEditor = false
    @State private var editingRule: GestureRule?
    
    @AppStorage("gesturekit_natural_scrolling") private var isNaturalScrolling: Bool = false
    @AppStorage("gesturekit_scroll_threshold") private var scrollSensitivity: Double = 20.0
    @AppStorage("gesturekit_left_width") private var leftWidth: Double = 0.40
    @AppStorage("gesturekit_right_width") private var rightWidth: Double = 0.40

    var body: some View {
        HStack(spacing: 0) {
            // Left: Trackpad diagram
            VStack(spacing: 20) {
                Text("Tap a zone to configure gestures")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TrackpadDiagramView(onZoneSelected: { zone in
                    withAnimation(.spring(response: 0.3)) {
                        selectedZone = zone
                    }
                })
                .padding(.horizontal, 24)

                if let zone = selectedZone {
                    zoneRulesSummary(zone: zone)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $isNaturalScrolling) {
                            Text("Natural Scrolling")
                                .font(.headline)
                        }
                        .toggleStyle(.switch)
                        
                        Text("Pushing your fingers upwards triggers Scroll Up.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Scroll Sensitivity")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(scrollSensitivity))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $scrollSensitivity, in: 1.0...50.0, step: 1.0)
                            .onChange(of: scrollSensitivity) { newValue in
                                GestureRecogniser.shared.scrollFireThreshold = newValue
                            }
                        
                        Text("Lower values trigger scrolls faster.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Zone Dimensions")
                            .font(.headline)
                        
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Left: \(Int(leftWidth * 100))%")
                                    .font(.subheadline)
                                Slider(value: $leftWidth, in: 0.10...0.45, step: 0.05)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Right: \(Int(rightWidth * 100))%")
                                    .font(.subheadline)
                                Slider(value: $rightWidth, in: 0.10...0.45, step: 0.05)
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)

            Divider()

            // Right: Rule list for selected zone
            if let zone = selectedZone {
                ZoneRuleListView(zone: zone, editingRule: $editingRule, showEditor: $showRuleEditor)
                    .frame(width: 320)
            } else {
                emptyDetail
                    .frame(width: 320)
            }
        }
        .sheet(isPresented: $showRuleEditor) {
            RuleEditorSheet(
                existingRule: editingRule,
                defaultZoneID: selectedZone?.id ?? GestureZone.full.id
            ) { rule in
                if let existing = editingRule {
                    var r = rule; r.id = existing.id
                    ruleEngine.updateRule(r)
                } else {
                    ruleEngine.addRule(rule)
                }
            }
        }
    }

    // MARK: – Zone rules summary (under diagram)

    @ViewBuilder
    private func zoneRulesSummary(zone: GestureZone) -> some View {
        let count = rulesForZone(zone).count

        HStack {
            Image(systemName: "bolt.fill")
                .foregroundColor(.accentColor)
            Text(count == 0
                 ? "No rules for \(zone.name)"
                 : "\(count) rule\(count == 1 ? "" : "s") in \(zone.name)")
                .font(.callout.weight(.medium))
            Spacer()
            Button("Add Rule") {
                editingRule = nil
                showRuleEditor = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
    }

    // MARK: – Empty state

    private var emptyDetail: some View {
        VStack(spacing: 20) {
            let base = Image(systemName: "hand.tap.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            if #available(macOS 15, *) {
                base.symbolEffect(.bounce, options: .repeating)
            } else {
                base
            }
            
            VStack(spacing: 6) {
                Text("Select a Zone")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Tap a zone in the diagram on the left\nto configure its gesture rules.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: – Helpers

    private func rulesForZone(_ zone: GestureZone) -> [GestureRule] {
        ruleEngine.rules.filter {
            $0.gesture.zoneID == zone.id || zone.id == GestureZone.full.id
        }
    }
}

// MARK: – ZoneRuleListView

struct ZoneRuleListView: View {

    let zone: GestureZone
    @Binding var editingRule: GestureRule?
    @Binding var showEditor: Bool
    @StateObject private var ruleEngine = RuleEngine.shared

    var rulesInZone: [GestureRule] {
        ruleEngine.rules
            .filter { $0.gesture.zoneID == zone.id }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(zone.name)
                    .font(.headline)
                Spacer()
                Button {
                    editingRule = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding()

            Divider()

            if rulesInZone.isEmpty {
                Spacer()
                Text("No rules for this zone")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(rulesInZone) { rule in
                        RuleRowView(rule: rule) {
                            editingRule = rule
                            showEditor = true
                        } onToggle: {
                            var updated = rule
                            updated.isEnabled.toggle()
                            ruleEngine.updateRule(updated)
                        } onDelete: {
                            ruleEngine.deleteRule(id: rule.id)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

// MARK: – RuleRowView

struct RuleRowView: View {
    let rule: GestureRule
    let onEdit: () -> Void
    let onToggle: () -> Void        // Called when the toggle switch changes
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Action icon
            Image(systemName: rule.action.type.symbolName)
                .font(.body.weight(.semibold))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .foregroundColor(rule.isEnabled ? .primary : .secondary)
                Text("\(rule.gesture.type.displayName) → \(rule.action.type.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Conflict warning
            if let conflict = ConflictResolver.shared.conflictDescription(for: rule) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .help(conflict)
            }

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .scaleEffect(0.75)

            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .transition(.opacity)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red.opacity(0.8))
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: – RuleEditorSheet

struct RuleEditorSheet: View {

    let existingRule: GestureRule?
    let defaultZoneID: String
    let onSave: (GestureRule) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var gestureType: GestureType = .scrollUp
    @State private var zoneID: String = GestureZone.full.id
    @State private var fingerCount: Int = 2
    @State private var actionType: ActionType = .volumeUp
    @State private var actionParam: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Name") {
                    TextField("e.g. Left Scroll Up → Volume", text: $name)
                }

                Section("Gesture") {
                    Picker("Type", selection: $gestureType) {
                        ForEach(GestureType.allCases, id: \.self) { t in
                            Label(t.displayName, systemImage: t.symbolName).tag(t)
                        }
                    }

                    Picker("Zone", selection: $zoneID) {
                        ForEach(GestureZone.allBuiltIn, id: \.id) { z in
                            Text(z.name).tag(z.id)
                        }
                    }

                    Stepper("Fingers: \(fingerCount)", value: $fingerCount, in: 1...5)
                }

                Section("Action") {
                    Picker("Action", selection: $actionType) {
                        ForEach(ActionType.allCases, id: \.self) { a in
                            Label(a.displayName, systemImage: a.symbolName).tag(a)
                        }
                    }

                    if actionType.requiresParameter {
                        TextField(parameterLabel, text: $actionParam)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(existingRule == nil ? "Add Rule" : "Edit Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 440, height: 480)
        .onAppear { populateFromExisting() }
    }

    private var parameterLabel: String {
        switch actionType {
        case .launchApp:       return "Bundle ID (e.g. com.apple.Safari)"
        case .runShortcut:     return "Shortcut Name"
        case .runAppleScript:  return "AppleScript source"
        case .sendKeyShortcut: return "Key code (integer)"
        default:               return "Parameter"
        }
    }

    private func saveAndDismiss() {
        let gesture = GestureDescriptor(
            type: gestureType,
            zoneID: zoneID,
            fingerCount: fingerCount
        )
        let action = ActionDescriptor(
            type: actionType,
            appBundleID: actionType == .launchApp ? actionParam : nil,
            shortcutName: actionType == .runShortcut ? actionParam : nil,
            appleScript: actionType == .runAppleScript ? actionParam : nil,
            keyCode: actionType == .sendKeyShortcut ? Int(actionParam) : nil
        )
        let rule = GestureRule(name: name, gesture: gesture, action: action)
        onSave(rule)
        dismiss()
    }

    private func populateFromExisting() {
        guard let r = existingRule else {
            zoneID = defaultZoneID
            return
        }
        name = r.name
        gestureType = r.gesture.type
        zoneID = r.gesture.zoneID
        fingerCount = r.gesture.fingerCount ?? 2
        actionType = r.action.type
        actionParam = r.action.appBundleID
            ?? r.action.shortcutName
            ?? r.action.appleScript
            ?? (r.action.keyCode.map { "\($0)" })
            ?? ""
    }
}
