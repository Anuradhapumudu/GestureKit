// PluginsView.swift — GestureKit/UI
// Shows installed GestureKit plugins, their status, and a button to open the plugins folder.

import SwiftUI

struct PluginsView: View {

    @StateObject private var pluginLoader = PluginLoader.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Installed Plugins")
                        .font(.headline)
                    Text("Drop .gesturekit or .dylib files into the plugins folder to extend GestureKit.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    pluginLoader.revealPluginsFolder()
                } label: {
                    Label("Open Plugins Folder", systemImage: "folder.fill")
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            if pluginLoader.loadedPlugins.isEmpty && pluginLoader.loadErrors.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.3))

                    Text("No plugins installed")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.secondary)

                    Text("Plugins let you add custom actions, gesture types,\nand integrations. Check the README for how to create one.")
                        .font(.body)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)

                    Button("Open Plugins Folder") {
                        pluginLoader.revealPluginsFolder()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                List {
                    // Successfully loaded plugins
                    if !pluginLoader.loadedPlugins.isEmpty {
                        Section("Loaded") {
                            ForEach(pluginLoader.loadedPlugins) { loaded in
                                PluginRowView(loaded: loaded)
                            }
                        }
                    }

                    // Plugins that failed to load
                    if !pluginLoader.loadErrors.isEmpty {
                        Section("Errors") {
                            ForEach(Array(pluginLoader.loadErrors.keys), id: \.self) { url in
                                HStack {
                                    Image(systemName: "xmark.octagon.fill")
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(url.lastPathComponent)
                                            .font(.callout.weight(.medium))
                                        Text(pluginLoader.loadErrors[url] ?? "Unknown error")
                                            .font(.caption)
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

// MARK: – PluginRowView

struct PluginRowView: View {
    let loaded: LoadedPlugin

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: "puzzlepiece.extension.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(loaded.name)
                        .font(.callout.weight(.semibold))
                    Text("v\(loaded.version)")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
                Text(loaded.pluginDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .padding(.vertical, 6)
    }
}
