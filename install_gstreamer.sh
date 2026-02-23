#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THREADS=$(nproc --all)
THREADS=$((THREADS > 1 ? THREADS - 1 : 1))

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

install_gstreamer() {
  log "Installing Gstreamer..."
  if ! command -v gst-inspect-1.0  >/dev/null 2>&1; then
    log "Gstreamer is not installed."
  else
    log "Gstreamer is already installed."
    return
  fi
  pushd /opt
  if [ ! -d "/opt/gstreamer" ]; then
    git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git
  else
    log "Gstreamer repo found."
  fi
  pushd gstreamer
  git checkout 1.24
  if [ ! -d "builddir" ]; then
    meson setup builddir
    meson compile -C builddir
  fi
  sudo bash -c "yes | meson install -C builddir"
  sudo ldconfig
  log "Gstreamer installation complete."
  log "Installing Gstreamer rust plugins..."
  pushd subprojects
  if [ ! -d "/opt/gstreamer/subprojects/gst-plugins-rs" ]; then
    git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs
  else
    log "Gstreamer rust plugins repo found."
  fi
  pushd gst-plugins-rs
  git checkout 0.13
  cargo install cargo-c --version 0.10.13+cargo-0.88.0 --locked
  cargo cbuild -j$THREADS
  sudo env PATH="$HOME/.cargo/bin:$PATH" RUSTUP_TOOLCHAIN=1.85.0 cargo cinstall --prefix=/usr/local -j$THREADS
  popd && popd && popd && popd
  log "Gstreamer rust plugins installation complete."
}

install_gstreamer
