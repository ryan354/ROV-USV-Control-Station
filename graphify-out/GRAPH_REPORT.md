# Graph Report - .  (2026-04-12)

## Corpus Check
- 26 files · ~15,000 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 185 nodes · 244 edges · 18 communities detected
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 11 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Vehicle Settings|Vehicle Settings]]
- [[_COMMUNITY_Joystick Input|Joystick Input]]
- [[_COMMUNITY_Build & Architecture|Build & Architecture]]
- [[_COMMUNITY_Vehicle Telemetry|Vehicle Telemetry]]
- [[_COMMUNITY_Joystick Manager|Joystick Manager]]
- [[_COMMUNITY_Video Receiver|Video Receiver]]
- [[_COMMUNITY_MAVLink Comms|MAVLink Comms]]
- [[_COMMUNITY_Vehicle Manager|Vehicle Manager]]
- [[_COMMUNITY_Video Manager|Video Manager]]
- [[_COMMUNITY_Map Frontend|Map Frontend]]
- [[_COMMUNITY_Map Bridge|Map Bridge]]
- [[_COMMUNITY_Video Surface|Video Surface]]
- [[_COMMUNITY_Application Core|Application Core]]
- [[_COMMUNITY_Entry Point|Entry Point]]
- [[_COMMUNITY_Build Targets|Build Targets]]
- [[_COMMUNITY_SITL Rationale|SITL Rationale]]
- [[_COMMUNITY_Settings Build|Settings Build]]
- [[_COMMUNITY_VideoSurface Build|VideoSurface Build]]

## God Nodes (most connected - your core abstractions)
1. `handleMessage()` - 11 edges
2. `RovoControl Project` - 7 edges
3. `getMappedAxis()` - 6 edges
4. `stop()` - 6 edges
5. `toManualControl()` - 5 edges
6. `setActiveVehicle()` - 5 edges
7. `createPipeline()` - 5 edges
8. `Architecture Overview` - 5 edges
9. `updateVehicle()` - 4 edges
10. `sanitizeName()` - 4 edges

## Surprising Connections (you probably didn't know these)
- `MapBridge` --references--> `Qt6 WebEngine (Optional)`  [INFERRED]
  src/map/MapBridge.cpp → CMakeLists.txt
- `VideoReceiver` --references--> `GStreamer Video Pipeline`  [INFERRED]
  src/video/VideoReceiver.cpp → CMakeLists.txt
- `JoystickManager` --references--> `SDL2 Joystick Support`  [INFERRED]
  src/input/JoystickManager.cpp → CMakeLists.txt
- `MavlinkManager` --references--> `MAVLink Header-Only Library`  [INFERRED]
  src/mavlink/MavlinkManager.cpp → CMakeLists.txt
- `Vehicle` --implements--> `ROV (ArduSub)`  [INFERRED]
  src/mavlink/Vehicle.cpp → README.md

## Hyperedges (group relationships)
- **MAVLink Communication Subsystem** — cmakelists_mavlinkmanager, cmakelists_vehicle, cmakelists_vehiclemanager, cmakelists_mavlink [EXTRACTED 0.90]
- **Video Streaming Subsystem** — cmakelists_videomanager, cmakelists_videoreceiver, cmakelists_videosurface, cmakelists_gstreamer [EXTRACTED 0.90]
- **Joystick Input Subsystem** — cmakelists_joystickmanager, cmakelists_joystick, cmakelists_sdl2 [EXTRACTED 0.90]
- **Core Application Subsystem** — cmakelists_main, cmakelists_application, cmakelists_settings [INFERRED 0.85]
- **Dual Vehicle (ROV + USV) System** — readme_rov, readme_usv, cmakelists_vehiclemanager, cmakelists_mavlinkmanager [EXTRACTED 0.90]

## Communities

### Community 0 - "Vehicle Settings"
Cohesion: 0.12
Nodes (21): loadJoystickConfig(), rovCamera1(), rovCamera2(), rovPort(), rovSysId(), sanitizeName(), saveJoystickConfig(), saveJoystickRouting() (+13 more)

### Community 1 - "Joystick Input"
Cohesion: 0.12
Nodes (12): applyDeadzoneAndExpo(), axisR(), axisX(), axisY(), axisZ(), getMappedAxis(), Joystick(), manualControlR() (+4 more)

### Community 2 - "Build & Architecture"
Cohesion: 0.11
Nodes (23): GStreamer Video Pipeline, Joystick, JoystickManager, MapBridge, MAVLink Header-Only Library, MavlinkManager, QML UI Module, Qt 6 Framework (+15 more)

### Community 3 - "Vehicle Telemetry"
Cohesion: 0.15
Nodes (17): arm(), disarm(), handleMessage(), processAttitude(), processBatteryStatus(), processCommandAck(), processGlobalPositionInt(), processGpsRawInt() (+9 more)

### Community 4 - "Joystick Manager"
Cohesion: 0.17
Nodes (6): dispatchAction(), enumerate(), JoystickManager(), poll(), start(), stop()

### Community 5 - "Video Receiver"
Cohesion: 0.33
Nodes (8): createPipeline(), destroyPipeline(), setPlaying(), setStatus(), setUri(), start(), stop(), VideoReceiver()

### Community 6 - "MAVLink Comms"
Cohesion: 0.25
Nodes (6): MavlinkManager(), sendHeartbeat(), sendMessage(), sendToVehicle(), start(), stop()

### Community 7 - "Vehicle Manager"
Cohesion: 0.31
Nodes (9): handleMavlinkMessage(), rovVehicle(), selectROV(), selectUSV(), selectVehicle(), setActiveVehicle(), usvVehicle(), vehicleBySysId() (+1 more)

### Community 8 - "Video Manager"
Cohesion: 0.33
Nodes (6): receiver(), setStreamUri(), startStream(), stopAll(), stopStream(), VideoManager()

### Community 9 - "Map Frontend"
Cohesion: 0.39
Nodes (4): connectBridge(), createVehicleMarker(), createVehicleSvg(), updateVehicle()

### Community 10 - "Map Bridge"
Cohesion: 0.25
Nodes (1): MapBridge()

### Community 11 - "Video Surface"
Cohesion: 0.4
Nodes (1): VideoSurface()

### Community 12 - "Application Core"
Cohesion: 0.67
Nodes (1): Application()

### Community 13 - "Entry Point"
Cohesion: 1.0
Nodes (0): 

### Community 14 - "Build Targets"
Cohesion: 1.0
Nodes (2): Application (core), Main Entry Point

### Community 15 - "SITL Rationale"
Cohesion: 1.0
Nodes (2): Rationale: Direct SITL Without MAVProxy, SITL Testing Setup

### Community 16 - "Settings Build"
Cohesion: 1.0
Nodes (1): Settings (core)

### Community 17 - "VideoSurface Build"
Cohesion: 1.0
Nodes (1): VideoSurface

## Knowledge Gaps
- **12 isolated node(s):** `Qt 6 Framework`, `Application (core)`, `Settings (core)`, `VideoSurface`, `Joystick` (+7 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Entry Point`** (2 nodes): `main()`, `main.cpp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Build Targets`** (2 nodes): `Application (core)`, `Main Entry Point`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `SITL Rationale`** (2 nodes): `Rationale: Direct SITL Without MAVProxy`, `SITL Testing Setup`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Settings Build`** (1 nodes): `Settings (core)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `VideoSurface Build`** (1 nodes): `VideoSurface`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `Qt 6 Framework`, `Application (core)`, `Settings (core)` to the rest of the system?**
  _12 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Vehicle Settings` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `Joystick Input` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `Build & Architecture` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._