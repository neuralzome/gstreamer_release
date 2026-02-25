# GStreamer Release Test Plan

Test that pre-built `.so` tarballs work on a clean container using `neuralpilot-base` image.

## 1. Create both containers

```bash
docker run \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev:/dev \
  --volume="$HOME/test:/home/neuralpilot/test:rw" \
  --volume="$HOME/.Xauthority:/home/neuralpilot/.Xauthority:rw" \
  -e DISPLAY=$DISPLAY \
  --network host \
  --privileged \
  --name gstreamer_source \
  -itd \
  neuralpilot-base

docker run \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev:/dev \
  --volume="$HOME/.Xauthority:/home/neuralpilot/.Xauthority:rw" \
  -e DISPLAY=$DISPLAY \
  --network host \
  --privileged \
  --name gstreamer_test \
  -itd \
  neuralpilot-base
```

## 2. Clone repo into source container and build

```bash
docker exec -it gstreamer_source bash
```

```bash
git clone --recurse-submodules https://github.com/<your-org>/Gstreamer_release.git /reamtmp/Gstreamer_release
cd /tmp/Gstreamer_release
chmod +x install_gstreamer.sh
./install_gstreamer.sh
```

The script will:
- Install build dependencies
- Build GStreamer 1.24 from the `gstreamer` submodule into `gstreamer-install/`
- Build Rust plugins 0.13 from the `gst-plugins-rs` submodule into `gst-plugins-rs-install/`
- Create `gstreamer-1.24-core.tar.gz` and `gst-plugins-rs-0.13.tar.gz` automatically

```bash
ls -lh /tmp/Gstreamer_release/*.tar.gz
exit
```

## 3. Copy tarballs to test container

```bash
docker cp gstreamer_source:~/test/gstreamer_release/gstreamer-1.24-core.tar.gz /tmp/
docker cp gstreamer_source:~/test/gstreamer_release/gst-plugins-rs-0.13.tar.gz /tmp/

docker cp /tmp/gstreamer-1.24-core.tar.gz gstreamer_test:/tmp/
docker cp /tmp/gst-plugins-rs-0.13.tar.gz gstreamer_test:/tmp/
```

## 4. In gstreamer_test - install runtime deps and extract

```bash
docker exec -it gstreamer_test bash
```

```bash
# Install runtime dependencies
sudo apt-get update && sudo apt-get install -y libglib2.0-0 liborc-0.4-0

# Extract to /usr/local
cd /usr/local
sudo tar xzf /tmp/gstreamer-1.24-core.tar.gz
sudo tar xzf /tmp/gst-plugins-rs-0.13.tar.gz
sudo ldconfig
```

## 5. Verify

```bash
# Check gst-launch runs
gst-launch-1.0 --version

# List rust plugins
gst-inspect-1.0 | grep -i rs

# KEY TEST - januswebrtcsink
gst-inspect-1.0 rswebrtc
gst-inspect-1.0 janusvrwebrtcsink
```

**Success criteria:** `gst-inspect-1.0 janusvrwebrtcsink` shows element details without errors.

## 6. Cleanup

```bash
exit
docker stop gstreamer_source gstreamer_test
docker rm gstreamer_source gstreamer_test
```
