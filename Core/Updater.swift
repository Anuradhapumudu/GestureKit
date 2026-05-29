// Updater.swift — GestureKit/Core
// Checks GitHub for new releases and downloads the .dmg file.

import Foundation
import AppKit

public final class Updater {
    
    public static let shared = Updater()
    private init() {}
    
    private let repoURL = "https://api.github.com/repos/Anuradhapumudu/GestureKit/releases/latest"
    
    /// Checks for updates. 
    /// - Parameter showNoUpdateAlert: If true, shows an alert when up-to-date. (Use true for manual checks, false for startup check).
    public func checkForUpdates(showNoUpdateAlert: Bool = false) {
        guard let url = URL(string: repoURL) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                if showNoUpdateAlert {
                    self?.showAlert(title: "Update Check Failed", message: "Could not connect to GitHub.")
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    
                    let newVersion = tagName.replacingOccurrences(of: "v", with: "")
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    
                    if newVersion > currentVersion {
                        // We have a new version!
                        if let assets = json["assets"] as? [[String: Any]],
                           let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
                           let downloadURLString = dmgAsset["browser_download_url"] as? String,
                           let downloadURL = URL(string: downloadURLString) {
                            
                            DispatchQueue.main.async {
                                self?.promptUpdate(newVersion: newVersion, downloadURL: downloadURL)
                            }
                        }
                    } else {
                        if showNoUpdateAlert {
                            self?.showAlert(title: "Up to Date", message: "You are running the latest version of GestureKit (\(currentVersion)).")
                        }
                    }
                }
            } catch {
                if showNoUpdateAlert {
                    self?.showAlert(title: "Update Check Failed", message: "Failed to parse GitHub response.")
                }
            }
        }
        task.resume()
    }
    
    private func promptUpdate(newVersion: String, downloadURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "GestureKit \(newVersion) is available! Would you like to update and relaunch now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update and Relaunch")
        alert.addButton(withTitle: "Later")
        
        if let window = NSApplication.shared.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    self.downloadAndUpdate(url: downloadURL)
                }
            }
        } else {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.downloadAndUpdate(url: downloadURL)
            }
        }
    }
    
    private func downloadAndUpdate(url: URL) {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let destinationURL = downloadsDir.appendingPathComponent(url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        // Let the user know we are downloading
        showAlert(title: "Downloading Update...", message: "GestureKit is downloading the update. The app will automatically restart in a few moments.")
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                self?.showAlert(title: "Download Failed", message: "Could not download the update.")
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                self?.executeInstallScript(dmgURL: destinationURL)
            } catch {
                self?.showAlert(title: "File Error", message: "Could not save the downloaded update.")
            }
        }
        task.resume()
    }
    
    private func executeInstallScript(dmgURL: URL) {
        let scriptPath = "/tmp/gesturekit_updater.sh"
        let appPath = Bundle.main.bundlePath
        
        let scriptContent = """
        #!/bin/bash
        # Wait for GestureKit to exit
        sleep 2
        
        # Mount the DMG silently
        hdiutil attach "\(dmgURL.path)" -mountpoint /Volumes/GestureKitUpdate -nobrowse -quiet
        
        # Replace the current app
        rm -rf "\(appPath)"
        cp -a /Volumes/GestureKitUpdate/GestureKit.app "\(appPath)"
        
        # Remove quarantine flag
        xattr -cr "\(appPath)"
        
        # Unmount the DMG
        hdiutil detach /Volumes/GestureKitUpdate -quiet
        
        # Relaunch GestureKit
        open "\(appPath)"
        
        # Clean up the DMG (optional, but nice)
        rm "\(dmgURL.path)"
        """
        
        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            
            // Make executable
            let task = Process()
            task.launchPath = "/bin/chmod"
            task.arguments = ["+x", scriptPath]
            try task.run()
            task.waitUntilExit()
            
            // Run the updater script in the background using nohup
            let runTask = Process()
            runTask.launchPath = "/usr/bin/nohup"
            runTask.arguments = [scriptPath]
            try runTask.run()
            
            // Quit the app immediately so the script can replace it
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
            
        } catch {
            self.showAlert(title: "Update Failed", message: "Could not create the update script.")
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            
            if let window = NSApplication.shared.windows.first {
                alert.beginSheetModal(for: window)
            } else {
                alert.runModal()
            }
        }
    }
}
