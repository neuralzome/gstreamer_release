#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS=$(nproc --all)
THREADS=$((THREADS > 1 ? THREADS - 1 : 1))
VENV_DIR="/tmp/gst-build-venv"
INSTALL_DIR="$SCRIPT_DIR/gstreamer-install"
RS_INSTALL_DIR="$SCRIPT_DIR/gst-plugins-rs-install"
PLATFORM=""
AARCH=""

export PATH="$HOME/.cargo/bin:$PATH"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

detect_platform() {
  case $(uname -m) in
  x86_64)
    PLATFORM="amd64"
    AARCH="x86_64"
    ;;
  aarch64)
    PLATFORM="arm64"
    AARCH="aarch64"
    ;;
  *)
    error "Unsupported architecture: $(uname -m)"
    exit 1
    ;;
  esac
  log "Detected platform: ${PLATFORM}, aarch: ${AARCH}"
}
install_system_packages() {
  log "Updating system packages..."
  sudo apt-get update
  log "Done"

  sudo ln -fs /usr/share/zoneinfo/UTC /etc/localtime
  sudo apt-get install -y tzdata

  packages=(
    lsb-release
    libserial-dev
    pkgconf
    libclang-dev
    libatk-bridge2.0
    libfontconfig1-dev
    libfreetype6-dev
    libglib2.0-dev
    libgtk-3-dev
    libssl-dev
    libxcb-render0-dev
    libxcb-shape0-dev
    libxcb-xfixes0-dev
    libxkbcommon-dev
    libxkbcommon-x11-dev
    patchelf
    unzip
    software-properties-common
    ca-certificates
    doxygen
    g++
    libeigen3-dev
    libgdal-dev
    python3-dev
    libpython3-dev
    python3-matplotlib
    python3-tk
    lcov
    libgtest-dev
    libtbb-dev
    swig
    libgeos-dev
    gnuplot
    libtinyxml2-dev
    nlohmann-json3-dev
    tmuxp
    rtklib
    lz4
    zstd
    flex
    bison
    libvpx-dev
    libx264-dev
    libyuv-dev
    libopus-dev
    libsrtp2-1
    libsrtp2-dev
    nasm
    git-lfs
  )
  log "Installing apt packages..."
  sudo apt-get install -y "${packages[@]}"
  log "Done"
  git config --global --add safe.directory "$(pwd)"

}


install_dependencies() {
  log "Installing build dependencies..."
  # Create venv and install meson inside it
  if [ ! -d "$VENV_DIR" ]; then
    log "Creating build venv..."
    python3 -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  pip install meson
  log "meson installed in venv at $(which meson)"

  if ! command -v rustc >/dev/null 2>&1; then
    log "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup default 1.85.0
  fi

  log "Dependencies installed."
}

install_ffmpeg7() {
  local version=""
  local full_version=""

  # Check if libavformat is available via pkg-config
  if pkg-config --exists libavformat 2>/dev/null; then
    full_version=$(pkg-config --modversion libavformat 2>/dev/null)
    version=$(echo "$full_version" | cut -d. -f1)

    # Validate that version is a number and check if it's >= 61 (FFmpeg 7.x)
    if [[ "$version" =~ ^[0-9]+$ ]] && [ "$version" -ge 61 ]; then
      log "FFmpeg 7 already installed (libavformat $full_version)."
      return
    fi
  fi
  log "Installing FFmpeg 7 development libraries (current libavformat: ${full_version:-not found})..."

  # Add FFmpeg 7 PPA
  sudo add-apt-repository -y ppa:ubuntuhandbook1/ffmpeg7
  sudo apt-get update

  # Remove old FFmpeg 4 dev packages if present
  sudo apt-get remove -y --allow-change-held-packages \
    libavcodec-dev libavformat-dev libavdevice-dev \
    libavutil-dev libavfilter-dev libswscale-dev libswresample-dev 2>/dev/null || true

  # Remove stale FFmpeg files from /usr/local (e.g., from GStreamer builds)
  sudo rm -f /usr/local/lib/x86_64-linux-gnu/pkgconfig/libav*.pc \
    /usr/local/lib/x86_64-linux-gnu/pkgconfig/libsw*.pc \
    /usr/local/lib/x86_64-linux-gnu/pkgconfig/libpostproc.pc \
    /usr/local/lib/pkgconfig/libav*.pc \
    /usr/local/lib/pkgconfig/libsw*.pc \
    /usr/local/lib/pkgconfig/libpostproc.pc 2>/dev/null || true
  sudo rm -rf /usr/local/include/libav* \
    /usr/local/include/libsw* \
    /usr/local/include/libpostproc 2>/dev/null || true

  # Install FFmpeg 7 from PPA
  sudo apt-get install -y ffmpeg \
    libavcodec-dev libavformat-dev libavdevice-dev \
    libavutil-dev libavfilter-dev libswscale-dev libswresample-dev

  # Verify installation
  full_version=$(pkg-config --modversion libavformat 2>/dev/null)
  version=$(echo "$full_version" | cut -d. -f1)
  if ! [[ "$version" =~ ^[0-9]+$ ]] || [ "$version" -lt 61 ]; then
    error "FFmpeg 7 installation failed. libavformat version: ${full_version:-not found} (expected >= 61)"
    exit 1
  fi
  log "FFmpeg 7 installation complete (libavformat $full_version)."
}

