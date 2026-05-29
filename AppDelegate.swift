// AppDelegate.swift — GestureKit
// Handles application lifecycle events, sets up the menu bar NSStatusItem,
// hides the app from the Dock, and bootstraps core services.
//
// Core services (RuleEngine, ProfileManager, PluginLoader) are @MainActor singletons.
// AppDelegate methods run on the main thread so direct access is safe.

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // The menu bar icon and its menu
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?

    // MARK: – Application lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Hide from Dock — GestureKit is a menu-bar-only app.
        NSApp.setActivationPolicy(.accessory)

        // 2. Load persisted gestures and profiles from disk.
        // These @MainActor singletons are safe to call here because AppDelegate
        // methods run on the main thread.
        Task { @MainActor in
            RuleEngine.shared.loadRules()
            ProfileManager.shared.loadProfiles()
            PluginLoader.shared.loadPlugins()
        }

        // 3. Set up the status bar icon.
        setupStatusItem()

        // 4. Check accessibility permission and start monitoring if granted.
        if AccessibilityHelper.hasPermission {
            TrackpadMonitor.shared.start()
        } else {
            // Show the settings window on the onboarding screen.
            showSettings(tab: "onboarding")
        }

        // 5. Observe app switches so we can activate the correct per-app profile.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeAppDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        TrackpadMonitor.shared.stop()
    }

    // MARK: – Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        // Use the trackpad symbol as the menu bar icon.
        button.image = NSImage(
            systemSymbolName: "hand.point.up.left.fill",
            accessibilityDescription: "GestureKit"
        )
        button.image?.size = NSSize(width: 18, height: 18)
        button.image?.isTemplate = true  // Allows macOS to tint for dark/light mode

        // Build the dropdown menu.
        let menu = NSMenu()
        menu.addItem(withTitle: "GestureKit", action: nil, keyEquivalent: "")
            .isEnabled = false
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Open Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ).target = self
        menu.addItem(.separator())
        let toggleItem = menu.addItem(
            withTitle: "Disable Gestures",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit GestureKit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        statusItem?.menu = menu
        self.statusMenu = menu
    }

    // MARK: – Actions

    @objc private func openSettings() {
        showSettings(tab: "gestures")
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        if TrackpadMonitor.shared.isRunning {
            TrackpadMonitor.shared.stop()
            sender.title = "Enable Gestures"
        } else {
            guard AccessibilityHelper.hasPermission else { return }
            TrackpadMonitor.shared.start()
            sender.title = "Disable Gestures"
        }
    }

    private func showSettings(tab: String) {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
        // Post a notification so SettingsWindow can switch to the right tab.
        NotificationCenter.default.post(
            name: .gestureKitShowTab,
            object: tab
        )
    }

    // MARK: – App switching

    // NSWorkspace.didActivateApplicationNotification is always posted on the main thread.
    @MainActor @objc private func activeAppDidChange(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        ProfileManager.shared.activateProfile(for: bundleID)
    }
}

// MARK: – Notification Names

extension Notification.Name {
    static let gestureKitShowTab = Notification.Name("gestureKitShowTab")
}
