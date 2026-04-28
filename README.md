# PortPilot

**English** | [中文](README_zh.md)

A lightweight macOS menu bar app for managing TCP listening ports. Monitor, search, and kill processes — all from your status bar.

![alt text](image.png)

## Features

- **Status Bar Resident** — Lives in your menu bar, no Dock icon
- **Real-time Port Monitoring** — Shows all TCP LISTEN ports with process name & PID
- **Smart Grouping** — Auto-categorizes ports: Cloudflare Tunnels, K8s Port Forward, Docker, Local Dev, System, Other
- **Search & Filter** — Instantly filter by port number, process name, or PID
- **Process Management** — Kill processes with SIGTERM (graceful) or SIGKILL (force), with auto-escalation on timeout
- **Quick Actions** — Open `localhost:port` in browser, copy port number, or kill process
- **Keyboard Shortcuts** — `⌘R` Refresh, `⌘K` Kill All, `⌘,` Settings, `⌘Q` Quit
- **Dark & Light Mode** — Adapts to your system appearance
- **Configurable** — Custom refresh interval, port exclusion rules, hide system ports
- **Universal Binary** — Native support for both Intel (x86_64) and Apple Silicon (arm64)
- **Lightweight** — ~1MB, minimal CPU & memory footprint

## Requirements

- macOS 12.0 (Monterey) or later
- Intel or Apple Silicon Mac

## Installation

### Download Release

Download the latest `PortPilot.dmg` from [Releases](../../releases), open it, and drag `PortPilot.app` to your Applications folder.

### Build from Source

```bash
git clone https://github.com/Ghjsw/PortPilot.git
cd PortPilot
xcodebuild -project PortPilot.xcodeproj -scheme PortPilot \
    -configuration Release \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/PortPilot-*/Build/Products/Release/`.

## Usage

1. Launch PortPilot — it appears as a ⇅ icon in your menu bar
2. Click the icon to open the port list panel
3. Hover over any port row to reveal action buttons
4. Right-click for context menu with all actions

### Keyboard Shortcuts

| Shortcut | Action                    |
| -------- | ------------------------- |
| `⌘R`     | Refresh port list         |
| `⌘K`     | Kill all listed processes |
| `⌘,`     | Open settings             |
| `⌘Q`     | Quit PortPilot            |

### Port Groups

| Group              | Description                                            |
| ------------------ | ------------------------------------------------------ |
| Cloudflare Tunnels | `cloudflared` processes                                |
| K8s Port Forward   | `kubectl` processes                                    |
| Docker             | `docker`, `docker-proxy`, `containerd`                 |
| Local Dev          | `node`, `python`, `ruby`, `java`, `nginx`, etc.        |
| System             | System processes and well-known ports (22, 80, 443...) |
| Other              | Everything else                                        |

## Configuration

### Settings

- **Refresh Interval** — 2s / 5s / 10s / 30s / Off (manual only)
- **Hide System Ports** — Filter out OS-level listening ports
- **Excluded Ports** — Comma-separated list of ports to exclude (e.g. `22, 80, 443`)

### Why No App Sandbox?

PortPilot needs access to system process information (`lsof`) and the ability to send signals to processes (`kill()`). These operations are incompatible with App Sandbox, so the app is distributed outside the Mac App Store with Developer ID signing + Notarization.

## Architecture

```
PortPilot/
├── App/              # @main entry + AppDelegate (LSUIElement)
├── StatusBar/        # NSStatusItem + NSPopover controller
├── Models/           # PortInfo, PortGroup data models
├── Services/         # PortScanner, ProcessKiller, PortGroupClassifier
├── ViewModels/       # PortListViewModel (Combine + async/await)
├── Views/            # SwiftUI views (list, search, settings, bottom bar)
├── Resources/        # Info.plist, Entitlements, Assets
└── Utilities/        # Constants, Extensions
```

**Tech Stack:** AppKit (NSStatusItem + NSPopover) + SwiftUI | Combine | POSIX signals | `lsof`

## License

MIT License. See [LICENSE](LICENSE) for details.
