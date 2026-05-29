// SettingsWindow.swift — GestureKit/UI
// The main settings window with a sidebar + detail navigation.
// Shows an onboarding screen if Accessibility permission is not yet granted.

import SwiftUI

struct SettingsWindow: View {

    // Sidebar selection
    @State private var selectedTab: SettingsTab = .gestures
    @State private var showOnboarding: Bool = !AccessibilityHelper.hasPermission

    // Observe rule engine & profile manager so the UI stays live.
    @StateObject private var ruleEngine = RuleEngine.shared
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var pluginLoader = PluginLoader.shared

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(onComplete: {
                    withAnimation(.spring(response: 0.4)) {
                        showOnboarding = false
                    }
                    // Start monitoring now that permission was granted.
                    TrackpadMonitor.shared.start()
                })
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                mainContent
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(.spring(response: 0.35), value: showOnboarding)
        // Listen for tab-switch notifications from AppDelegate.
        .onReceive(NotificationCenter.default.publisher(for: .gestureKitShowTab)) { note in
            if let tab = note.object as? String {
                if tab == "onboarding" {
                    showOnboarding = true
                } else if let match = SettingsTab(rawValue: tab) {
                    selectedTab = match
                    showOnboarding = false
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationSplitView {
            // MARK: Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.symbolName)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(180)
            // The sidebar toggle button is fine to leave on macOS 13.
            // On macOS 14+ it can be removed; users can hide it via View menu.
        } detail: {
            // MARK: Detail pane
            Group {
                switch selectedTab {
                case .gestures: GesturesView()
                case .actions:  ActionsView()
                case .profiles: ProfilesView()
                case .plugins:  PluginsView()
                case .about:    AboutView()
                }
            }
            .navigationTitle(selectedTab.title)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 500)
        .background(.ultraThinMaterial)
    }
}

// MARK: – SettingsTab

enum SettingsTab: String, CaseIterable {
    case gestures = "gestures"
    case actions  = "actions"
    case profiles = "profiles"
    case plugins  = "plugins"
    case about    = "about"

    var title: String {
        switch self {
        case .gestures: return "Gestures"
        case .actions:  return "Actions"
        case .profiles: return "App Profiles"
        case .plugins:  return "Plugins"
        case .about:    return "About"
        }
    }

    var symbolName: String {
        switch self {
        case .gestures: return "hand.draw.fill"
        case .actions:  return "bolt.fill"
        case .profiles: return "app.badge.fill"
        case .plugins:  return "puzzlepiece.extension.fill"
        case .about:    return "info.circle.fill"
        }
    }
}

// MARK: – Onboarding

/// First-launch screen that explains why Accessibility access is needed.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var isRequestingPermission = false
    @State private var permissionGranted = false

    // Poll for permission after the user visits System Settings.
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Icon view — uses symbolEffect on macOS 14+, plain image on macOS 13.
    @ViewBuilder
    private var appIcon: some View {
        let base = Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 72, weight: .thin))
            .foregroundStyle(
                LinearGradient(colors: [.white, Color.accentColor],
                               startPoint: .top, endPoint: .bottom)
            )
        if #available(macOS 15, *) {
            base.symbolEffect(.bounce, options: .repeating)
        } else {
            base
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hue: 0.64, saturation: 0.8, brightness: 0.18),
                         Color(hue: 0.68, saturation: 0.6, brightness: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                // Icon — symbolEffect(.bounce) requires macOS 14+.
                appIcon

                VStack(spacing: 12) {
                    Text("Welcome to GestureKit")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("GestureKit needs Accessibility access to intercept trackpad gestures system-wide. Your data stays on-device and is never shared.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                        
                    Text("Tip: If you've already checked the box but it's not working, macOS might be confused. Select GestureKit in System Settings, click the minus (-) button to remove it, and try again!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

                // Permission status
                HStack(spacing: 10) {
                    Image(systemName: permissionGranted ? "checkmark.circle.fill" : "lock.shield.fill")
                        .foregroundColor(permissionGranted ? .green : .yellow)
                        .font(.title2)
                    Text(permissionGranted
                         ? "Accessibility access granted ✓"
                         : "Accessibility access required")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(spacing: 12) {
                    Button(action: grantPermission) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text(isRequestingPermission ? "Opening System Settings…" : "Grant Accessibility Access")
                        }
                        .frame(width: 280, height: 44)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .font(.headline)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRequestingPermission || permissionGranted)
                    
                    if !permissionGranted {
                        Button("Click here to Reset macOS Permissions if it's stuck") {
                            resetTCC()
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    if permissionGranted {
                        Button("Continue →") { onComplete() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: permissionGranted)
            }
            .padding(48)
        }
        .onReceive(timer) { _ in
            if AccessibilityHelper.hasPermission && !permissionGranted {
                permissionGranted = true
            }
        }
    }

    private func grantPermission() {
        isRequestingPermission = true
        AccessibilityHelper.requestPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            AccessibilityHelper.openSystemSettings()
            isRequestingPermission = false
        }
    }
    
    private func resetTCC() {
        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", "com.anuradhapumudu.gesturekit"]
        try? task.run()
        
        // Give macOS a moment, then re-prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            grantPermission()
        }
    }
}
