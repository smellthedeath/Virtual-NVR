# Production-Grade NVR & AI Surveillance Stack (Frigate + go2rtc)

A high-performance, containerized Network Video Recorder (NVR) architecture powered by [Frigate](https://frigate.video/) and [go2rtc](https://github.com/AlexxIT/go2rtc), featuring:
- **Low-CPU Multi-stream Architecture**: Splitting 3K/4K high-res video for 24/7 direct recording and low-res substreams (D1/VGA) for AI/motion detection.
- **Automated Storage Management**: Intelligent auto-pruning guard script ensuring disk utilization remains safely below threshold (e.g. 90%).
- **Hardware Acceleration Support**: Built-in support for Intel VA-API, QuickSync, and NVIDIA hardware transcoding.
- **Secure by Design**: Credentials and network IPs decoupled via environment variables.

---

## 📁 Repository Structure

```tree
├── docker-compose.yml          # Container stack definition
├── .env.example                # Template for environment variables and secrets
├── .gitignore                  # Prevents secrets, databases, and media from leaking
├── config/
│   └── config.example.yml      # Sanitized Frigate configuration template
└── scripts/
    ├── frigate-storage-guard.sh   # Bash automated disk monitoring & purge script
    └── frigate-storage-guard.cron # Cron definition (checks every 30 mins)
```

---

## 🚀 Quick Start

### 1. Prerequisites
- Docker Engine (24.0+) & Docker Compose Plugin
- Storage drive/partition dedicated to recordings (e.g., `/data/nvr`)

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Edit `.env` and fill in your camera credentials, IP addresses, RTSP secrets, and storage paths.

### 3. Setup Configuration
Copy the configuration template:
```bash
cp config/config.example.yml config/config.yml
```
Adjust camera stream paths and detection parameters in `config/config.yml` according to your camera models.

### 4. Setup Automated Storage Guard
To prevent your storage drive from filling to 100%:
```bash
sudo cp scripts/frigate-storage-guard.sh /usr/local/bin/frigate-storage-guard.sh
sudo chmod +x /usr/local/bin/frigate-storage-guard.sh
sudo cp scripts/frigate-storage-guard.cron /etc/cron.d/frigate-storage-guard
sudo chmod 644 /etc/cron.d/frigate-storage-guard
```

### 5. Launch the Stack
```bash
docker compose up -d
```
Access the web dashboard at: `http://<your-server-ip>:8971` (or port `5000` for unauthenticated internal access).

---

## ⚡ Performance Optimization Tip (Dual-Stream Setup)

Decoding 3K or 4K streams with software FFmpeg can cause **100%+ CPU usage per camera**. 
This configuration splits stream duties inside `go2rtc`:
1. **Mainstream (`preset-rtsp-restream`)**: Passed directly to disk for `record` without decoding (near 0% CPU).
2. **Substream (`704x576 @ 5 FPS`)**: Decoded for `detect` and object analysis, dropping CPU usage down to ~3-4% per camera.

---

## 🔒 Security
- Always keep `.env` out of version control.
- Ensure RTSP ports (`554`, `8554`) are not exposed directly to the public internet without VPN or firewall protection.
