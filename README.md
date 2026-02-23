# Gstreamer Release

Pre-built GStreamer 1.24 and GStreamer Rust plugins (0.13) `.so` files for Ubuntu.

## Using pre-built `.so` files

1. Download the `.so` files from the [Releases](../../releases) page
2. Copy them to `/usr/local/lib/` (or your preferred library path)
3. Run `sudo ldconfig`

## Building from source

If you prefer to build from source instead of using the pre-built binaries:

```bash
chmod +x install_gstreamer.sh
sudo ./install_gstreamer.sh
```

This will clone, build, and install:
- GStreamer 1.24 from `https://gitlab.freedesktop.org/gstreamer/gstreamer.git`
- GStreamer Rust plugins 0.13 from `https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs`

### Prerequisites

- `meson` and `ninja` build system
- Rust toolchain (rustup, rustc 1.85.0, cargo-c 0.10.13)
- Standard build tools (`gcc`, `pkg-config`, etc.)