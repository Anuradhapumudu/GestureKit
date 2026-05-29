<div align="center">
  <h1>✨ GestureKit ✨</h1>
  <p><strong>A powerful, customizable macOS application that allows you to trigger system actions and custom shortcuts using advanced multi-touch trackpad gestures.</strong></p>
  
  [![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/macos)
  [![Swift](https://img.shields.io/badge/Swift-5.10-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
</div>

---

## ✨ Features

- 🎯 **Custom Trackpad Zones:** Divide your physical trackpad into specific active zones (Left Edge, Right Edge, Top Edge, Bottom Edge, Corners, and Centre).
- ✋ **Advanced Multi-Touch:** First-class support for 2-finger, 3-finger, and 4-finger swipes, pinches, rotations, and taps.
- ⚙️ **Deep System Integrations:** Control your Mac's screen brightness, keyboard backlight, volume, and media playback seamlessly.
- 🚀 **Shortcuts & Scripts:** Trigger Apple Shortcuts, execute raw AppleScripts, send keystrokes, or launch specific applications right from your trackpad.
- 🎨 **Dynamic UI:** A beautiful, real-time visual trackpad diagram lets you configure and manage your gesture rules effortlessly.
- 📏 **Customizable Dimensions:** Adjust the exact physical width of your edge zones to suit your personal tracking preferences.

---

## 📥 Installation

The easiest way to install GestureKit is by downloading the pre-built installer.

1. Navigate to the [**Releases**](../../releases/latest) tab on GitHub.
2. Download the latest `GestureKit.dmg` file.
3. Open the `.dmg` and drag `GestureKit.app` into your `/Applications` folder.
4. Launch `GestureKit` and follow the on-screen prompt to grant **Accessibility permissions** (required to intercept gestures system-wide).

---

## 🛠️ Build from Source

If you prefer to compile GestureKit yourself, it's incredibly easy using SwiftPM.

1. Clone the repository:
   ```bash
   git clone https://github.com/Anuradhapumudu/GestureKit.git
   cd GestureKit
   ```
2. Build and run the app:
   ```bash
   swift run
   ```

---

## 🧠 How it Works

GestureKit hooks directly into macOS's private `MultitouchSupport.framework` to read raw finger positions from the trackpad surface. This allows the app to know *exactly* where your fingers are physically touching the glass, entirely bypassing standard on-screen cursor coordinates. This low-level integration is what makes our precise edge and corner gestures possible!

---

## 🤝 Contributing

We welcome contributions from the community! Whether you want to fix a bug, add a new system action, or improve the UI, your help is highly appreciated. 

### How to Contribute:
1. **Fork** the repository.
2. **Create a branch** for your feature or bugfix (`git checkout -b feature/awesome-new-action`).
3. **Commit** your changes (`git commit -m 'Added an awesome new gesture action'`).
4. **Push** to the branch (`git push origin feature/awesome-new-action`).
5. **Open a Pull Request** and describe the changes you've made!

If you find a bug or have a feature request, please don't hesitate to open an [**Issue**](../../issues)!

---

## 🔒 Privacy

**GestureKit operates 100% on-device.** No trackpad data, keystrokes, or gesture information is ever transmitted, logged, or stored off your machine. 

---
<div align="center">
  Made with ❤️ for macOS power users.
</div>
