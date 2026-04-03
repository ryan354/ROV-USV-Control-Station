cmake_minimum_required(VERSION 3.21)
project(RovoControl VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Qt policies
if(POLICY CMP0071)
    cmake_policy(SET CMP0071 NEW)
endif()

# ─── Qt 6 ───────────────────────────────────────────────────────────────────
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    Multimedia
    Network
    Svg
)

# Optional: WebEngine for map (heavy dependency)
find_package(Qt6 COMPONENTS WebEngineQuick WebChannel QUIET)
if(Qt6WebEngineQuick_FOUND)
    message(STATUS "Qt6 WebEngine found - map will use Leaflet")
    add_compile_definitions(HAS_WEBENGINE)
else()
    message(STATUS "Qt6 WebEngine not found - map will use placeholder")
endif()

qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

# ─── GStreamer (optional for Phase 1) ────────────────────────────────────────
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

option(ENABLE_GSTREAMER "Enable GStreamer video pipeline" ON)
if(ENABLE_GSTREAMER)
    # Try to find GStreamer at known locations
    set(_GST_ROOT "C:/gstreamer/1.0/msvc_x86_64")
    if(DEFINED ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64})
        string(REGEX REPLACE "[/\\\\]+$" "" _GST_ROOT "$ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64}")
    elseif(EXISTS "C:/Program Files/gstreamer/1.0/msvc_x86_64/include/gstreamer-1.0/gst/gst.h")
        set(_GST_ROOT "C:/Program Files/gstreamer/1.0/msvc_x86_64")
    endif()

    if(EXISTS "${_GST_ROOT}/include/gstreamer-1.0/gst/gst.h")
        set(GSTREAMER_INCLUDE_DIRS
            "${_GST_ROOT}/include/gstreamer-1.0"
            "${_GST_ROOT}/include/glib-2.0"
            "${_GST_ROOT}/lib/glib-2.0/include"
        )
        set(GSTREAMER_LIBRARIES
            "${_GST_ROOT}/lib/gstreamer-1.0.lib"
            "${_GST_ROOT}/lib/gstapp-1.0.lib"
            "${_GST_ROOT}/lib/gstvideo-1.0.lib"
            "${_GST_ROOT}/lib/glib-2.0.lib"
            "${_GST_ROOT}/lib/gobject-2.0.lib"
        )
        set(GStreamer_FOUND TRUE)
        message(STATUS "GStreamer found at: ${_GST_ROOT}")
        add_compile_definitions(HAS_GSTREAMER)
    else()
        message(WARNING "GStreamer not found — video will use test pattern fallback")
        set(ENABLE_GSTREAMER OFF)
    endif()
endif()

# ─── SDL2 (joystick support) ────────────────────────────────────────────────
option(ENABLE_SDL2 "Enable SDL2 joystick support" ON)
if(ENABLE_SDL2)
    # Try cmake find first, then manual search
    find_package(SDL2 QUIET)
    if(NOT SDL2_FOUND)
        # Manual search at known locations
        set(_SDL2_SEARCH "C:/SDL2" "D:/SDL2" "$ENV{SDL2_DIR}")
        foreach(_path ${_SDL2_SEARCH})
            if(EXISTS "${_path}/include/SDL.h")
                set(SDL2_INCLUDE_DIRS "${_path}/include")
                set(SDL2_LIBRARIES "${_path}/lib/x64/SDL2.lib" "${_path}/lib/x64/SDL2main.lib")
                set(SDL2_DLL "${_path}/lib/x64/SDL2.dll")
                set(SDL2_FOUND TRUE)
                break()
            endif()
        endforeach()
    endif()

    if(SDL2_FOUND)
        message(STATUS "SDL2 found: ${SDL2_INCLUDE_DIRS}")
        add_compile_definitions(HAS_SDL2)
    else()
        message(WARNING "SDL2 not found — joystick input disabled. Install to C:/SDL2/")
        set(ENABLE_SDL2 OFF)
    endif()
endif()

# ─── MAVLink (header-only) ──────────────────────────────────────────────────
add_library(mavlink INTERFACE)
target_include_directories(mavlink INTERFACE
    "${CMAKE_SOURCE_DIR}/third_party/mavlink"
)

# ─── Sources ────────────────────────────────────────────────────────────────
set(SOURCES
    src/main.cpp
    src/core/Application.cpp
    src/core/Settings.cpp
    src/mavlink/MavlinkManager.cpp
    src/mavlink/Vehicle.cpp
    src/mavlink/VehicleManager.cpp
    src/video/VideoReceiver.cpp
    src/video/VideoManager.cpp
    src/video/VideoSurface.cpp
    src/input/JoystickManager.cpp
    src/input/Joystick.cpp
    src/map/MapBridge.cpp
)

set(HEADERS
    src/core/Application.h
    src/core/Settings.h
    src/mavlink/MavlinkManager.h
    src/mavlink/Vehicle.h
    src/mavlink/VehicleManager.h
    src/video/VideoReceiver.h
    src/video/VideoManager.h
    src/video/VideoSurface.h
    src/input/JoystickManager.h
    src/input/Joystick.h
    src/map/MapBridge.h
)

