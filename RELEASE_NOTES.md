## v1.24.0 — GStreamer 1.24 + Rust Plugins 0.13

Pre-built binaries and shared libraries for Ubuntu 22.04 (x86_64).

### Assets

| File | Description |
|---|---|
| `gstreamer-1.24-core.tar.gz` | GStreamer 1.24 — binaries, core shared libs, C plugins, and Rust plugins |
| `gst-plugins-rs-0.13.tar.gz` | GStreamer Rust plugins 0.13 — static libs and headers |

### Install

```bash
sudo apt-get install -y libglib2.0-0 liborc-0.4-0
sudo tar xzf gstreamer-1.24-core.tar.gz -C /usr/local
sudo tar xzf gst-plugins-rs-0.13.tar.gz -C /usr/local
sudo ldconfig
```

### Verify

```bash
gst-launch-1.0 --version
gst-inspect-1.0 janusvrwebrtcsink
```

### Included Rust plugins (gst-plugins-rs 0.13)

- `libgstrswebrtc.so` — WebRTC (janusvrwebrtcsink, whip, whep)
- `libgstrsrtp.so` — RTP
- `libgstrsrtsp.so` — RTSP
- `libgstrsonvif.so` — ONVIF
- `libgstrsaudiofx.so` — Audio effects
- `libgstrspng.so` — PNG
- `libgstrstracers.so` — Tracers
- `libgstrsinter.so` — Inter-pipeline communication

### Additional notable plugins included in core

- `libgstwebrtc.so` — WebRTC (C)
- `libgstnice.so` — ICE/STUN/TURN
- `libgstsrtp.so` — SRTP
- `libgstdtls.so` — DTLS
- `libgstlibav.so` — FFmpeg/libav decoders & encoders
- `libgstvpx.so` — VP8/VP9
- `libgstopus.so` — Opus audio
- `libgstopenh264.so` — H.264
- `libgstvideo4linux2.so` — Video4Linux2
- 180+ more C plugins

### Runtime dependencies

- `libglib2.0-0`
- `liborc-0.4-0`

### Built from

- [GStreamer 1.24](https://gitlab.freedesktop.org/gstreamer/gstreamer/-/tree/1.24)
- [gst-plugins-rs 0.13](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs/-/tree/0.13)
