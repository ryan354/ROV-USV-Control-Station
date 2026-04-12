---
type: community
cohesion: 0.33
members: 12
---

# Video Receiver

**Cohesion:** 0.33 - loosely connected
**Members:** 12 nodes

## Members
- [[VideoReceiver()]] - code - src\video\VideoReceiver.h
- [[VideoReceiver.cpp]] - code - src\video\VideoReceiver.cpp
- [[VideoReceiver.h]] - code - src\video\VideoReceiver.h
- [[createPipeline()]] - code - src\video\VideoReceiver.cpp
- [[destroyPipeline()]] - code - src\video\VideoReceiver.cpp
- [[onNewSample()]] - code - src\video\VideoReceiver.cpp
- [[setPlaying()]] - code - src\video\VideoReceiver.cpp
- [[setStatus()]] - code - src\video\VideoReceiver.cpp
- [[setUri()]] - code - src\video\VideoReceiver.cpp
- [[setVideoSink()]] - code - src\video\VideoReceiver.cpp
- [[start()_2]] - code - src\video\VideoReceiver.cpp
- [[stop()_2]] - code - src\video\VideoReceiver.cpp

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Video_Receiver
SORT file.name ASC
```
