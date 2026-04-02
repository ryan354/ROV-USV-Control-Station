# RovoControl — ROV & USV Ground Control Station

A dual-vehicle ground control station for simultaneous control of underwater drones (ROV/ArduSub) and surface drones (USV/ArduBoat). Built with Qt 6 / C++ / QML.

![Qt](https://img.shields.io/badge/Qt-6.8-green?logo=qt) ![C++](https://img.shields.io/badge/C++-17-blue?logo=cplusplus) ![MAVLink](https://img.shields.io/badge/MAVLink-v2-orange) ![License](https://img.shields.io/badge/License-MIT-yellow)

## Features

- **Dual Vehicle Control** — Simultaneous ROV + USV with independent MAVLink connections
- **Multi-Camera View** — 2x2 video grid (2 cameras per vehicle), RTSP / H.264 streams via GStreamer
- **Live Map** — Google Satellite/Hybrid/Streets + Esri + CartoDB Dark tiles with vehicle markers and track history
- **Real-Time Telemetry** — Depth, heading, speed, battery, GPS, attitude (roll/pitch/yaw)
- **Joystick Support** — Multiple gamepads with per-joystick vehicle routing, axis mapping, button binding
- **Dark Theme UI** — Navy/coral/cyan theme, SplitView resizable panels
- **Configurable** — Per-vehicle settings (sysid, UDP port, camera URIs), all persisted via QSettings

## Screenshots

```
+------------------------------------------------------------------+
| RovoControl   [ROV] [USV]         ARM DISARM  Mode:[MANUAL]  [S] |
+-------------------------------+----------------------------------+
|  ROV Cam 1    |  ROV Cam 2    |           MAP                    |
|  (HUD overlay)|               |   Google Satellite + vehicles    |
|---------------+---------------|   ROV marker (cyan)              |
|  USV Cam 1    |  USV Cam 2    |   USV marker (orange)            |
|               |               |   Track polylines                |
+-------------------------------+----------------------------------+
| ROV-1 | MANUAL | DEPTH 12.3m | HDG 045 | SPD 1.2 | BAT 14.8V   |
+------------------------------------------------------------------+
| ROV Connected | USV Connected | MAVLink: 42 msg/s | Ports: 14550 |
+------------------------------------------------------------------+
```

## Requirements

| Dependency | Version | Purpose |
|---|---|---|
| **Qt** | 6.6+ | UI framework (Core, Quick, WebEngine, Multimedia) |
| **CMake** | 3.21+ | Build system |
| **Visual Studio** | 2022 | MSVC compiler |
| **GStreamer** | 1.22+ | Video streaming (RTSP, H.264) |
| **SDL2** | 2.28+ | Joystick/gamepad input |
| **MAVLink** | v2 | Vehicle communication (headers included) |

## Quick Setup (Windows)

```bash
git clone https://github.com/ryan354/ROV-USV-Control-Station.git
cd ROV-USV-Control-Station
./setup.sh
```

Or follow the manual steps below.

## Manual Setup

### 1. Install Visual Studio 2022

Download from https://visualstudio.microsoft.com/ — select **"Desktop development with C++"** workload.

### 2. Install CMake

Download from https://cmake.org/download/ — add to PATH during install.

### 3. Install Qt 6.8

```bash
pip install aqtinstall
aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 --outputdir C:/Qt
aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 --outputdir C:/Qt --modules qtwebchannel qtwebengine qtmultimedia qtshadertools qtpositioning qtserialport
```

### 4. Install GStreamer

Download the **MSVC 64-bit** installer from https://gstreamer.freedesktop.org/download/

Install both **Runtime** and **Development** packages. Default path: `C:\gstreamer\1.0\msvc_x86_64\`

### 5. Install SDL2

```bash
curl -L -o SDL2-devel.zip https://github.com/libsdl-org/SDL/releases/download/release-2.30.11/SDL2-devel-2.30.11-VC.zip
# Extract to C:\SDL2\
```

### 6. Generate MAVLink Headers (already included)

Headers are pre-generated in `third_party/mavlink/`. To regenerate:

```bash
pip install pymavlink
git clone --recursive https://github.com/mavlink/mavlink.git mavlink-src
python -c "
from pymavlink.generator import mavgen
from pymavlink.generator.mavgen import Opts
opts = Opts('mavlink-src/message_definitions/v1.0/ardupilotmega.xml')
opts.output = 'third_party/mavlink'
opts.language = 'C'
opts.wire_protocol = '2.0'
mavgen.mavgen(opts, ['mavlink-src/message_definitions/v1.0/ardupilotmega.xml'])
"
```

### 7. Build

```bash
cmake -B build -G "Visual Studio 17 2022" -DCMAKE_PREFIX_PATH="C:/Qt/6.8.3/msvc2022_64"
cmake --build build --config Release
```

### 8. Deploy DLLs

```bash
# Qt DLLs
C:/Qt/6.8.3/msvc2022_64/bin/windeployqt6.exe build/Release/RovoControl.exe --qmldir qml

# Or use the deploy script
./deploy.bat
```

### 9. Run

```bash
build/Release/RovoControl.exe
```

## VS Code Setup

The project includes `.vscode/` configuration for development:

1. Install extensions: **C/C++**, **CMake Tools**
2. Open folder in VS Code
3. CMake Tools will auto-configure (select kit: **MSVC 2022 x64 + Qt 6.8.3**)
4. `Ctrl+Shift+B` to build
5. `F5` to debug

## Configuration

Open Settings (gear icon in toolbar):

### ROV Settings
| Setting | Default | Description |
|---|---|---|
| Vehicle ID | 1 | MAVLink system ID |
| UDP Port | 14550 | MAVLink listening port |
| Camera 1 | rtsp://192.168.2.2:8554/video0 | Main camera RTSP stream |
| Camera 2 | rtsp://192.168.2.2:8554/video1 | Secondary camera |

### USV Settings
| Setting | Default | Description |
|---|---|---|
| Vehicle ID | 2 | MAVLink system ID |
| UDP Port | 14551 | MAVLink listening port |
| Camera 1 | rtsp://192.168.3.2:8554/video0 | Main camera RTSP stream |
| Camera 2 | rtsp://192.168.3.2:8554/video1 | Secondary camera |

### Joystick
- Assign each gamepad to ROV or USV
- Map physical axes to X/Y/Z/R with inversion
- Bind buttons to actions (Arm, Disarm, mode changes, lights, camera)
- Configure deadzone and expo curves

## Architecture

```
QML UI (main.qml + SplitView panels)
  |  Q_PROPERTY bindings
C++ Backend
  +-- VehicleManager --> Vehicle(ROV), Vehicle(USV)
  +-- MavlinkManager (dual UDP sockets: 14550 + 14551)
  +-- VideoManager --> VideoReceiver x4 (GStreamer appsink)
  +-- JoystickManager --> Joystick x2 (SDL2, 50Hz poll, 25Hz send)
  +-- MapBridge --> Leaflet (QWebEngine, runJavaScript)
```

## Project Structure

```
src/
  main.cpp                  # Entry point
  core/Settings.h|.cpp      # QSettings persistence
  mavlink/
    MavlinkManager.h|.cpp   # Dual UDP socket, MAVLink parser
    Vehicle.h|.cpp           # Per-vehicle state (ArduSub/ArduBoat)
    VehicleManager.h|.cpp    # Multi-vehicle orchestration
  video/
    VideoReceiver.h|.cpp     # GStreamer RTSP pipeline
    VideoManager.h|.cpp      # 4-stream manager
  input/
    JoystickManager.h|.cpp   # SDL2 polling, vehicle routing
    Joystick.h|.cpp          # Axis mapping, button actions
  map/MapBridge.h|.cpp       # C++ <-> Leaflet JS bridge
qml/
  main.qml                  # Root layout + settings popup
  Theme.qml                 # Dark theme colors
resources/
  map/index.html|map.js     # Leaflet map with Google tiles
third_party/mavlink/        # Pre-generated MAVLink v2 headers
```

## Testing with SITL (ArduPilot Software-In-The-Loop)

### Prerequisites — Cygwin Setup (one-time)

1. Download the Cygwin installer from https://www.cygwin.com/install.html (`setup-x86_64.exe`)
2. Run the installer and select these packages:
   - `gcc-g++`, `make`, `cmake`, `git`, `procps-ng`
   - `python37`, `python37-pip`, `python37-devel`
   - `libxml2-devel`, `libxslt-devel`
3. Open **Cygwin Terminal** and install Python dependencies:
   ```bash
   pip3.7 install pymavlink pexpect future lxml empy==3.3.4
   ```
4. Clone and build ArduPilot:
   ```bash
   cd ~
   git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
   cd ardupilot
   git submodule update --init --recursive

   # Configure for SITL
   python3.7 modules/waf/waf-light configure --board sitl

   # Build ArduSub (ROV)
   python3.7 modules/waf/waf-light build --target bin/ardusub -j6

   # Build ArduRover (USV / motorboat)
   python3.7 modules/waf/waf-light build --target bin/ardurover -j6
   ```

### Running SITL

Open **two Cygwin terminals** and run:

**Terminal 1 — ArduSub (ROV, SYSID 1, port 14550):**
```bash
cd ~/ardupilot
./build/sitl/bin/ardusub -S --model vectored --speedup 1 --sysid 1 -I0 \
  --home 33.810313,-118.393867,0.0,270.0 \
  --defaults Tools/autotest/default_params/sub.parm \
  --serial0=udpclient:127.0.0.1:14550
```

**Terminal 2 — ArduBoat (USV, SYSID 2, port 14551):**
```bash
cd ~/ardupilot
./build/sitl/bin/ardurover -S --model motorboat --speedup 1 --sysid 2 -I1 \
  --home 33.810313,-118.393867,0.0,270.0 \
  --defaults Tools/autotest/default_params/rover.parm,Tools/autotest/default_params/motorboat.parm \
  --serial0=udpclient:127.0.0.1:14551
```

Press **Ctrl+C** in each terminal to stop.

### SITL Flag Reference

| Flag | Purpose |
|------|---------|
| `--sysid N` | MAVLink system ID (must be unique per vehicle) |
| `-I N` | Instance number (offsets ports by N*10 to avoid conflicts) |
| `--serial0=udpclient:IP:PORT` | Sends MAVLink over UDP directly to RovoControl |
| `--model vectored` | BlueROV2-style 6-DOF thruster layout |
| `--model motorboat` | Surface vessel physics |
| `-S` | Synthetic clock (keeps simulation in sync) |
| `--speedup N` | Simulation speed multiplier |
| `-L RATBeach` | Named location shortcut (same as `--home 33.81...`) |

> **Note:** These commands run the SITL binaries directly instead of using `sim_vehicle.py`, because `sim_vehicle.py` requires MAVProxy which depends on numpy (very slow to build on Cygwin). The `--serial0=udpclient:...` flag sends MAVLink straight to RovoControl without MAVProxy.

## License

MIT License
