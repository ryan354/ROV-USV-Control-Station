---
type: community
cohesion: 0.15
members: 22
---

# Vehicle Telemetry

**Cohesion:** 0.15 - loosely connected
**Members:** 22 nodes

## Members
- [[Vehicle()]] - code - src\mavlink\Vehicle.h
- [[Vehicle.cpp]] - code - src\mavlink\Vehicle.cpp
- [[Vehicle.h]] - code - src\mavlink\Vehicle.h
- [[arm()]] - code - src\mavlink\Vehicle.cpp
- [[checkHeartbeat()]] - code - src\mavlink\Vehicle.cpp
- [[disarm()]] - code - src\mavlink\Vehicle.cpp
- [[handleMessage()]] - code - src\mavlink\Vehicle.cpp
- [[processAttitude()]] - code - src\mavlink\Vehicle.cpp
- [[processBatteryStatus()]] - code - src\mavlink\Vehicle.cpp
- [[processCommandAck()]] - code - src\mavlink\Vehicle.cpp
- [[processGlobalPositionInt()]] - code - src\mavlink\Vehicle.cpp
- [[processGpsRawInt()]] - code - src\mavlink\Vehicle.cpp
- [[processHeartbeat()]] - code - src\mavlink\Vehicle.cpp
- [[processRcChannels()]] - code - src\mavlink\Vehicle.cpp
- [[processScaledPressure()]] - code - src\mavlink\Vehicle.cpp
- [[processSysStatus()]] - code - src\mavlink\Vehicle.cpp
- [[processVfrHud()]] - code - src\mavlink\Vehicle.cpp
- [[requestDataStreams()]] - code - src\mavlink\Vehicle.cpp
- [[resolveFlightMode()]] - code - src\mavlink\Vehicle.cpp
- [[sendCommandLong()]] - code - src\mavlink\Vehicle.cpp
- [[sendManualControl()]] - code - src\mavlink\Vehicle.cpp
- [[setMode()]] - code - src\mavlink\Vehicle.cpp

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Vehicle_Telemetry
SORT file.name ASC
```
