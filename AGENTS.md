# AGENTS.md - Antigravity IDE Debian Packaging

This repository builds binary Debian (`.deb`) packages for **Google Antigravity IDE** (`amd64` and `arm64`), adapting upstream releases and the Arch Linux AUR package implementation.

---

## Repository Overview

```
antigravity-ide-deb/
├── build.sh                               # Main build orchestration script
├── debian/
│   ├── control.in                         # Control template (macro-expanded during build)
│   ├── copyright                          # Machine-readable copyright & licensing info
│   ├── postinst                           # Post-installation script (mime, desktop, icon cache)
│   └── postrm                             # Post-removal script (cache cleanup)
├── antigravity-ide.sh                     # Runtime launcher wrapper script
├── antigravity-ide.desktop                # Main desktop entry
├── antigravity-ide-url-handler.desktop    # Protocol handler for antigravity-ide://
├── antigravity-ide.appdata.xml            # AppStream component metainfo
├── antigravity-ide-workspace.xml          # MIME descriptor for workspace files
├── cache/                                 # Download cache (git-ignored)
├── build/                                 # Ephemeral build directory (git-ignored)
├── dist/                                  # Output directory for .deb packages (git-ignored)
├── README.md                              # User-facing documentation
└── AGENTS.md                              # Instructions & technical guidelines for AI agents
```

---

## Build Commands

| Command | Action |
| :--- | :--- |
| `./build.sh` | Build `.deb` for host architecture (auto-detected `amd64` or `arm64`) |
| `./build.sh amd64` | Build `.deb` for `x86_64` / `amd64` |
| `./build.sh arm64` | Build `.deb` for `aarch64` / `arm64` |
| `./build.sh all` | Build `.deb` for both `amd64` and `arm64` |
| `./build.sh clean` | Remove `build/` directory artifacts |

The resulting packages are output to `dist/`:
- `dist/antigravity-ide_${PKGVER}-${PKGREL}_amd64.deb`
- `dist/antigravity-ide_${PKGVER}-${PKGREL}_arm64.deb`

---

## Upstream Release & Versioning

Upstream binaries are hosted on Google's CDN with the following URL structure:
```text
https://dl.google.com/release2/j0qc3/antigravity/stable/${PKGVER}-${BUILD_ID}/${UPSTREAM_ARCH}/Antigravity%20IDE.tar.gz
```
- `UPSTREAM_ARCH` is `linux-x64` for `amd64`, or `linux-arm` for `arm64`.
- `BUILD_ID` is Google's internal execution ID for that release (e.g., `5526304964083712` for `2.6.0`).

### Bumping to a New Version
When upgrading the package to a new upstream version:
1. Update `PKGVER`, `BUILD_ID`, and reset `PKGREL="1"` in `build.sh`.
2. Download or fetch the new archives and update `B2SUM_X86_64_TAR` and `B2SUM_AARCH64_TAR` in `build.sh`.
3. Check if `@parcel/watcher` workaround is still needed or needs version bump.
4. Run `./build.sh all` to test and generate updated packages.

---

## Critical Stability Workaround (@parcel/watcher)

Upstream bundles `@parcel/watcher 2.5.1`, which suffers from a race condition in static teardown (`parcel-bundler/watcher#216`), triggering a `SIGTRAP` crash / coredump on application exit.

- **Fix**: `build.sh` downloads the prebuilt `2.5.6` npm binary (`@parcel/watcher-linux-{x64,arm64}-glibc`) and replaces `opt/antigravity-ide/resources/app/node_modules/@parcel/watcher/build/Release/watcher.node`.
- **Integrity**: Do not remove this replacement unless an upstream Antigravity IDE release bundles `@parcel/watcher >= 2.5.6`.

---

## Package Architecture & Debian Conventions

1. **Launcher Script (`antigravity-ide.sh`)**:
   - Installed to `/usr/bin/antigravity-ide`.
   - Reads user flags from `$XDG_CONFIG_HOME/antigravity-ide-flags.conf` (defaults to `$HOME/.config`).
   - Delegates to `/opt/antigravity-ide/bin/antigravity-ide "$@" $ANTIGRAVITY_IDE_USER_FLAGS`.

2. **Debian Control (`debian/control.in`)**:
   - Includes dependencies for both legacy Debian/Ubuntu and modern releases (e.g., `libasound2 | libasound2t64`, `libgtk-3-0 | libgtk-3-0t64`).
   - Placeholder macros `@VERSION@`, `@REVISION@`, `@DEB_ARCH@`, and `@INSTALLED_SIZE@` are expanded by `build.sh`.

3. **Universal Packaging Engine**:
   - Uses `dpkg-deb` if available on the system.
   - Falls back automatically to native POSIX `ar` and `tar` if `dpkg-deb` is missing (allowing seamless builds on Arch Linux, Fedora, Alpine, or macOS).
   - Archive member order MUST strictly be:
     1. `debian-binary` (`2.0\n`)
     2. `control.tar.gz` (contains `control`, `md5sums`, `postinst`, `postrm` with `--numeric-owner 0:0`)
     3. `data.tar.xz` (contains payload files with `--numeric-owner 0:0`)

---

## Verification & Testing Guidelines

When making changes to this codebase:
1. Run `./build.sh` to ensure package build succeeds.
2. Verify package structure:
   ```bash
   ar -tv dist/antigravity-ide_*_amd64.deb
   ```
3. Verify control archive:
   ```bash
   ar -p dist/antigravity-ide_*_amd64.deb control.tar.gz | tar -tzv
   ```
4. Verify replacement of `watcher.node`:
   ```bash
   ar -p dist/antigravity-ide_*_amd64.deb data.tar.xz | tar -tvJ | grep 'watcher\.node'
   ```
5. Ensure `git status` remains clean (no build artifacts or cache files tracked).
