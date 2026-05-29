// AboutView.swift — GestureKit/UI
// App information, version, MIT license text, and GitHub link.

import SwiftUI

struct AboutView: View {

    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    private let githubURL = URL(string: "https://github.com/your-username/GestureKit")!

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hue: 0.64, saturation: 0.8, brightness: 0.5),
                                        Color(hue: 0.75, saturation: 0.7, brightness: 0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 40, weight: .thin))
                            .foregroundColor(.white)
                    }

                    Text("GestureKit")
                        .font(.largeTitle.bold())

                    Text("Version \(version) (Build \(build))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Text("A free, open-source trackpad gesture customiser\nfor macOS — the BetterTouchTool alternative.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Divider()

                // Features grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(features, id: \.title) { feature in
                        FeatureCard(icon: feature.icon, title: feature.title, desc: feature.desc)
                    }
                }

                Divider()

                // License
                VStack(alignment: .leading, spacing: 12) {
                    Text("MIT License")
                        .font(.headline)

                    Text(mitLicenseText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Links
                HStack(spacing: 16) {
                    Link(destination: githubURL) {
                        Label("GitHub", systemImage: "link")
                    }
                    .buttonStyle(.bordered)

                    Button("Report an Issue") {
                        NSWorkspace.shared.open(
                            githubURL.appendingPathComponent("issues/new")
                        )
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Check for Updates...") {
                        Updater.shared.checkForUpdates(showNoUpdateAlert: true)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(32)
            .frame(maxWidth: 560)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Features data

    private let features: [(icon: String, title: String, desc: String)] = [
        ("rectangle.3.group.fill",    "Zone Gestures",    "Left/right/centre scroll zones for volume, brightness, and more."),
        ("app.badge.fill",            "App Profiles",     "Different gesture sets per frontmost app."),
        ("puzzlepiece.extension.fill","Plugin System",    "Drop in Swift dylibs to add custom actions."),
        ("exclamationmark.triangle",  "Conflict Resolver","Warns when a gesture clashes with macOS system gestures."),
        ("bolt.fill",                 "Rich Actions",     "Volume, brightness, shortcuts, AppleScript, key combos."),
        ("hand.draw.fill",            "Visual Editor",    "Interactive trackpad diagram — tap a zone to configure."),
    ]

    private let mitLicenseText = """
MIT License

Copyright (c) 2025 GestureKit Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"""
}

// MARK: – FeatureCard

struct FeatureCard: View {
    let icon: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.bold())
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
