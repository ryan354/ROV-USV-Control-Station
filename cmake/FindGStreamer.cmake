# FindGStreamer.cmake - Find GStreamer 1.0 on Windows (MSVC)
#
# Sets:
#   GStreamer_FOUND
#   GSTREAMER_INCLUDE_DIRS
#   GSTREAMER_LIBRARIES

# Check environment variable set by GStreamer MSI installer
set(GSTREAMER_ROOT "$ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64}")

# Strip trailing slashes
string(REGEX REPLACE "[/\\\\]+$" "" GSTREAMER_ROOT "${GSTREAMER_ROOT}")

if(NOT GSTREAMER_ROOT OR NOT EXISTS "${GSTREAMER_ROOT}/include/gstreamer-1.0")
    # Fallback common install paths
    foreach(_path "C:/gstreamer/1.0/msvc_x86_64" "D:/gstreamer/1.0/msvc_x86_64")
        if(EXISTS "${_path}/include/gstreamer-1.0")
            set(GSTREAMER_ROOT "${_path}")
            break()
        endif()
    endforeach()
endif()

if(GSTREAMER_ROOT AND EXISTS "${GSTREAMER_ROOT}/include/gstreamer-1.0")
    set(GSTREAMER_INCLUDE_DIRS
        "${GSTREAMER_ROOT}/include/gstreamer-1.0"
        "${GSTREAMER_ROOT}/include/glib-2.0"
        "${GSTREAMER_ROOT}/lib/glib-2.0/include"
    )

    set(GSTREAMER_LIBRARIES
        "${GSTREAMER_ROOT}/lib/gstreamer-1.0.lib"
        "${GSTREAMER_ROOT}/lib/gstapp-1.0.lib"
        "${GSTREAMER_ROOT}/lib/gstvideo-1.0.lib"
        "${GSTREAMER_ROOT}/lib/glib-2.0.lib"
        "${GSTREAMER_ROOT}/lib/gobject-2.0.lib"
    )

    # Verify all libs exist
    set(GStreamer_FOUND TRUE)
    foreach(_lib ${GSTREAMER_LIBRARIES})
        if(NOT EXISTS "${_lib}")
            message(WARNING "GStreamer lib not found: ${_lib}")
            set(GStreamer_FOUND FALSE)
        endif()
    endforeach()

    if(GStreamer_FOUND)
        message(STATUS "GStreamer found at: ${GSTREAMER_ROOT}")
    endif()
else()
    set(GStreamer_FOUND FALSE)
endif()

if(NOT GStreamer_FOUND AND GStreamer_FIND_REQUIRED)
    message(FATAL_ERROR "GStreamer not found. Install from https://gstreamer.freedesktop.org/download/")
endif()