# ─── Resources ──────────────────────────────────────────────────────────────
qt_add_resources(RESOURCES resources/resources.qrc)

# ─── Executable ─────────────────────────────────────────────────────────────
qt_add_executable(RovoControl
    ${SOURCES}
    ${HEADERS}
    ${RESOURCES}
)

# ─── QML Module ─────────────────────────────────────────────────────────────

# Mark Theme.qml as singleton (must be before qt_add_qml_module)
set_source_files_properties(qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

# Set QT_RESOURCE_ALIAS so all QML files appear at module root (QTP0004 compliant)
set_source_files_properties(qml/main.qml                      PROPERTIES QT_RESOURCE_ALIAS "main.qml")
set_source_files_properties(qml/Theme.qml                     PROPERTIES QT_RESOURCE_ALIAS "Theme.qml")
set_source_files_properties(qml/components/VehicleSelector.qml PROPERTIES QT_RESOURCE_ALIAS "VehicleSelector.qml")
set_source_files_properties(qml/components/StatusBar.qml       PROPERTIES QT_RESOURCE_ALIAS "StatusBar.qml")
set_source_files_properties(qml/components/DockPanel.qml       PROPERTIES QT_RESOURCE_ALIAS "DockPanel.qml")
set_source_files_properties(qml/components/ConfirmDialog.qml   PROPERTIES QT_RESOURCE_ALIAS "ConfirmDialog.qml")
set_source_files_properties(qml/panels/VideoPanel.qml          PROPERTIES QT_RESOURCE_ALIAS "VideoPanel.qml")
set_source_files_properties(qml/panels/VideoGrid.qml           PROPERTIES QT_RESOURCE_ALIAS "VideoGrid.qml")
set_source_files_properties(qml/panels/TelemetryPanel.qml      PROPERTIES QT_RESOURCE_ALIAS "TelemetryPanel.qml")
set_source_files_properties(qml/panels/MapPanel.qml            PROPERTIES QT_RESOURCE_ALIAS "MapPanel.qml")
set_source_files_properties(qml/panels/ControlPanel.qml        PROPERTIES QT_RESOURCE_ALIAS "ControlPanel.qml")
set_source_files_properties(qml/panels/JoystickPanel.qml       PROPERTIES QT_RESOURCE_ALIAS "JoystickPanel.qml")
set_source_files_properties(qml/panels/AttitudeIndicator.qml   PROPERTIES QT_RESOURCE_ALIAS "AttitudeIndicator.qml")
set_source_files_properties(qml/panels/CameraWindow.qml       PROPERTIES QT_RESOURCE_ALIAS "CameraWindow.qml")
set_source_files_properties(qml/overlays/HudOverlay.qml        PROPERTIES QT_RESOURCE_ALIAS "HudOverlay.qml")
set_source_files_properties(qml/overlays/CompassRose.qml       PROPERTIES QT_RESOURCE_ALIAS "CompassRose.qml")
set_source_files_properties(qml/overlays/DepthGauge.qml        PROPERTIES QT_RESOURCE_ALIAS "DepthGauge.qml")

qt_add_qml_module(RovoControl
    URI RovoControl
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/Theme.qml
        qml/components/VehicleSelector.qml
        qml/components/StatusBar.qml
        qml/components/DockPanel.qml
        qml/components/ConfirmDialog.qml
        qml/panels/VideoPanel.qml
        qml/panels/VideoGrid.qml
        qml/panels/TelemetryPanel.qml
        qml/panels/MapPanel.qml
        qml/panels/ControlPanel.qml
        qml/panels/JoystickPanel.qml
        qml/panels/AttitudeIndicator.qml
        qml/panels/CameraWindow.qml
        qml/overlays/HudOverlay.qml
        qml/overlays/CompassRose.qml
        qml/overlays/DepthGauge.qml
)

# ─── Link libraries ────────────────────────────────────────────────────────
target_link_libraries(RovoControl PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Network
    Qt6::Svg
    mavlink
)

if(Qt6WebEngineQuick_FOUND)
    target_link_libraries(RovoControl PRIVATE Qt6::WebEngineQuick Qt6::WebChannel)
endif()

if(ENABLE_GSTREAMER)
    target_include_directories(RovoControl PRIVATE ${GSTREAMER_INCLUDE_DIRS})
    target_link_libraries(RovoControl PRIVATE ${GSTREAMER_LIBRARIES})
endif()

if(ENABLE_SDL2)
    target_include_directories(RovoControl PRIVATE ${SDL2_INCLUDE_DIRS})
    target_link_libraries(RovoControl PRIVATE ${SDL2_LIBRARIES})
endif()

# ─── Include paths ──────────────────────────────────────────────────────────
target_include_directories(RovoControl PRIVATE
    "${CMAKE_SOURCE_DIR}/src"
)

# ─── Install ────────────────────────────────────────────────────────────────
install(TARGETS RovoControl
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
