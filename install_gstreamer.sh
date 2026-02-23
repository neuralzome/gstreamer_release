#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS=$(nproc --all)
THREADS=$((THREADS > 1 ? THREADS - 1 : 1))
VENV_DIR="/tmp/gst-build-venv"
INSTALL_DIR="$SCRIPT_DIR/gstreamer-install"
RS_INSTALL_DIR="$SCRIPT_DIR/gst-plugins-rs-install"

export PATH="$HOME/.cargo/bin:$PATH"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

install_dependencies() {
  log "Installing build dependencies..."
  sudo apt-get update
  sudo apt-get install -y \
    python3 python3-pip python3-venv \
    git curl build-essential pkg-config flex bison \
    libglib2.0-dev libssl-dev libx264-dev libvpx-dev \
    libopus-dev libsrtp2-dev nasm cmake ninja-build \
    ca-certificates wget

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

install_gstreamer() {
  log "Installing Gstreamer..."
  if ! command -v gst-inspect-1.0  >/dev/null 2>&1; then
    log "Gstreamer is not installed."
  else
    log "Gstreamer is already installed."
    return
  fi

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$RS_INSTALL_DIR"

  pushd "$SCRIPT_DIR/gstreamer"
  git checkout 1.24
  if [ ! -d "builddir" ]; then
    meson setup builddir --prefix="$INSTALL_DIR"
    meson compile -C builddir
  fi
  yes | meson install -C builddir
  log "Gstreamer installed to $INSTALL_DIR"

  log "Installing Gstreamer rust plugins..."
  pushd "$SCRIPT_DIR/gst-plugins-rs"
  git checkout 0.13
  cargo install cargo-c --version 0.10.13+cargo-0.88.0 --locked

  export PKG_CONFIG_PATH="$INSTALL_DIR/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"
  export LD_LIBRARY_PATH="$INSTALL_DIR/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"

  cargo cbuild -j$THREADS
  env PATH="$HOME/.cargo/bin:$PATH" RUSTUP_TOOLCHAIN=1.85.0 cargo cinstall --prefix="$RS_INSTALL_DIR" -j$THREADS
  popd && popd
  log "Gstreamer rust plugins installed to $RS_INSTALL_DIR"

  log "Creating tarballs..."
  tar czf "$SCRIPT_DIR/gstreamer-1.24-core.tar.gz" -C "$INSTALL_DIR" .
  tar czf "$SCRIPT_DIR/gst-plugins-rs-0.13.tar.gz" -C "$RS_INSTALL_DIR" .
  log "Tarballs created:"
  ls -lh "$SCRIPT_DIR/gstreamer-1.24-core.tar.gz" "$SCRIPT_DIR/gst-plugins-rs-0.13.tar.gz"
}

install_dependencies
install_gstreamer
