![Bundle](https://raw.githubusercontent.com/LukeMutlow-21/Bundle/refs/heads/main/Bundle/Banner.png)

# Bundle

**Bundle** is a lightweight macOS utility for packaging `.app` bundles into `.pkg` installers — built for Mac admins and IT professionals who need a fast, no-fuss way to create packages for MDM deployment.

![macOS](https://img.shields.io/badge/macOS-13%2B-green)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Notarised](https://img.shields.io/badge/notarised-no-red)

---

## Why Bundle?

Creating `.pkg` installers normally means dropping into Terminal and wrestling with `pkgbuild` or `productbuild`. Bundle gives you a clean native UI to do the same thing in seconds — select an app, choose a destination, and hit **Create Package**.

---

## Features

- 📦 Packages any `.app` from `/Applications` into a `.pkg` installer
- 🔍 Automatically reads the app's bundle identifier, version, and install location from its `Info.plist`
- 🖥️ Native SwiftUI interface — no Electron, no dependencies
- 🌗 Light and dark mode support
- ⌘↩ Keyboard shortcut to build

---

## Requirements

- macOS 13.0 Ventura or later
- Xcode 15+ (if building from source)

---

## Installation

### Download (Recommended)

Download the latest release from the [Releases](../../releases) page and move `Bundle.app` to your `/Applications` folder.

### Build from Source

```bash
git clone https://github.com/yourusername/bundle.git
cd bundle
open Bundle.xcodeproj
```

Build and run in Xcode (`⌘R`).

---

## ⚠️ Unsigned App — Important

Bundle is currently unsigned and not notarised by Apple. To open Bundle for the first time:

1. Download the .Zip file
2. Drag the Application into /Applications
3. Open Bundle

This is only required once. After, Bundle will open normally.

## Usage

1. Launch Bundle
2. Select an application from the sidebar
3. Confirm or change the output destination
4. Review the technical details — bundle identifier, version, install location
5. Click **Create Package** (or press `⌘↩`)

The `.pkg` file will be saved to your chosen destination, ready for deployment via Jamf, Mosyle, Kandji, or any other MDM.

---

© 2026 Luke Mutlow. All rights reserved.
