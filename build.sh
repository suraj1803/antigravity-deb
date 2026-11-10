#!/usr/bin/env bash
#
# build.sh - Build Debian (.deb) package for Google Antigravity IDE
# Works on Debian, Ubuntu, Arch Linux, and any POSIX system with bash, tar, ar, and curl.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGNAME="antigravity-ide"
PKGVER="2.6.0"
BUILD_ID="5526304964083712"
PKGREL="2"
WATCHER_VER="2.5.6"

CACHE_DIR="${SCRIPT_DIR}/cache"
BUILD_BASE_DIR="${SCRIPT_DIR}/build"
DIST_DIR="${SCRIPT_DIR}/dist"

# Expected b2sums matching official AUR PKGBUILD
B2SUM_X86_64_TAR="1e931652fa5b99fe753ee2aa660f2f757b4b87612af83965fa7924231da816b5423fa033cddbbdcb99b629682d635e29b3c5233a68a25b4ce3100423326bca72"
B2SUM_X86_64_WATCHER="8a1b93db2872a1eb1dc095cd913c44c52a29adb5bd9f1c608e3baa2d5504c4fd0e72e9f429cbf931fb101f325d53f6b66d954ed40219a9f3099513924891d5fe"

B2SUM_AARCH64_TAR="92da83ebea4f03c10ed495e3631e74d9103864dde6cbb18a60c11f8aaa402b34e7681a48d51f61afa4c87a96146801605b3e47ce4bd962ae501813712c491963"
B2SUM_AARCH64_WATCHER="7c646a9085006c79f346b56f04e68be3708a878625aac8bf948c7bc5dccee6c7231206230be351fb2d4e6e9c58e9abcab55dd474a135484f4732738948e7a8d5"

msg() {
    printf "\033[1;34m::\033[0m \033[1m%s\033[0m\n" "$*"
}

success() {
    printf "\033[1;32m==>\033[0m \033[1m%s\033[0m\n" "$*"
}

warn() {
    printf "\033[1;33m==> WARNING:\033[0m \033[1m%s\033[0m\n" "$*"
}

err() {
    printf "\033[1;31m==> ERROR:\033[0m \033[1m%s\033[0m\n" "$*" >&2
    exit 1
}

verify_b2sum() {
    local file="$1"
    local expected="$2"
    if command -v b2sum >/dev/null 2>&1; then
        local actual
        actual="$(b2sum "$file" | cut -d' ' -f1)"
        if [[ "$actual" != "$expected" ]]; then
            err "Checksum mismatch for $(basename "$file"): expected $expected, got $actual"
        fi
        msg "Verified b2sum for $(basename "$file")"
    else
        warn "b2sum not found, skipping checksum verification"
    fi
}

download_file() {
    local url="$1"
    local dest="$2"
    local expected_sum="$3"

    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
        msg "Found cached $(basename "$dest")"
    else
        msg "Downloading $(basename "$dest") from ${url}..."
        curl -fSL --retry 3 --progress-bar -o "$dest.part" "$url"
        mv "$dest.part" "$dest"
    fi

    if [[ -n "$expected_sum" ]]; then
        verify_b2sum "$dest" "$expected_sum"
    fi
}

