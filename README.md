# Gstreamer Release

Pre-built GStreamer 1.24 and GStreamer Rust plugins (0.13) `.so` files for Ubuntu.

## Using pre-built `.so` files

1. Download the `.tar` files from the [Releases](../../releases) page
2. Copy them to `/usr/local/` (or your preferred library path) and extract for `.so` files.
3. Run
```sh
sudo apt-get install -y libglib2.0-0 liborc-0.4-0
sudo tar xzf gstreamer-<version>-core.tar.gz -C /usr/local
sudo tar xzf gst-plugins-rs-<version>.tar.gz -C /usr/local
sudo ldconfig  
```

## Submodules

This repo includes the following as git submodules (mirrors of the original upstream repos):

- `gstreamer/` — mirror of [GStreamer](https://gitlab.freedesktop.org/gstreamer/gstreamer) (branch `1.24`)
- `gst-plugins-rs/` — mirror of [GStreamer Rust plugins](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs) (branch `0.13`)

## Building from source

If you prefer to build from source instead of using the pre-built binaries:

```bash
git clone --recurse-submodules https://github.com/neuralzome/Gstreamer_release.git
cd Gstreamer_release
chmod +x install_gstreamer.sh
./install_gstreamer.sh
```

The script handles all dependencies automatically (apt packages, meson via venv, rust toolchain).

### Prerequisites

- `meson` and `ninja` build system
- Rust toolchain (rustup, rustc 1.85.0, cargo-c 0.10.13)
- Standard build tools (`gcc`, `pkg-config`, etc.)
