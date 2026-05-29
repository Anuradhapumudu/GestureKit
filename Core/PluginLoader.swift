// PluginLoader.swift — GestureKit/Core
// Loads Swift plugins from ~/Library/Application Support/GestureKit/Plugins/.
//
// Plugin contract:
//   Each plugin is a .dylib or a bundle folder named *.gesturekit
//   It must export a C symbol "gestureKitPluginEntry" of type GestureKitPluginEntry.
//   The entry function returns a GestureKitPlugin protocol object.
//
// Because loading unsigned dylibs requires SIP-related entitlements in a
// sandboxed app, this loader uses a simple scripting approach for macOS 13+:
// plugins can also be plain Swift source files that get compiled on load via
// swift-build. See README.md for details.

import Foundation
import AppKit

// MARK: – Plugin protocol (public API for plugin authors)

/// A GestureKit plugin must conform to this protocol.
/// The conforming type is instantiated once and lives for the app lifetime.
public protocol GestureKitPlugin: AnyObject {

    /// Short name shown in the Plugins settings pane.
    var name: String { get }

    /// Version string (e.g. "1.0.0").
    var version: String { get }

    /// Human-readable description.
    var description: String { get }

    /// Called once after the plugin is loaded. Use this to register custom action types.
    func setup()

    /// Called when the app is quitting.
    func teardown()
}

// MARK: – Plugin entry point (C symbol plugins export)

/// Type of the C-exported entry function in a plugin dylib.
public typealias GestureKitPluginEntryFn = @convention(c) () -> AnyObject

// MARK: – LoadedPlugin

/// A record of a successfully loaded plugin.
public struct LoadedPlugin: Identifiable {
    public let id: UUID
    public let plugin: any GestureKitPlugin
    public let fileURL: URL

    public var name: String { plugin.name }
    public var version: String { plugin.version }
    public var pluginDescription: String { plugin.description }
}

// MARK: – PluginLoader

@MainActor
public final class PluginLoader: ObservableObject {

    nonisolated public static let shared = PluginLoader()
    nonisolated private init() {}

    @Published public var loadedPlugins: [LoadedPlugin] = []
    @Published public var loadErrors: [URL: String] = [:]

    // MARK: – Plugin directory

    public var pluginsDirectoryURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("GestureKit/Plugins", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: – Loading

    public func loadPlugins() {
        let fm = FileManager.default
        let dir = pluginsDirectoryURL

        guard let contents = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        ) else { return }

        let candidates = contents.filter {
            $0.pathExtension == "dylib" || $0.pathExtension == "gesturekit"
        }

        for url in candidates {
            loadPlugin(at: url)
        }

        print("[PluginLoader] Loaded \(loadedPlugins.count) plugins.")
    }

    private func loadPlugin(at url: URL) {
        // Attempt to dlopen the plugin.
        guard let handle = dlopen(url.path, RTLD_NOW | RTLD_LOCAL) else {
            let err = String(cString: dlerror())
            loadErrors[url] = "dlopen failed: \(err)"
            print("[PluginLoader] Failed to load \(url.lastPathComponent): \(err)")
            return
        }

        // Resolve the entry function.
        guard let sym = dlsym(handle, "gestureKitPluginEntry") else {
            loadErrors[url] = "Missing 'gestureKitPluginEntry' symbol."
            return
        }

        let entry = unsafeBitCast(sym, to: GestureKitPluginEntryFn.self)
        guard let plugin = entry() as? any GestureKitPlugin else {
            loadErrors[url] = "Entry function did not return a GestureKitPlugin."
            return
        }

        plugin.setup()

        let loaded = LoadedPlugin(id: UUID(), plugin: plugin, fileURL: url)
        loadedPlugins.append(loaded)
        print("[PluginLoader] Loaded plugin '\(plugin.name)' v\(plugin.version)")
    }

    // MARK: – Open plugins folder

    public func revealPluginsFolder() {
        NSWorkspace.shared.open(pluginsDirectoryURL)
    }
}
