// ShortcutAction.swift — GestureKit/Actions
// Runs an Apple Shortcut by name using the `shortcuts run` CLI command.
// Shortcuts app must be installed and the shortcut must exist in the user's library.

import Foundation

public enum ShortcutAction {

    /// Run a Shortcut by name. Runs asynchronously; errors are logged but not thrown.
    public static func run(name: String) async {
        // `shortcuts run "<Name>"` is the CLI interface to the Shortcuts app.
        // Available on macOS 12+.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", name]

        // Capture stderr for error reporting.
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8) ?? "(no output)"
                print("[ShortcutAction] Shortcut '\(name)' failed: \(errMsg)")
            }
        } catch {
            print("[ShortcutAction] Could not launch shortcuts CLI: \(error)")
        }
    }
}
