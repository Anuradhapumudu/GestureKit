# GestureKit

GestureKit is a powerful, customizable macOS application that allows you to trigger system actions and custom shortcuts using multi-touch trackpad gestures.

## Features

- **Custom Trackpad Zones:** Divide your trackpad into specific physical zones (Left Edge, Right Edge, Top Edge, Bottom Edge, Corners, and Centre).
- **Multi-Touch Gestures:** Support for 2-finger, 3-finger, and 4-finger swipes and taps.
- **System Integrations:** Adjust screen brightness, keyboard backlight, volume, media playback, and more.
- **Shortcuts & Scripts:** Trigger Apple Shortcuts, execute AppleScripts, or launch specific applications right from your trackpad.
- **Dynamic UI:** Real-time visual trackpad diagram to configure and manage your gesture rules.
- **Customizable Dimensions:** Adjust the exact physical width of your edge zones to suit your tracking preferences.

## Requirements

- macOS 13.0 or later
- Accessibility Permissions (required to intercept trackpad events globally)

## Installation

### Download Pre-built DMG
You can download the latest compiled `.dmg` from the **Releases** tab on GitHub.
1. Download `GestureKit.dmg`.
2. Open the file and drag `GestureKit.app` into your `/Applications` folder.
3. Launch `GestureKit` and follow the on-screen prompt to grant Accessibility permissions.

### Build from Source
1. Clone the repository: `git clone https://github.com/Anuradhapumudu/GestureKit.git`
2. Open the project folder in Terminal.
3. Run `swift run` to build and launch the app in debug mode.

## How it Works

GestureKit hooks into macOS's private `MultitouchSupport.framework` to read raw finger positions from the trackpad surface. This allows the app to know *exactly* where your fingers are touching, bypassing standard cursor coordinates, enabling precise edge and corner gestures.

## Privacy

GestureKit operates entirely on-device. No trackpad data, keystrokes, or gesture information is ever transmitted or stored off your machine.
