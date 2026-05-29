// AppleScriptAction.swift — GestureKit/Actions
// Executes an AppleScript source string using NSAppleScript.
// Runs on a background thread to avoid blocking the main run loop.

import Foundation

public enum AppleScriptAction {

    /// Execute the given AppleScript source. Errors are logged but not thrown.
    public static func run(source: String) async {
        // NSAppleScript must be used on the main thread.
        await MainActor.run {
            var error: NSDictionary?
            let script = NSAppleScript(source: source)
            script?.executeAndReturnError(&error)
            if let err = error {
                print("[AppleScriptAction] Error: \(err)")
            }
        }
    }
}
