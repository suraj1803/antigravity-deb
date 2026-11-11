# Google Antigravity IDE — Debian & Ubuntu Packaging

[![Release](https://img.shields.io/github/v/release/suraj1803/antigravity-deb?color=blue&logo=github)](https://github.com/suraj1803/antigravity-deb/releases)
[![Build & Release](https://img.shields.io/github/actions/workflow/status/suraj1803/antigravity-deb/release.yml?branch=main&label=build)](https://github.com/suraj1803/antigravity-deb/actions)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-blueviolet)](https://github.com/suraj1803/antigravity-deb/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Binary Debian (`.deb`) packaging generator for **Google Antigravity IDE**, ported from the Arch Linux AUR package implementation with native stability fixes, multi-architecture support, and full Ubuntu/Debian system integration.

---

## ⚡ Quick Install

Download the latest `.deb` package directly from [GitHub Releases](https://github.com/suraj1803/antigravity-deb/releases):

### For Intel / AMD 64-bit (`amd64` / `x86_64`)
```bash
sudo apt update
sudo apt install -y curl
curl -LO $(curl -s https://api.github.com/repos/suraj1803/antigravity-deb/releases/latest | grep "browser_download_url.*amd64.deb" | cut -d '"' -f 4)
sudo apt install ./antigravity-ide_*_amd64.deb
```

### For ARM 64-bit (`arm64` / `aarch64` / Raspberry Pi 64-bit / Apple Silicon VMs)
```bash
sudo apt update
sudo apt install -y curl
curl -LO $(curl -s https://api.github.com/repos/suraj1803/antigravity-deb/releases/latest | grep "browser_download_url.*arm64.deb" | cut -d '"' -f 4)
sudo apt install ./antigravity-ide_*_arm64.deb
```

*(Using `apt install ./<file>.deb` automatically fetches and installs any missing system dependencies).*

---

## 🌟 Key Features

* **Official Upstream Releases**: Packages official Google CDN binaries for Antigravity IDE (`2.6.0`, built on Code-OSS `1.107.0`).
* **Ubuntu 24.04+ Sandbox Support**: Bundles an AppArmor profile (`/etc/apparmor.d/antigravity-ide`) that authorizes unprivileged user namespaces, allowing Chromium's security sandbox to run natively without requiring `--no-sandbox`.
* **Exit SIGTRAP / Crash Fix**: Replaces bundled `@parcel/watcher` 2.5.1 with prebuilt 2.5.6 from npm, mitigating the known teardown race condition (`SIGTRAP` in NodeService on app exit).
* **Multi-Architecture**: Native packages for both **`amd64`** and **`arm64`**.
* **Complete Desktop Integration**:
  * Desktop application menu entry (`antigravity-ide.desktop`)
  * Protocol URL handler (`antigravity-ide-url-handler.desktop` for `antigravity-ide://`)
  * AppStream metadata specification (`antigravity-ide.appdata.xml`)
  * Workspace MIME descriptor (`antigravity-ide-workspace.xml`)
  * Shell autocompletions for **Bash** (`/usr/share/bash-completion/completions/antigravity-ide`) and **Zsh** (`/usr/share/zsh/vendor-completions/_antigravity-ide`)
* **Zero-Dependency Universal Build**: Build `.deb` packages on Debian/Ubuntu using `dpkg-deb`, or on any Linux distribution (Arch, Fedora, Alpine, macOS) using POSIX tools (`bash`, `tar`, `ar`, `curl`).

---

## 💻 System Compatibility

| OS / Distribution | Minimum Supported Version | Status |
| :--- | :--- | :--- |
| **Ubuntu** | 20.04 LTS (Focal) or newer *(20.04, 22.04, 24.04 LTS, 24.10, 26.04)* | Fully Supported |
| **Debian** | Debian 10 (Buster) or newer *(Debian 10, 11, 12, 13/Trixie)* | Fully Supported |
| **Linux Mint** | Mint 20 or newer | Fully Supported |
| **Pop!_OS** | 20.04 LTS or newer | Fully Supported |

> [!NOTE]
> Supports both legacy library names and modern 64-bit `time_t` packages (e.g. `libgtk-3-0 | libgtk-3-0t64`, `libasound2 | libasound2t64`).

---

## 🛠️ Building From Source

### Build Requirements
* `bash` (>= 4.0)
* `curl`
* `tar`
* `ar` (from `binutils`)
* `xz`
* `b2sum` *(optional, for checksum verification)*
* `dpkg-deb` *(optional, automatically falls back to `ar + tar` if missing)*

### Build Commands

```bash
# 1. Clone the repository
git clone https://github.com/suraj1803/antigravity-deb.git
cd antigravity-deb

# 2. Build for host architecture (auto-detected):
./build.sh

# Or build for a specific architecture:
./build.sh amd64   # Intel/AMD 64-bit
./build.sh arm64   # ARM 64-bit
./build.sh all     # Both architectures

# Clean build artifacts:
./build.sh clean
```

Outputs are written to the [`dist/`](dist/) directory:
```
dist/antigravity-ide_2.6.0-1_amd64.deb
dist/antigravity-ide_2.6.0-1_arm64.deb
```

---

## ⚙️ Custom Flags Configuration

You can customize runtime flags without modifying application shortcuts by creating:
```bash
~/.config/antigravity-ide-flags.conf
```

Lines starting with `#` are treated as comments. Useful examples:

```ini
# Force Wayland native windowing
--ozone-platform-hint=auto
--enable-features=WaylandWindowDecorations

# Disable hardware GPU acceleration (troubleshooting graphics drivers)
# --disable-gpu

# Custom user data directory
# --user-data-dir=~/.config/antigravity-ide-custom
```

---

## 📂 Repository Structure

```
antigravity-deb/
├── build.sh                               # Universal package build script
├── debian/
│   ├── control.in                         # Debian package control template
│   ├── copyright                          # Machine-readable licensing
│   ├── postinst                           # Post-installation maintenance script
│   └── postrm                             # Cleanup on uninstallation
├── antigravity-ide.apparmor               # AppArmor security profile (Ubuntu 24.04+)
├── antigravity-ide.sh                     # Runtime launcher wrapper
├── antigravity-ide.desktop                # Main desktop application shortcut
├── antigravity-ide-url-handler.desktop    # Protocol handler for antigravity-ide://
├── antigravity-ide.appdata.xml            # AppStream component specification
├── antigravity-ide-workspace.xml          # Shared MIME workspace descriptor
├── cache/                                 # Download cache (git-ignored)
├── dist/                                  # Output directory for .deb packages (git-ignored)
└── .github/workflows/release.yml          # Automated CI/CD release workflow
```

---

## 📄 License & Attribution

* **Packaging Scripts, Profiles & Configurations**: Licensed under the [MIT License](LICENSE).
  * Copyright (c) 2026 Suraj Biswas & Arch Linux Contributors.
* **Google Antigravity IDE Application**: Property of Google LLC and distributed under Google's proprietary terms (`LicenseRef-Google-Antigravity`). See upstream license details inside the package at `/opt/antigravity-ide/resources/app/LICENSE.txt`.