install_gstreamer() {

  local version="1.24"
  local rs_version="0.13"
  local cargo_c_version="0.10.13+cargo-0.88.0"
  local rustup_toolchain="1.85.0"

  log "Installing Gstreamer..."
  source "$HOME/.cargo/env"
  source "$VENV_DIR/bin/activate"
  if ! command -v gst-inspect-1.0  >/dev/null 2>&1; then
    log "Gstreamer is not installed."
  else
    log "Gstreamer is already installed."
    return
  fi

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$RS_INSTALL_DIR"

  pushd "$SCRIPT_DIR/gstreamer"
  git checkout $version
  if [ ! -d "builddir" ]; then
    "$VENV_DIR/bin/meson" setup builddir --prefix=/usr/local
    "$VENV_DIR/bin/meson" compile -C builddir
  fi
  yes | sudo "$VENV_DIR/bin/meson" install -C builddir || true
  sudo ldconfig
  log "Gstreamer installed to /usr/local"

  log "Copying Gstreamer files to $INSTALL_DIR..."
  sudo cp -r /usr/local/* "$INSTALL_DIR/"
  sudo chown -R $(whoami) "$INSTALL_DIR"
  log "Gstreamer files copied to $INSTALL_DIR"

  log "Installing Gstreamer rust plugins..."
  pushd "$SCRIPT_DIR/gst-plugins-rs"
  git checkout $rs_version
  cargo install cargo-c --version $cargo_c_version --locked

  cargo cbuild --release -j$THREADS
  sudo env PATH="$HOME/.cargo/bin:$PATH" RUSTUP_TOOLCHAIN=$rustup_toolchain cargo cinstall --release --prefix=/usr/local -j$THREADS
  sudo ldconfig
  log "Gstreamer rust plugins installed to /usr/local"

  log "Copying Rust plugin files to $RS_INSTALL_DIR..."
  sudo cp -r /usr/local/* "$RS_INSTALL_DIR/"
  sudo chown -R $(whoami) "$RS_INSTALL_DIR"
  log "Rust plugin files copied to $RS_INSTALL_DIR"
  popd && popd

  log "Creating tarballs..."
  tar czf "$SCRIPT_DIR/gstreamer-$version-$PLATFORM-core.tar.gz" -C "$INSTALL_DIR" .
  tar czf "$SCRIPT_DIR/gst-plugins-rs-$rs_version-$PLATFORM.tar.gz" -C "$RS_INSTALL_DIR" .
  log "Tarballs created:"
  ls -lh "$SCRIPT_DIR/gstreamer-$version-$PLATFORM-core.tar.gz" "$SCRIPT_DIR/gst-plugins-rs-$rs_version-$PLATFORM.tar.gz"
}
detect_platform
install_system_packages
install_dependencies
install_ffmpeg7
install_gstreamer
