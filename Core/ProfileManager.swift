// ProfileManager.swift — GestureKit/Core
// Manages per-application gesture profiles.
// Stores profiles in ~/Library/Application Support/GestureKit/profiles.json.
// When an app becomes frontmost, activates its profile so RuleEngine uses
// its specific rule set instead of the global one.

import Foundation
import Combine

@MainActor
public final class ProfileManager: ObservableObject {

    // nonisolated init() allows the static singleton to be created from any context.
    // All @Published properties and methods remain @MainActor-protected.
    nonisolated public static let shared = ProfileManager()
    nonisolated private init() {}

    // MARK: – Published state

    @Published public var profiles: [AppProfile] = []
    @Published public private(set) var activeProfile: AppProfile?

    /// The rules to use for the current frontmost app.
    /// If nil, RuleEngine falls back to the global rule list.
    public var activeRules: [GestureRule]? {
        activeProfile?.isEnabled == true ? activeProfile?.rules : nil
    }

    // MARK: – Persistence

    private var storageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("GestureKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("profiles.json")
    }

    public func loadProfiles() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            profiles = try JSONDecoder().decode([AppProfile].self, from: data)
            print("[ProfileManager] Loaded \(profiles.count) profiles.")
        } catch {
            print("[ProfileManager] Failed to load profiles: \(error)")
        }
    }

    public func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("[ProfileManager] Failed to save profiles: \(error)")
        }
    }

    // MARK: – Profile management

    public func addProfile(_ profile: AppProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    public func updateProfile(_ profile: AppProfile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[idx] = profile
        saveProfiles()
    }

    public func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        saveProfiles()
    }

    // MARK: – Activation

    /// Called by AppDelegate when the frontmost application changes.
    public nonisolated func activateProfile(for bundleID: String) {
        Task { @MainActor in
            if let match = profiles.first(where: { $0.appBundleID == bundleID }) {
                activeProfile = match
                print("[ProfileManager] Activated profile '\(match.appName)'")
            } else {
                activeProfile = nil
            }
        }
    }
}