build_deb() {
    local target_arch="$1" # "amd64" or "arm64"
    local upstream_arch
    local watcher_npm_arch
    local tar_checksum
    local watcher_checksum

    case "$target_arch" in
        amd64)
            upstream_arch="linux-x64"
            watcher_npm_arch="linux-x64-glibc"
            tar_checksum="$B2SUM_X86_64_TAR"
            watcher_checksum="$B2SUM_X86_64_WATCHER"
            ;;
        arm64)
            upstream_arch="linux-arm"
            watcher_npm_arch="linux-arm64-glibc"
            tar_checksum="$B2SUM_AARCH64_TAR"
            watcher_checksum="$B2SUM_AARCH64_WATCHER"
            ;;
        *)
            err "Unsupported architecture: $target_arch. Choose amd64 or arm64."
            ;;
    esac

    local app_tar="${CACHE_DIR}/antigravity-ide-${PKGVER}-${target_arch}.tar.gz"
    local watcher_tgz="${CACHE_DIR}/watcher-${watcher_npm_arch}-${WATCHER_VER}.tgz"
    local app_url="https://dl.google.com/release2/j0qc3/antigravity/stable/${PKGVER}-${BUILD_ID}/${upstream_arch}/Antigravity%20IDE.tar.gz"
    local watcher_url="https://registry.npmjs.org/@parcel/watcher-${watcher_npm_arch}/-/watcher-${watcher_npm_arch}-${WATCHER_VER}.tgz"

    download_file "$app_url" "$app_tar" "$tar_checksum"
    download_file "$watcher_url" "$watcher_tgz" "$watcher_checksum"

    local build_dir="${BUILD_BASE_DIR}/${target_arch}"
    local pkg_root="${build_dir}/pkg"
    local debian_dir="${build_dir}/DEBIAN"

    msg "Preparing build tree in ${build_dir}..."
    rm -rf "$build_dir"
    mkdir -p "${pkg_root}/opt"
    mkdir -p "${pkg_root}/etc/apparmor.d"
    mkdir -p "${pkg_root}/usr/bin"
    mkdir -p "${pkg_root}/usr/share/applications"
    mkdir -p "${pkg_root}/usr/share/metainfo"
    mkdir -p "${pkg_root}/usr/share/mime/packages"
    mkdir -p "${pkg_root}/usr/share/pixmaps"
    mkdir -p "${pkg_root}/usr/share/bash-completion/completions"
    mkdir -p "${pkg_root}/usr/share/zsh/vendor-completions"
    mkdir -p "${pkg_root}/usr/share/doc/${PKGNAME}"
    mkdir -p "$debian_dir"

    msg "Extracting upstream application archive..."
    tar -xzf "$app_tar" -C "${pkg_root}/opt"
    mv "${pkg_root}/opt/Antigravity IDE" "${pkg_root}/opt/antigravity-ide"

    msg "Applying @parcel/watcher ${WATCHER_VER} fix (mitigating exit SIGTRAP coredump)..."
    local watcher_tmp="${build_dir}/watcher-unpack"
    mkdir -p "$watcher_tmp"
    tar -xzf "$watcher_tgz" -C "$watcher_tmp"
    local target_node="${pkg_root}/opt/antigravity-ide/resources/app/node_modules/@parcel/watcher/build/Release/watcher.node"
    if [[ ! -f "$target_node" ]]; then
        err "Target watcher.node not found at $target_node"
    fi
    install -Dm755 "${watcher_tmp}/package/watcher.node" "$target_node"
    rm -rf "$watcher_tmp"

    msg "Installing launchers, desktop files, completions, and metadata..."
    install -Dm755 "${SCRIPT_DIR}/antigravity-ide.sh" "${pkg_root}/usr/bin/${PKGNAME}"
    install -Dm644 "${SCRIPT_DIR}/antigravity-ide.desktop" "${pkg_root}/usr/share/applications/${PKGNAME}.desktop"
    install -Dm644 "${SCRIPT_DIR}/antigravity-ide-url-handler.desktop" "${pkg_root}/usr/share/applications/${PKGNAME}-url-handler.desktop"
    install -Dm644 "${SCRIPT_DIR}/antigravity-ide.appdata.xml" "${pkg_root}/usr/share/metainfo/${PKGNAME}.appdata.xml"
    install -Dm644 "${SCRIPT_DIR}/antigravity-ide.workspace.xml" "${pkg_root}/usr/share/mime/packages/${PKGNAME}-workspace.xml" 2>/dev/null || \
        install -Dm644 "${SCRIPT_DIR}/antigravity-ide-workspace.xml" "${pkg_root}/usr/share/mime/packages/${PKGNAME}-workspace.xml"
    install -Dm644 "${SCRIPT_DIR}/antigravity-ide.apparmor" "${pkg_root}/etc/apparmor.d/${PKGNAME}"
    install -Dm644 "${SCRIPT_DIR}/debian/copyright" "${pkg_root}/usr/share/doc/${PKGNAME}/copyright"

    # Shell completions
    local completions_dir="${pkg_root}/opt/antigravity-ide/resources/completions"
    if [[ -d "$completions_dir" ]]; then
        install -Dm644 "${completions_dir}/bash/antigravity-ide" \
            "${pkg_root}/usr/share/bash-completion/completions/${PKGNAME}"
        install -Dm644 "${completions_dir}/zsh/_antigravity-ide" \
            "${pkg_root}/usr/share/zsh/vendor-completions/_${PKGNAME}"
        rm -rf "$completions_dir"
    fi

    # Application Icon
    install -Dm644 "${pkg_root}/opt/antigravity-ide/resources/app/resources/linux/code.png" \
        "${pkg_root}/usr/share/pixmaps/${PKGNAME}.png"

    # Maintainer scripts
    install -Dm755 "${SCRIPT_DIR}/debian/postinst" "${debian_dir}/postinst"
    install -Dm755 "${SCRIPT_DIR}/debian/postrm" "${debian_dir}/postrm"

    msg "Generating md5sums and control file..."
    (
        cd "$pkg_root"
        find opt usr etc -type f ! -path 'DEBIAN/*' -exec md5sum {} + > "${debian_dir}/md5sums"
    )
    chmod 644 "${debian_dir}/md5sums"

    local installed_size
    installed_size="$(du -sk "$pkg_root" | cut -f1)"

    sed \
        -e "s/@VERSION@/${PKGVER}/g" \
        -e "s/@REVISION@/${PKGREL}/g" \
        -e "s/@DEB_ARCH@/${target_arch}/g" \
        -e "s/@INSTALLED_SIZE@/${installed_size}/g" \
        "${SCRIPT_DIR}/debian/control.in" > "${debian_dir}/control"
    chmod 644 "${debian_dir}/control"

    mkdir -p "$DIST_DIR"
    local deb_output="${DIST_DIR}/${PKGNAME}_${PKGVER}-${PKGREL}_${target_arch}.deb"

    msg "Packaging ${deb_output}..."
    if command -v dpkg-deb >/dev/null 2>&1; then
        # Merge DEBIAN into pkg_root for dpkg-deb
        cp -a "$debian_dir" "${pkg_root}/DEBIAN"
        dpkg-deb --build -Zxz --root-owner-group "$pkg_root" "$deb_output"
    else
        msg "dpkg-deb not present; building standard deb archive using ar + tar..."
        local work_archive="${build_dir}/deb-pkg"
        mkdir -p "$work_archive"

        echo "2.0" > "${work_archive}/debian-binary"

        # control.tar.gz
        (
            cd "$debian_dir"
            tar --owner=0 --group=0 --numeric-owner -czf "${work_archive}/control.tar.gz" .
        )

        # data.tar.xz
        (
            cd "$pkg_root"
            tar --owner=0 --group=0 --numeric-owner -cJf "${work_archive}/data.tar.xz" opt usr etc
        )

        (
            cd "$work_archive"
            ar -cr "$deb_output" debian-binary control.tar.gz data.tar.xz
        )
    fi

    success "Successfully created ${deb_output}"
}

usage() {
    echo "Usage: $0 [amd64 | arm64 | all | clean]"
    echo
    echo "Commands:"
    echo "  amd64   Build .deb for x86_64 architecture (default on x86_64)"
    echo "  arm64   Build .deb for aarch64 architecture (default on aarch64)"
    echo "  all     Build .deb for both amd64 and arm64"
    echo "  clean   Clean build directory"
    exit 0
}

TARGET="${1:-auto}"

if [[ "$TARGET" == "-h" || "$TARGET" == "--help" ]]; then
    usage
fi

if [[ "$TARGET" == "clean" ]]; then
    msg "Cleaning build artifacts..."
    rm -rf "$BUILD_BASE_DIR"
    success "Build directory cleaned."
    exit 0
fi

if [[ "$TARGET" == "auto" ]]; then
    case "$(uname -m)" in
        x86_64)  TARGET="amd64" ;;
        aarch64) TARGET="arm64" ;;
        *) err "Unsupported host architecture: $(uname -m). Please specify amd64 or arm64." ;;
    esac
fi

case "$TARGET" in
    amd64|arm64)
        build_deb "$TARGET"
        ;;
    all)
        build_deb "amd64"
        build_deb "arm64"
        ;;
    *)
        usage
        ;;
esac
