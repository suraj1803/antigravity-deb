# antigravity-ide-deb

Debian (`.deb`) packaging generator for **Google Antigravity IDE**, ported directly from the Arch Linux AUR package implementation with all stability fixes and desktop integrations.

## Features

- **Upstream Release Support**: Packages the official Google Antigravity IDE stable release for both `amd64` (x86_64) and `arm64` (aarch64).
- **Core Dump / SIGTRAP Fix**: Overwrites upstream bundled `@parcel/watcher` 2.5.1 with the prebuilt 2.5.6 release from npm, preventing the known exit race condition (`SIGTRAP` in NodeService).
- **Desktop & System Integration**:
  - Desktop entries (`antigravity-ide.desktop` and `antigravity-ide-url-handler.desktop`).
  - AppStream metainfo specification (`antigravity-ide.appdata.xml`).
  - Shared MIME workspace definition (`antigravity-ide-workspace.xml`).
  - Shell autocompletions for Bash (`/usr/share/bash-completion/completions/antigravity-ide`) and Zsh (`/usr/share/zsh/vendor-completions/_antigravity-ide`).
  - Launcher script (`/usr/bin/antigravity-ide`) supporting user flag customization via `~/.config/antigravity-ide-flags.conf`.
- **Zero-Dependency Universal Build**: Can be built on Debian/Ubuntu using `dpkg-deb`, or on any Linux distribution (including Arch Linux) using standard POSIX tools (`bash`, `tar`, `ar`, `curl`).

## System Compatibility & Requirements

- **Supported Architectures**: `amd64` (x86_64) and `arm64` (aarch64).
- **Minimum OS Versions**:
  - **Ubuntu**: 20.04 LTS or later (including 22.04, 24.04 LTS, 24.10)
  - **Debian**: 10 (Buster) or later (including 11, 12, 13/Trixie)
  - **Linux Mint**: 20+ / **Pop!_OS**: 20.04+
- **Baseline Dependencies**: `glibc >= 2.28`, `GTK >= 3.24` (compatible with both legacy and `t64` transitional packages).
- **Application Version**: Antigravity IDE `2.6.0` (Code-OSS base `1.107.0`).

## Requirements for Building

- `bash`
- `curl`
- `tar`
- `ar` (from `binutils`)
- `b2sum` (optional, for verifying integrity checksums)
- `xz`

## Usage

### 1. Build for the current architecture (auto-detected):
```bash
./build.sh
```

### 2. Build for a specific architecture:
```bash
# For x86_64
./build.sh amd64

# For ARM64 / AArch64
./build.sh arm64

# For both architectures
./build.sh all
```

The resulting `.deb` files will be placed in the `dist/` directory:
```
dist/antigravity-ide_2.6.0-1_amd64.deb
dist/antigravity-ide_2.6.0-1_arm64.deb
```

### 3. Installing on Debian / Ubuntu:
```bash
sudo apt install ./dist/antigravity-ide_2.6.0-1_amd64.deb
```

## Custom Launch Flags

Users can pass custom launch arguments by adding them to:
```bash
~/.config/antigravity-ide-flags.conf
```
Comments starting with `#` are automatically ignored.

## License

- Packaging scripts and desktop files: `0BSD` (SPDX)
- Google Antigravity IDE application: `LicenseRef-Google-Antigravity`
