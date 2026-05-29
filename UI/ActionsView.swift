// ActionsView.swift — GestureKit/UI
// Shows all gesture rules in a flat list with drag-to-reorder and add/edit/delete.

import SwiftUI

struct ActionsView: View {

    @StateObject private var ruleEngine = RuleEngine.shared
    @State private var showEditor = false
    @State private var editingRule: GestureRule?
    @State private var searchText = ""

    var filteredRules: [GestureRule] {
        let sorted = ruleEngine.rules.sorted { $0.sortOrder < $1.sortOrder }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.action.type.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search rules…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 240)

                Spacer()

                Button {
                    editingRule = nil
                    showEditor = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            if filteredRules.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text(searchText.isEmpty ? "No gesture rules yet" : "No matching rules")
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Button("Add your first rule") {
                            editingRule = nil
                            showEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                Spacer()
            } else {
                List {
                    ForEach(filteredRules) { rule in
                        ActionRuleRow(rule: rule) {
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
                    .onMove { source, dest in
                        ruleEngine.moveRules(from: source, to: dest)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .sheet(isPresented: $showEditor) {
            RuleEditorSheet(
                existingRule: editingRule,
                defaultZoneID: GestureZone.full.id
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
}

// MARK: – ActionRuleRow

struct ActionRuleRow: View {

    let rule: GestureRule
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    private var conflictWarning: String? {
        ConflictResolver.shared.conflictDescription(for: rule)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary.opacity(0.4))
                .font(.caption)

            // Action icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: rule.action.type.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(rule.name)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(rule.isEnabled ? .primary : .secondary)

                    if let warning = conflictWarning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .help(warning)
                    }
                }

                HStack(spacing: 6) {
                    // Zone badge
                    zoneBadge(zoneID: rule.gesture.zoneID)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(rule.gesture.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("→")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(rule.action.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .transition(.scale.combined(with: .opacity))

                Button(action: onDelete) {
                    Image(systemName: "trash.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .transition(.scale.combined(with: .opacity))
            }

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }

    @ViewBuilder
    private func zoneBadge(zoneID: String) -> some View {
        let zoneName = GestureZone.allBuiltIn.first(where: { $0.id == zoneID })?.name ?? "All"
        Text(zoneName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.12))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
    }
}
