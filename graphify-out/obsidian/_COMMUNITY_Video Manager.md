---
type: community
cohesion: 0.33
members: 9
---

# Video Manager

**Cohesion:** 0.33 - loosely connected
**Members:** 9 nodes

## Members
- [[VideoManager()]] - code - src\video\VideoManager.h
- [[VideoManager.cpp]] - code - src\video\VideoManager.cpp
- [[VideoManager.h]] - code - src\video\VideoManager.h
- [[receiver()]] - code - src\video\VideoManager.cpp
- [[setStreamUri()]] - code - src\video\VideoManager.cpp
- [[startAll()]] - code - src\video\VideoManager.cpp
- [[startStream()]] - code - src\video\VideoManager.cpp
- [[stopAll()]] - code - src\video\VideoManager.cpp
- [[stopStream()]] - code - src\video\VideoManager.cpp

## Live Query (requires Dataview plugin)

```dataview
TABLE source_file, type FROM #community/Video_Manager
SORT file.name ASC
```
