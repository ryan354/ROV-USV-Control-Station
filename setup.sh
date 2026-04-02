#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# RovoControl Setup Script (Windows - Git Bash / MSYS2)
# Run: ./setup.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

echo "================================================"
echo "  RovoControl — Setup Script"
echo "================================================"
echo ""

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
warn() { echo -e "  ${YELLOW}[!!]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; }
info() { echo -e "  ${CYAN}[..]${NC} $1"; }

# ─── Check Prerequisites ────────────────────────────────────────────────────
echo -e "${CYAN}Checking prerequisites...${NC}"
echo ""

# CMake
if command -v cmake &>/dev/null || [ -f "/c/Program Files/CMake/bin/cmake.exe" ]; then
    CMAKE_EXE=$(command -v cmake 2>/dev/null || echo "/c/Program Files/CMake/bin/cmake.exe")
    ok "CMake found"
else
    fail "CMake not found. Download from https://cmake.org/download/"
    exit 1
fi

# Visual Studio
VS_FOUND=false
for vs_path in "/c/Program Files/Microsoft Visual Studio/2022/Professional" \
               "/c/Program Files/Microsoft Visual Studio/2022/Community" \
               "/c/Program Files/Microsoft Visual Studio/2022/Enterprise"; do
    if [ -d "$vs_path" ]; then
        ok "Visual Studio 2022 found at $vs_path"
        VS_FOUND=true
        break
    fi
done
if [ "$VS_FOUND" = false ]; then
    fail "Visual Studio 2022 not found. Install with 'Desktop development with C++' workload"
    exit 1
fi

# Python (for aqtinstall)
if command -v python &>/dev/null; then
    ok "Python found: $(python --version 2>&1)"
else
    fail "Python not found. Download from https://python.org"
    exit 1
fi

echo ""

# ─── Install Qt 6.8.3 ───────────────────────────────────────────────────────
QT_DIR="C:/Qt/6.8.3/msvc2022_64"

if [ -f "$QT_DIR/lib/cmake/Qt6/Qt6Config.cmake" ]; then
    ok "Qt 6.8.3 already installed at $QT_DIR"
else
    echo -e "${CYAN}Installing Qt 6.8.3 (this may take a few minutes)...${NC}"
    pip install aqtinstall --quiet 2>/dev/null

    info "Installing Qt base..."
    python -m aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 --outputdir "C:/Qt" 2>&1 | tail -1

    info "Installing Qt modules (WebEngine, Multimedia, etc.)..."
    python -m aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 --outputdir "C:/Qt" \
        --modules qtwebchannel qtwebengine qtmultimedia qtshadertools qtpositioning qtserialport 2>&1 | tail -1

    if [ -f "$QT_DIR/lib/cmake/Qt6/Qt6Config.cmake" ]; then
        ok "Qt 6.8.3 installed successfully"
    else
        fail "Qt installation failed"
        exit 1
    fi
fi

# ─── Install GStreamer ───────────────────────────────────────────────────────
GST_DIR="C:/gstreamer/1.0/msvc_x86_64"

if [ -f "$GST_DIR/include/gstreamer-1.0/gst/gst.h" ]; then
    ok "GStreamer found at $GST_DIR"
else
    warn "GStreamer not found at $GST_DIR"
    echo ""
    echo "    Download MSVC 64-bit installer from:"
    echo "    https://gstreamer.freedesktop.org/download/"
    echo ""
    echo "    Install BOTH 'Runtime' and 'Development' packages."
    echo "    Default install path: C:\\gstreamer\\1.0\\msvc_x86_64\\"
    echo ""
    echo "    Video streaming will be disabled without GStreamer."
    echo ""
fi

# ─── Install SDL2 ───────────────────────────────────────────────────────────
SDL2_DIR="C:/SDL2"

if [ -f "$SDL2_DIR/include/SDL.h" ]; then
    ok "SDL2 found at $SDL2_DIR"
else
    echo -e "${CYAN}Installing SDL2...${NC}"
    SDL2_VERSION="2.30.11"
    SDL2_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/SDL2-devel-${SDL2_VERSION}-VC.zip"

    info "Downloading SDL2 ${SDL2_VERSION}..."
    curl -L -o /tmp/SDL2-devel.zip "$SDL2_URL" 2>/dev/null

    info "Extracting to C:/SDL2/..."
    mkdir -p "$SDL2_DIR"
    unzip -o /tmp/SDL2-devel.zip -d /tmp/SDL2-extract >/dev/null 2>&1
    cp -r /tmp/SDL2-extract/SDL2-${SDL2_VERSION}/* "$SDL2_DIR/"
    rm -rf /tmp/SDL2-devel.zip /tmp/SDL2-extract

    if [ -f "$SDL2_DIR/include/SDL.h" ]; then
        ok "SDL2 installed to $SDL2_DIR"
    else
        warn "SDL2 installation failed — joystick support will be disabled"
    fi
fi

# ─── Generate MAVLink Headers (if missing) ───────────────────────────────────
if [ -f "third_party/mavlink/ardupilotmega/mavlink.h" ]; then
    ok "MAVLink headers present"
else
    echo -e "${CYAN}Generating MAVLink headers...${NC}"
    pip install pymavlink --quiet 2>/dev/null

    info "Cloning MAVLink definitions..."
    git clone --depth 1 --recursive https://github.com/mavlink/mavlink.git /tmp/mavlink-src 2>/dev/null

    MAVLINK_XML=$(cygpath -m /tmp/mavlink-src/message_definitions/v1.0/ardupilotmega.xml 2>/dev/null || echo "/tmp/mavlink-src/message_definitions/v1.0/ardupilotmega.xml")
    MAVLINK_OUT=$(cygpath -m "$(pwd)/third_party/mavlink" 2>/dev/null || echo "$(pwd)/third_party/mavlink")

    info "Generating C headers (ardupilotmega dialect, MAVLink v2)..."
    python -c "
from pymavlink.generator import mavgen
from pymavlink.generator.mavgen import Opts
opts = Opts('${MAVLINK_XML}')
opts.output = '${MAVLINK_OUT}'
opts.language = 'C'
opts.wire_protocol = '2.0'
mavgen.mavgen(opts, ['${MAVLINK_XML}'])
" 2>&1 | tail -2

    rm -rf /tmp/mavlink-src

    if [ -f "third_party/mavlink/ardupilotmega/mavlink.h" ]; then
        ok "MAVLink headers generated"
    else
        fail "MAVLink header generation failed"
        exit 1
    fi
fi

echo ""

# ─── Configure ───────────────────────────────────────────────────────────────
echo -e "${CYAN}Configuring CMake build...${NC}"

"$CMAKE_EXE" -B build \
    -G "Visual Studio 17 2022" \
    -DCMAKE_PREFIX_PATH="$QT_DIR" \
    -Wno-dev 2>&1 | grep -E "GStreamer|SDL2|WebEngine|Configuring done|error" || true

echo ""

# ─── Build ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}Building RovoControl (Release)...${NC}"

"$CMAKE_EXE" --build build --config Release 2>&1 | tail -3

if [ -f "build/Release/RovoControl.exe" ]; then
    ok "Build successful: build/Release/RovoControl.exe"
else
    fail "Build failed!"
    exit 1
fi

echo ""

# ─── Deploy DLLs ────────────────────────────────────────────────────────────
echo -e "${CYAN}Deploying runtime DLLs...${NC}"

# Qt DLLs
"$QT_DIR/bin/windeployqt6.exe" build/Release/RovoControl.exe --qmldir qml 2>/dev/null

# SDL2
[ -f "$SDL2_DIR/lib/x64/SDL2.dll" ] && cp "$SDL2_DIR/lib/x64/SDL2.dll" build/Release/

# GStreamer
for dll in gobject-2.0-0.dll glib-2.0-0.dll gmodule-2.0-0.dll gio-2.0-0.dll \
           gstreamer-1.0-0.dll gstbase-1.0-0.dll gstapp-1.0-0.dll gstvideo-1.0-0.dll \
           gstpbutils-1.0-0.dll gsttag-1.0-0.dll gstaudio-1.0-0.dll gstgl-1.0-0.dll \
           gstrtp-1.0-0.dll gstrtsp-1.0-0.dll gstsdp-1.0-0.dll gstnet-1.0-0.dll \
           gstallocators-1.0-0.dll gstcontroller-1.0-0.dll \
           orc-0.4-0.dll ffi-7.dll intl-8.dll z-1.dll; do
    [ -f "$GST_DIR/bin/$dll" ] && cp "$GST_DIR/bin/$dll" build/Release/ 2>/dev/null
done

# MSVC runtime
for dll in msvcp140.dll vcruntime140.dll vcruntime140_1.dll; do
    [ -f "/c/Windows/System32/$dll" ] && cp "/c/Windows/System32/$dll" build/Release/
done

ok "DLLs deployed"

echo ""
echo "================================================"
echo -e "  ${GREEN}Setup complete!${NC}"
echo ""
echo "  Run:  build/Release/RovoControl.exe"
echo ""
echo "  VS Code: Open folder, Ctrl+Shift+B to build"
echo "================================================"
