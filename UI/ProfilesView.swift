// ProfilesView.swift — GestureKit/UI
// Shows per-app gesture profiles. Users can add a profile by picking an installed app,
// then configure its rules independently of the global rule set.

import SwiftUI
import AppKit

struct ProfilesView: View {

    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedProfile: AppProfile?
    @State private var showAppPicker = false
    @State private var showRuleEditor = false
    @State private var editingRule: GestureRule?

    var body: some View {
        HSplitView {
            // Left: profile list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("App Profiles")
                        .font(.headline)
                    Spacer()
                    Button {
                        showAppPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding()

                Divider()

                if profileManager.profiles.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "app.badge.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("No app profiles yet")
                            .foregroundColor(.secondary)
                        Button("Add Profile") { showAppPicker = true }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List(profileManager.profiles, id: \.id, selection: $selectedProfile) { profile in
                        ProfileRowView(
                            profile: profile,
                            isActive: profileManager.activeProfile?.id == profile.id
                        )
                        .tag(profile)
                        .contextMenu {
                            Button("Delete Profile", role: .destructive) {
                                if selectedProfile?.id == profile.id { selectedProfile = nil }
                                profileManager.deleteProfile(id: profile.id)
                            }
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
            .frame(minWidth: 220, maxWidth: 280)

            // Right: selected profile rules
            if let profile = selectedProfile {
                ProfileRulesView(
                    profile: profile,
                    editingRule: $editingRule,
                    showEditor: $showRuleEditor
                )
            } else {
                Text("Select an app profile to edit its rules")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(onProfileAdded: { profile in
                selectedProfile = profile
            })
        }
        .sheet(isPresented: $showRuleEditor) {
            if let profile = selectedProfile {
                RuleEditorSheet(
                    existingRule: editingRule,
                    defaultZoneID: GestureZone.full.id
                ) { rule in
                    var updated = profile
                    if let existing = editingRule,
                       let idx = updated.rules.firstIndex(where: { $0.id == existing.id }) {
                        var r = rule; r.id = existing.id
                        updated.rules[idx] = r
                    } else {
                        updated.rules.append(rule)
                    }
                    profileManager.updateProfile(updated)
                    selectedProfile = updated
                }
            }
        }
    }
}

// MARK: – ProfileRowView

struct ProfileRowView: View {
    let profile: AppProfile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let icon = profile.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.appName)
                    .font(.callout.weight(.medium))
                Text("\(profile.rules.count) rule\(profile.rules.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isActive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .help("Active now")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: – ProfileRulesView

struct ProfileRulesView: View {

    let profile: AppProfile
    @Binding var editingRule: GestureRule?
    @Binding var showEditor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.appName)
                        .font(.title3.bold())
                    Text(profile.appBundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    editingRule = nil
                    showEditor = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            if profile.rules.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("No rules for \(profile.appName) yet")
                        .foregroundColor(.secondary)
                    Button("Add Rule") {
                        editingRule = nil
                        showEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    ForEach(profile.rules) { rule in
                        RuleRowView(rule: rule) {
                            editingRule = rule
                            showEditor = true
                        } onToggle: {
                            var updated = profile
                            if let idx = updated.rules.firstIndex(where: { $0.id == rule.id }) {
                                updated.rules[idx].isEnabled.toggle()
                                ProfileManager.shared.updateProfile(updated)
                            }
                        } onDelete: {
                            var updated = profile
                            updated.rules.removeAll { $0.id == rule.id }
                            ProfileManager.shared.updateProfile(updated)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

// MARK: – AppPickerSheet

struct AppPickerSheet: View {

    /// Called on the main thread after a profile is created for the selected app.
    let onProfileAdded: (AppProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var installedApps: [AppInfo] = []

    struct AppInfo: Identifiable {
        let id = UUID()
        let name: String
        let bundleID: String
        let icon: NSImage?
        let url: URL
    }

    var filteredApps: [AppInfo] {
        if searchText.isEmpty { return installedApps }
        return installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search apps…", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(.regularMaterial)
            .padding()

            Divider()

            List(filteredApps) { app in
                HStack(spacing: 10) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name).font(.callout.weight(.medium))
                        Text(app.bundleID).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Create a profile directly from the app metadata we scanned.
                    let profile = AppProfile(
                        appBundleID: app.bundleID,
                        appName: app.name
                    )
                    // Avoid duplicates.
                    if !ProfileManager.shared.profiles.contains(where: { $0.appBundleID == app.bundleID }) {
                        ProfileManager.shared.addProfile(profile)
                    }
                    onProfileAdded(profile)
                    dismiss()
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .navigationTitle("Choose an App")
        .onAppear { loadApps() }
    }

    private func loadApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let appDirs = [
                URL(fileURLWithPath: "/Applications"),
                URL(fileURLWithPath: "/System/Applications"),
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
            ]

            var apps: [AppInfo] = []
            let fm = FileManager.default

            for dir in appDirs {
                guard let contents = try? fm.contentsOfDirectory(
                    at: dir, includingPropertiesForKeys: nil
                ) else { continue }

                for url in contents where url.pathExtension == "app" {
                    let bundle = Bundle(url: url)
                    let bundleID = bundle?.bundleIdentifier ?? ""
                    let name = bundle?.infoDictionary?["CFBundleDisplayName"] as? String
                        ?? bundle?.infoDictionary?["CFBundleName"] as? String
                        ?? url.deletingPathExtension().lastPathComponent
                    let icon = NSWorkspace.shared.icon(forFile: url.path)

                    if !bundleID.isEmpty {
                        apps.append(AppInfo(name: name, bundleID: bundleID, icon: icon, url: url))
                    }
                }
            }

            let sorted = apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
            DispatchQueue.main.async {
                self.installedApps = sorted
            }
        }
    }
}
