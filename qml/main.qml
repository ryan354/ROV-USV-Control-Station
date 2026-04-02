import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtWebEngine

ApplicationWindow {
    id: root
    visible: true
    width: 1400
    height: 800
    minimumWidth: 1000
    minimumHeight: 600
    title: "RovoControl — ROV & USV Ground Station"
    color: "#1a1a2e"

    Material.theme: Material.Dark
    Material.accent: "#e94560"
    Material.background: "#1a1a2e"
    Material.foreground: "#e0e0e0"

    // ─── Convenience aliases ────────────────────────────────────────────────
    property var activeVehicle: vehicleManager.activeVehicle
    property var rov: vehicleManager.rovVehicle
    property var usv: vehicleManager.usvVehicle

    // ─── Header Toolbar ─────────────────────────────────────────────────────
    header: ToolBar {
        height: 44
        background: Rectangle {
            color: "#16213e"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#2a3f55" }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 8

            // App title
            Label {
                text: "RovoControl"
                font.pixelSize: 20; font.bold: true; color: "#e94560"
            }

            Rectangle { width: 1; height: 24; color: "#2a3f55" }

            // ── ROV selector ──
            Button {
                flat: true
                highlighted: activeVehicle === rov
                onClicked: vehicleManager.selectROV()

                contentItem: Row {
                    spacing: 6
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: rov && rov.connected ? "#4caf50" : "#6e6e6e"
                    }
                    Label {
                        text: rov ? rov.name : "ROV"
                        color: "#00bcd4"
                        font.pixelSize: 13
                        font.bold: activeVehicle === rov
                    }
                }
                background: Rectangle {
                    color: parent.highlighted ? Qt.rgba(0, 0.74, 0.83, 0.15) :
                           parent.hovered ? "#2a3f55" : "transparent"
                    radius: 6
                    border.width: parent.highlighted ? 1 : 0
                    border.color: "#00bcd4"
                }
            }

            Rectangle { width: 1; height: 24; color: "#2a3f55" }

            // ── USV selector ──
            Button {
                flat: true
                highlighted: activeVehicle === usv
                onClicked: vehicleManager.selectUSV()

                contentItem: Row {
                    spacing: 6
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: usv && usv.connected ? "#4caf50" : "#6e6e6e"
                    }
                    Label {
                        text: usv ? usv.name : "USV"
                        color: "#ff9800"
                        font.pixelSize: 13
                        font.bold: activeVehicle === usv
                    }
                }
                background: Rectangle {
                    color: parent.highlighted ? Qt.rgba(1, 0.6, 0, 0.15) :
                           parent.hovered ? "#2a3f55" : "transparent"
                    radius: 6
                    border.width: parent.highlighted ? 1 : 0
                    border.color: "#ff9800"
                }
            }

            Item { Layout.fillWidth: true }

            // ── ARM / DISARM ──
            Button {
                text: "ARM"
                enabled: activeVehicle && activeVehicle.connected && !activeVehicle.armed
                onClicked: if (activeVehicle) activeVehicle.arm()
                background: Rectangle {
                    color: parent.enabled ? (parent.pressed ? "#c62828" : parent.hovered ? "#ef5350" : "#f44336") : "#37474f"
                    radius: 6
                }
                contentItem: Label {
                    text: "ARM"; color: parent.parent.enabled ? "white" : "#6e6e6e"
                    font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                }
            }
            Button {
                text: "DISARM"
                enabled: activeVehicle && activeVehicle.connected && activeVehicle.armed
                onClicked: if (activeVehicle) activeVehicle.disarm()
                background: Rectangle {
                    color: parent.enabled ? (parent.pressed ? "#2e7d32" : parent.hovered ? "#66bb6a" : "#4caf50") : "#37474f"
                    radius: 6
                }
                contentItem: Label {
                    text: "DISARM"; color: parent.parent.enabled ? "white" : "#6e6e6e"
                    font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle { width: 1; height: 24; color: "#2a3f55" }

            // ── Mode selector ──
            Label { text: "Mode:"; color: "#9e9e9e"; font.pixelSize: 12 }
            ComboBox {
                id: modeCombo
                width: 120
                model: {
                    if (!activeVehicle) return ["---"]
                    // vehicleType: 1=ROV, 2=USV
                    if (activeVehicle.vehicleType === 1)
                        return ["MANUAL", "STABILIZE", "ALT_HOLD", "POSHOLD", "GUIDED", "AUTO", "SURFACE"]
                    else
                        return ["MANUAL", "HOLD", "LOITER", "AUTO", "RTL", "GUIDED", "ACRO"]
                }
                currentIndex: activeVehicle ? Math.max(0, model.indexOf(activeVehicle.flightMode)) : 0
                onActivated: if (activeVehicle && currentText !== "---") activeVehicle.setMode(currentText)

                background: Rectangle { color: "#243447"; radius: 6; border.width: 1; border.color: "#2a3f55" }
                contentItem: Label {
                    text: modeCombo.displayText; color: "#e0e0e0"
                    font.pixelSize: 11; leftPadding: 8; verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle { width: 1; height: 24; color: "#2a3f55" }

            // ── Settings ──
            ToolButton {
                text: "\u2699"
                font.pixelSize: 18
                onClicked: settingsPopup.open()
                background: Rectangle {
                    color: parent.hovered ? "#2a3f55" : "transparent"; radius: 6
                }
            }
        }
    }

    // ─── Main Content ───────────────────────────────────────────────────────
    SplitView {
        id: mainSplit
        anchors.fill: parent
        orientation: Qt.Horizontal

        // ═══ Left: Video + Telemetry ════════════════════════════════════════
        SplitView {
            orientation: Qt.Vertical
            SplitView.preferredWidth: parent.width * 0.6
            SplitView.minimumWidth: 400

            // ── Video Grid 2x2 ──
            Rectangle {
                id: videoArea
                color: "#1a1a2e"
                SplitView.fillHeight: true
                SplitView.minimumHeight: 300
                clip: true

                Grid {
                    anchors.fill: parent; anchors.margins: 2
                    columns: 2; rows: 2; spacing: 2

                    Repeater {
                        model: [
                            { name: "ROV Cam 1", col: "#00bcd4", vtype: "rov" },
                            { name: "ROV Cam 2", col: "#00bcd4", vtype: "rov" },
                            { name: "USV Cam 1", col: "#ff9800", vtype: "usv" },
                            { name: "USV Cam 2", col: "#ff9800", vtype: "usv" }
                        ]

                        Rectangle {
                            width: (videoArea.width - 6) / 2
                            height: (videoArea.height - 6) / 2
                            color: "#16213e"
                            border.width: 1; border.color: "#2a3f55"

                            property var cam_vehicle: modelData.vtype === "rov" ? rov : usv

                            Column {
                                anchors.centerIn: parent; spacing: 8
                                Label {
                                    text: "NO SIGNAL"
                                    font.pixelSize: 16; font.bold: true; color: "#6e6e6e"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Label {
                                    text: cam_vehicle ? cam_vehicle.name + " Cam" : modelData.name
                                    font.pixelSize: 11; color: "#9e9e9e"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            // Label badge
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8
                                color: "#80000000"; radius: 4
                                width: badgeLbl.width + 12; height: badgeLbl.height + 4
                                Label {
                                    id: badgeLbl; anchors.centerIn: parent
                                    text: cam_vehicle ? cam_vehicle.name + " Cam " + ((index % 2) + 1) : modelData.name
                                    font.pixelSize: 10; color: modelData.col
                                }
                            }
                        }
                    }
                }
            }

            // ── Telemetry Panel ──
            Rectangle {
                color: "#1e2a3a"
                SplitView.preferredHeight: 110
                SplitView.minimumHeight: 70
                SplitView.maximumHeight: 180

                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#2a3f55" }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 16

                    // Vehicle indicator
                    Column {
                        spacing: 2; Layout.preferredWidth: 90

                        Label {
                            text: activeVehicle ? activeVehicle.name : "---"
                            font.pixelSize: 16; font.bold: true
                            color: {
                                if (!activeVehicle) return "#6e6e6e"
                                return activeVehicle.vehicleType === 1 ? "#00bcd4" : "#ff9800"
                            }
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Label {
                            text: activeVehicle ? activeVehicle.flightMode : "---"
                            font.pixelSize: 11; color: "#9e9e9e"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Rectangle {
                            width: 64; height: 18; radius: 9
                            color: activeVehicle && activeVehicle.armed ? "#f44336" : "#4caf50"
                            anchors.horizontalCenter: parent.horizontalCenter
                            Label {
                                anchors.centerIn: parent
                                text: activeVehicle && activeVehicle.armed ? "ARMED" : "DISARMED"
                                font.pixelSize: 8; font.bold: true; color: "white"
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4; color: "#2a3f55" }

                    // Telemetry grid — bound to activeVehicle
                    GridLayout {
                        Layout.fillWidth: true; columns: 6; columnSpacing: 16; rowSpacing: 2

                        // Row 1: labels
                        Label { text: "DEPTH"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "HEADING"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "SPEED"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "BATTERY"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "GPS"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "THROTTLE"; font.pixelSize: 9; color: "#6e6e6e" }

                        // Row 2: values
                        Label { text: activeVehicle ? activeVehicle.depth.toFixed(1) + " m" : "--- m"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.heading.toFixed(0) + "\u00B0" : "---\u00B0"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.groundSpeed.toFixed(1) + " m/s" : "--- m/s"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label {
                            text: activeVehicle ? activeVehicle.batteryVoltage.toFixed(1) + "V " +
                                  (activeVehicle.batteryPercent >= 0 ? activeVehicle.batteryPercent + "%" : "") : "---V"
                            font.pixelSize: 14; font.bold: true
                            color: activeVehicle && activeVehicle.batteryPercent >= 0 && activeVehicle.batteryPercent < 20 ? "#f44336" :
                                   activeVehicle && activeVehicle.batteryPercent >= 0 && activeVehicle.batteryPercent < 40 ? "#ff9800" : "#00ff88"
                        }
                        Label {
                            text: activeVehicle ? activeVehicle.gpsSatCount + " sats" : "--- sats"
                            font.pixelSize: 14; font.bold: true
                            color: activeVehicle && activeVehicle.gpsFixType < 2 ? "#f44336" :
                                   activeVehicle && activeVehicle.gpsFixType < 3 ? "#ff9800" : "#00ff88"
                        }
                        Label { text: activeVehicle ? activeVehicle.throttle.toFixed(0) + "%" : "---"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }

                        // Row 3: labels
                        Label { text: "ROLL"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "PITCH"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "YAW"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "CURRENT"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "ALT"; font.pixelSize: 9; color: "#6e6e6e" }
                        Label { text: "CLIMB"; font.pixelSize: 9; color: "#6e6e6e" }

                        // Row 4: values
                        Label { text: activeVehicle ? activeVehicle.roll.toFixed(1) + "\u00B0" : "---"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.pitch.toFixed(1) + "\u00B0" : "---"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.yaw.toFixed(1) + "\u00B0" : "---"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.batteryCurrent.toFixed(1) + " A" : "--- A"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.altitude.toFixed(1) + " m" : "--- m"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                        Label { text: activeVehicle ? activeVehicle.climbRate.toFixed(1) + " m/s" : "--- m/s"; font.pixelSize: 14; font.bold: true; color: "#00ff88" }
                    }
                }
            }
        }

        // ═══ Right: Map (Leaflet via WebEngine) ════════════════════════════
        Rectangle {
            color: "#1e2a3a"
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // Map header
                Rectangle {
                    Layout.fillWidth: true; height: 32; color: "#0f3460"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        Label { text: "MAP"; font.pixelSize: 11; font.bold: true; color: "#9e9e9e" }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: vehicleManager.vehicleCount + " vehicle(s)"
                            font.pixelSize: 10; color: "#6e6e6e"
                        }
                    }
                }

                // Leaflet map
                WebEngineView {
                    id: mapView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    backgroundColor: "#1a1a2e"
                    url: "qrc:/map/index.html"

                    property bool mapReady: false

                    onContextMenuRequested: function(request) { request.accepted = true }
                    onLoadingChanged: function(loadRequest) {
                        if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                            mapReady = true
                            console.log("Map loaded successfully")
                        }
                    }

                    // Push vehicle positions to map via runJavaScript
                    function pushVehicleToMap(vehicle) {
                        if (!mapReady || !vehicle) return
                        if (vehicle.latitude === 0 && vehicle.longitude === 0) return
                        var js = "window.updateVehiclePosition(" +
                                 vehicle.sysId + "," +
                                 vehicle.latitude + "," +
                                 vehicle.longitude + "," +
                                 vehicle.heading + "," +
                                 vehicle.vehicleType + ")"
                        mapView.runJavaScript(js)
                    }
                }

                // Timer to push positions to map at ~2 Hz
                Timer {
                    interval: 500; running: true; repeat: true
                    onTriggered: {
                        if (mapView.mapReady) {
                            mapView.pushVehicleToMap(rov)
                            mapView.pushVehicleToMap(usv)
                        }
                    }
                }

                // Coord overlay
                Rectangle {
                    Layout.fillWidth: true; height: 22; color: "#16213e"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 16
                        Label {
                            text: rov ? "ROV: " + rov.latitude.toFixed(6) + ", " + rov.longitude.toFixed(6) : "ROV: ---"
                            font.pixelSize: 10; color: "#00bcd4"
                        }
                        Label {
                            text: usv ? "USV: " + usv.latitude.toFixed(6) + ", " + usv.longitude.toFixed(6) : "USV: ---"
                            font.pixelSize: 10; color: "#ff9800"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    // ─── Status Bar (live data) ─────────────────────────────────────────────
    footer: Rectangle {
        height: 28; color: "#16213e"
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#2a3f55" }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 16

            // ROV status
            Row {
                spacing: 4
                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: rov && rov.connected ? "#4caf50" : "#f44336"
                }
                Label {
                    text: rov && rov.connected ? "ROV Connected" : "ROV Disconnected"
                    font.pixelSize: 11; color: "#9e9e9e"
                }
            }

            // USV status
            Row {
                spacing: 4
                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: usv && usv.connected ? "#4caf50" : "#f44336"
                }
                Label {
                    text: usv && usv.connected ? "USV Connected" : "USV Disconnected"
                    font.pixelSize: 11; color: "#9e9e9e"
                }
            }

            Rectangle { width: 1; height: 14; color: "#2a3f55" }

            // MAVLink stats
            Label {
                text: "MAVLink: " + mavlinkManager.messagesPerSecond + " msg/s"
                font.pixelSize: 11; color: "#9e9e9e"
            }

            Item { Layout.fillWidth: true }

            Label { text: "Ports: " + mavlinkManager.ports; font.pixelSize: 11; color: "#6e6e6e" }
            Label { text: "v0.1.0"; font.pixelSize: 11; color: "#6e6e6e" }
        }
    }

    // ─── Settings Window ────────────────────────────────────────────────────
    Popup {
        id: settingsPopup
        anchors.centerIn: parent
        width: 720; height: 750
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape
        padding: 0

        // ── Temp edit state (not saved until Apply) ──
        property string t_rovSysId
        property string t_rovPort
        property string t_rovCam1
        property string t_rovCam2
        property string t_usvSysId
        property string t_usvPort
        property string t_usvCam1
        property string t_usvCam2
        property bool dirty: false

        function loadFromSettings() {
            t_rovSysId = String(settings.rovSysId)
            t_rovPort  = String(settings.rovPort)
            t_rovCam1  = settings.rovCamera1
            t_rovCam2  = settings.rovCamera2
            t_usvSysId = String(settings.usvSysId)
            t_usvPort  = String(settings.usvPort)
            t_usvCam1  = settings.usvCamera1
            t_usvCam2  = settings.usvCamera2
            dirty = false
        }

        function applySettings() {
            settings.rovSysId   = parseInt(t_rovSysId) || 1
            settings.rovPort    = parseInt(t_rovPort)  || 14550
            settings.rovCamera1 = t_rovCam1
            settings.rovCamera2 = t_rovCam2
            settings.usvSysId   = parseInt(t_usvSysId) || 2
            settings.usvPort    = parseInt(t_usvPort)  || 14551
            settings.usvCamera1 = t_usvCam1
            settings.usvCamera2 = t_usvCam2

            // Restart MAVLink with new ports
            mavlinkManager.stop()
            mavlinkManager.start(settings.rovPort, settings.usvPort)

            // Save joystick config
            joystickManager.saveConfig()

            dirty = false
            console.log("Settings applied — MAVLink restarted on ports " + settings.rovPort + ", " + settings.usvPort)
        }

        onOpened: loadFromSettings()

        background: Rectangle {
            color: "#1a2235"; radius: 10
            border.width: 1; border.color: "#2a3f55"

            // Shadow
            layer.enabled: true
            layer.effect: Item {} // placeholder — shadow not critical
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // ══ Title Bar ════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true; height: 48; color: "#16213e"
                radius: 10

                // Square off bottom corners
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: parent.color }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 8; spacing: 10

                    Label { text: "\u2699"; font.pixelSize: 20; color: "#9e9e9e" }
                    Label { text: "Settings"; font.pixelSize: 16; font.bold: true; color: "#e0e0e0" }

                    // Unsaved indicator
                    Rectangle {
                        visible: settingsPopup.dirty
                        width: unsavedLbl.width + 12; height: 18; radius: 9
                        color: "#e94560"
                        Label {
                            id: unsavedLbl; anchors.centerIn: parent
                            text: "Unsaved"; font.pixelSize: 9; font.bold: true; color: "white"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ToolButton {
                        text: "\u2715"; font.pixelSize: 16
                        onClicked: settingsPopup.close()
                        background: Rectangle { color: parent.hovered ? "#f44336" : "transparent"; radius: 4 }
                        contentItem: Label { text: "\u2715"; color: parent.parent.hovered ? "white" : "#6e6e6e"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter }
                    }
                }
            }

            // ══ Scrollable Content ═══════════════════════════════════════════
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: contentCol.height + 20
                clip: true; boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: contentCol
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: 16
                    spacing: 16

                    // ═══ ROV ═════════════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true; radius: 8; color: "#1e2a3a"
                        border.width: 1; border.color: "#00bcd4"
                        implicitHeight: rovCol.height + 24

                        ColumnLayout {
                            id: rovCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 10

                            // Header
                            RowLayout {
                                spacing: 8
                                Rectangle { width: 10; height: 10; radius: 5; color: "#00bcd4" }
                                Label { text: "ROV — Underwater Drone"; font.pixelSize: 13; font.bold: true; color: "#00bcd4" }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: rov && rov.connected ? "Connected" : "Disconnected"
                                    font.pixelSize: 10; color: rov && rov.connected ? "#4caf50" : "#6e6e6e"
                                }
                            }

                            // Fields
                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 10; rowSpacing: 8

                                Label { text: "Vehicle ID:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovSysId
                                    text: settingsPopup.t_rovSysId
                                    Layout.preferredWidth: 70; color: "#e0e0e0"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 254 }
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fRovSysId.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovSysId = text; settingsPopup.dirty = true }
                                }

                                Label { text: "UDP Port:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovPort
                                    text: settingsPopup.t_rovPort
                                    Layout.preferredWidth: 70; color: "#e0e0e0"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1024; top: 65535 }
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fRovPort.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovPort = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 1:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovCam1
                                    text: settingsPopup.t_rovCam1
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#e0e0e0"; font.pixelSize: 11
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fRovCam1.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovCam1 = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 2:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovCam2
                                    text: settingsPopup.t_rovCam2
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#e0e0e0"; font.pixelSize: 11
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fRovCam2.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovCam2 = text; settingsPopup.dirty = true }
                                }
                            }
                        }
                    }

                    // ═══ USV ═════════════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true; radius: 8; color: "#1e2a3a"
                        border.width: 1; border.color: "#ff9800"
                        implicitHeight: usvCol.height + 24

                        ColumnLayout {
                            id: usvCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 10

                            RowLayout {
                                spacing: 8
                                Rectangle { width: 10; height: 10; radius: 5; color: "#ff9800" }
                                Label { text: "USV — Surface Drone / Boat"; font.pixelSize: 13; font.bold: true; color: "#ff9800" }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: usv && usv.connected ? "Connected" : "Disconnected"
                                    font.pixelSize: 10; color: usv && usv.connected ? "#4caf50" : "#6e6e6e"
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 10; rowSpacing: 8

                                Label { text: "Vehicle ID:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvSysId
                                    text: settingsPopup.t_usvSysId
                                    Layout.preferredWidth: 70; color: "#e0e0e0"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 254 }
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fUsvSysId.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvSysId = text; settingsPopup.dirty = true }
                                }

                                Label { text: "UDP Port:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvPort
                                    text: settingsPopup.t_usvPort
                                    Layout.preferredWidth: 70; color: "#e0e0e0"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1024; top: 65535 }
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fUsvPort.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvPort = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 1:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvCam1
                                    text: settingsPopup.t_usvCam1
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#e0e0e0"; font.pixelSize: 11
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fUsvCam1.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvCam1 = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 2:"; color: "#9e9e9e"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvCam2
                                    text: settingsPopup.t_usvCam2
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#e0e0e0"; font.pixelSize: 11
                                    background: Rectangle { color: "#243447"; radius: 4; border.width: 1; border.color: fUsvCam2.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvCam2 = text; settingsPopup.dirty = true }
                                }
                            }
                        }
                    }

                    // ═══ JOYSTICK ════════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true; radius: 8; color: "#1e2a3a"
                        border.width: 1; border.color: "#4caf50"
                        implicitHeight: jsCol.height + 24

                        ColumnLayout {
                            id: jsCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 10

                            // Header
                            RowLayout {
                                spacing: 8
                                Rectangle { width: 10; height: 10; radius: 5; color: "#4caf50" }
                                Label { text: "JOYSTICK INPUT"; font.pixelSize: 13; font.bold: true; color: "#4caf50" }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: joystickManager.available
                                          ? joystickManager.joystickCount + " device(s)"
                                          : "SDL2 unavailable"
                                    font.pixelSize: 10
                                    color: joystickManager.available ? "#9e9e9e" : "#f44336"
                                }
                            }

                            // No joysticks message
                            Label {
                                visible: joystickManager.joystickCount === 0
                                text: joystickManager.available
                                      ? "No gamepads detected. Connect a controller and reopen settings."
                                      : "Joystick support requires SDL2 (not compiled)."
                                font.pixelSize: 11; font.italic: true; color: "#6e6e6e"
                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                            }

                            // Per-joystick config (Repeater)
                            Repeater {
                                model: joystickManager.joysticks

                                Rectangle {
                                    Layout.fillWidth: true; radius: 6; color: "#243447"
                                    border.width: 1; border.color: "#2a3f55"
                                    implicitHeight: jsItemCol.height + 16

                                    property var js: modelData

                                    ColumnLayout {
                                        id: jsItemCol
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.margins: 8; spacing: 8

                                        // Joystick name + info
                                        RowLayout {
                                            Label {
                                                text: js.name
                                                font.pixelSize: 12; font.bold: true; color: "#e0e0e0"
                                            }
                                            Label {
                                                text: "(" + js.axisCount + " axes, " + js.buttonCount + " btns)"
                                                font.pixelSize: 10; color: "#6e6e6e"
                                            }
                                            Item { Layout.fillWidth: true }

                                            // Vehicle assignment
                                            Label { text: "Assign to:"; font.pixelSize: 11; color: "#9e9e9e" }
                                            ComboBox {
                                                id: jsVehicleCombo
                                                width: 140
                                                model: ["Unassigned", "ROV (id:" + settings.rovSysId + ")", "USV (id:" + settings.usvSysId + ")"]
                                                currentIndex: {
                                                    var sid = joystickManager.vehicleForJoystick(js.name)
                                                    if (sid === settings.rovSysId) return 1
                                                    if (sid === settings.usvSysId) return 2
                                                    return 0
                                                }
                                                onActivated: function(idx) {
                                                    var sid = 0
                                                    if (idx === 1) sid = settings.rovSysId
                                                    else if (idx === 2) sid = settings.usvSysId
                                                    joystickManager.assignJoystickToVehicle(js.name, sid)
                                                    settingsPopup.dirty = true
                                                }
                                                font.pixelSize: 11
                                                background: Rectangle { color: "#1e2a3a"; radius: 4; border.width: 1; border.color: "#2a3f55" }
                                                contentItem: Label { text: jsVehicleCombo.displayText; color: "#e0e0e0"; font.pixelSize: 11; leftPadding: 6; verticalAlignment: Text.AlignVCenter }
                                            }
                                        }

                                        // ── Axis Mapping ──
                                        Label { text: "AXIS MAPPING"; font.pixelSize: 9; font.bold: true; color: "#4a5568" }

                                        GridLayout {
                                            Layout.fillWidth: true; columns: 5; columnSpacing: 6; rowSpacing: 4

                                            // Header
                                            Label { text: "Function"; font.pixelSize: 9; color: "#6e6e6e" }
                                            Label { text: "Axis"; font.pixelSize: 9; color: "#6e6e6e" }
                                            Label { text: "Invert"; font.pixelSize: 9; color: "#6e6e6e" }
                                            Label { text: "Live"; font.pixelSize: 9; color: "#6e6e6e"; Layout.columnSpan: 2 }

                                            // X (Lateral)
                                            Label { text: "X (Lateral)"; font.pixelSize: 11; color: "#9e9e9e" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapX; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapX = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#1e2a3a"; radius: 3; border.width: 1; border.color: "#2a3f55" }
                                            }
                                            CheckBox { checked: js.invertX; onToggled: { js.invertX = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#37474f"; border.width: 1; border.color: "#2a3f55"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#1a1a2e"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisX) * parent.width / 2); x: js.axisX >= 0 ? parent.width/2 : parent.width/2 + js.axisX * parent.width/2; color: "#4caf50"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#6e6e6e" }
                                            }
                                            Label { text: js.axisX.toFixed(2); font.pixelSize: 9; color: "#4caf50"; Layout.preferredWidth: 35 }

                                            // Y (Forward)
                                            Label { text: "Y (Forward)"; font.pixelSize: 11; color: "#9e9e9e" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapY; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapY = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#1e2a3a"; radius: 3; border.width: 1; border.color: "#2a3f55" }
                                            }
                                            CheckBox { checked: js.invertY; onToggled: { js.invertY = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#37474f"; border.width: 1; border.color: "#2a3f55"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#1a1a2e"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisY) * parent.width / 2); x: js.axisY >= 0 ? parent.width/2 : parent.width/2 + js.axisY * parent.width/2; color: "#00bcd4"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#6e6e6e" }
                                            }
                                            Label { text: js.axisY.toFixed(2); font.pixelSize: 9; color: "#00bcd4"; Layout.preferredWidth: 35 }

                                            // Z (Throttle)
                                            Label { text: "Z (Throttle)"; font.pixelSize: 11; color: "#9e9e9e" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapZ; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapZ = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#1e2a3a"; radius: 3; border.width: 1; border.color: "#2a3f55" }
                                            }
                                            CheckBox { checked: js.invertZ; onToggled: { js.invertZ = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#37474f"; border.width: 1; border.color: "#2a3f55"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#1a1a2e"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisZ) * parent.width / 2); x: js.axisZ >= 0 ? parent.width/2 : parent.width/2 + js.axisZ * parent.width/2; color: "#ff9800"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#6e6e6e" }
                                            }
                                            Label { text: js.axisZ.toFixed(2); font.pixelSize: 9; color: "#ff9800"; Layout.preferredWidth: 35 }

                                            // R (Yaw)
                                            Label { text: "R (Yaw)"; font.pixelSize: 11; color: "#9e9e9e" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapR; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapR = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#1e2a3a"; radius: 3; border.width: 1; border.color: "#2a3f55" }
                                            }
                                            CheckBox { checked: js.invertR; onToggled: { js.invertR = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#37474f"; border.width: 1; border.color: "#2a3f55"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#1a1a2e"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisR) * parent.width / 2); x: js.axisR >= 0 ? parent.width/2 : parent.width/2 + js.axisR * parent.width/2; color: "#e94560"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#6e6e6e" }
                                            }
                                            Label { text: js.axisR.toFixed(2); font.pixelSize: 9; color: "#e94560"; Layout.preferredWidth: 35 }
                                        }

                                        // ── Deadzone & Expo ──
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 16

                                            Label { text: "Deadzone:"; font.pixelSize: 11; color: "#9e9e9e" }
                                            Slider { id: dzSlider; from: 0; to: 0.3; stepSize: 0.01; value: js.deadzone; Layout.preferredWidth: 120
                                                onMoved: { js.deadzone = value; settingsPopup.dirty = true }
                                            }
                                            Label { text: (js.deadzone * 100).toFixed(0) + "%"; font.pixelSize: 10; color: "#e0e0e0"; Layout.preferredWidth: 30 }

                                            Rectangle { width: 1; height: 16; color: "#2a3f55" }

                                            Label { text: "Expo:"; font.pixelSize: 11; color: "#9e9e9e" }
                                            Slider { id: expoSlider; from: 0; to: 1.0; stepSize: 0.05; value: js.expo; Layout.preferredWidth: 120
                                                onMoved: { js.expo = value; settingsPopup.dirty = true }
                                            }
                                            Label { text: (js.expo * 100).toFixed(0) + "%"; font.pixelSize: 10; color: "#e0e0e0"; Layout.preferredWidth: 30 }
                                        }

                                        // ── Button Bindings ──
                                        Label { text: "BUTTON BINDINGS"; font.pixelSize: 9; font.bold: true; color: "#4a5568" }

                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 4; columnSpacing: 6; rowSpacing: 3

                                            Repeater {
                                                model: Math.min(js.buttonCount, 16)

                                                RowLayout {
                                                    spacing: 4
                                                    Layout.columnSpan: (index % 2 === 0) ? 2 : 2

                                                    // Live indicator
                                                    Rectangle {
                                                        width: 14; height: 14; radius: 3
                                                        color: js.button(index) ? "#4caf50" : "#37474f"
                                                        border.width: 1; border.color: "#2a3f55"
                                                        Label { anchors.centerIn: parent; text: index; font.pixelSize: 7; color: "#9e9e9e" }
                                                    }

                                                    ComboBox {
                                                        implicitWidth: 130; implicitHeight: 24; font.pixelSize: 10
                                                        model: ["None", "Arm", "Disarm", "Manual", "Stabilize", "Depth Hold",
                                                                "PosHold", "Auto", "Guided", "Loiter", "RTL", "Hold", "Surface",
                                                                "Lights+", "Lights-", "CamTilt+", "CamTilt-", "Gain+", "Gain-"]

                                                        property var actionMap: ["none", "arm", "disarm", "mode_manual", "mode_stabilize",
                                                            "mode_depthhold", "mode_poshold", "mode_auto", "mode_guided",
                                                            "mode_loiter", "mode_rtl", "mode_hold", "mode_surface",
                                                            "lights_brighter", "lights_dimmer", "camera_tilt_up", "camera_tilt_down",
                                                            "gain_inc", "gain_dec"]

                                                        currentIndex: {
                                                            var act = js.buttonAction(index)
                                                            var idx = actionMap.indexOf(act)
                                                            return idx >= 0 ? idx : 0
                                                        }
                                                        onActivated: function(idx) {
                                                            js.setButtonAction(index, actionMap[idx])
                                                            settingsPopup.dirty = true
                                                        }

                                                        background: Rectangle { color: "#1e2a3a"; radius: 3; border.width: 1; border.color: "#2a3f55" }
                                                        contentItem: Label { text: parent.displayText; color: "#e0e0e0"; font.pixelSize: 10; leftPadding: 4; verticalAlignment: Text.AlignVCenter }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══ STATUS ══════════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true; radius: 8; color: "#1e2a3a"
                        border.width: 1; border.color: "#2a3f55"
                        implicitHeight: statusCol.height + 24

                        ColumnLayout {
                            id: statusCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 8

                            Label { text: "SYSTEM STATUS"; font.pixelSize: 11; font.bold: true; color: "#6e6e6e" }

                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 16; rowSpacing: 4

                                Label { text: "Vehicles:"; color: "#6e6e6e"; font.pixelSize: 11 }
                                Label { text: vehicleManager.vehicleCount + " connected"; color: "#e0e0e0"; font.pixelSize: 11; font.bold: true }

                                Label { text: "MAVLink:"; color: "#6e6e6e"; font.pixelSize: 11 }
                                Label { text: mavlinkManager.messagesPerSecond + " msg/s"; color: "#e0e0e0"; font.pixelSize: 11; font.bold: true }

                                Label { text: "Listening:"; color: "#6e6e6e"; font.pixelSize: 11 }
                                Label {
                                    text: mavlinkManager.listening ? "Yes" : "No"
                                    color: mavlinkManager.listening ? "#4caf50" : "#f44336"; font.pixelSize: 11; font.bold: true
                                }

                                Label { text: "Ports:"; color: "#6e6e6e"; font.pixelSize: 11 }
                                Label { text: mavlinkManager.ports; color: "#e0e0e0"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                }
            }

            // ══ Bottom Button Bar ════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true; height: 56; color: "#16213e"
                radius: 10
                Rectangle { anchors.top: parent.top; width: parent.width; height: 10; color: parent.color }
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#2a3f55" }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10

                    Label {
                        text: "RovoControl v0.1.0"
                        font.pixelSize: 10; color: "#4a5568"
                    }

                    Item { Layout.fillWidth: true }

                    // Cancel
                    Button {
                        text: "Cancel"
                        flat: true
                        onClicked: {
                            settingsPopup.loadFromSettings()
                            settingsPopup.close()
                        }
                        contentItem: Label {
                            text: parent.text; color: "#9e9e9e"
                            font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#2a3f55" : "transparent"
                            radius: 6; border.width: 1; border.color: "#2a3f55"
                        }
                        implicitWidth: 90; implicitHeight: 36
                    }

                    // Apply
                    Button {
                        text: "Apply"
                        enabled: settingsPopup.dirty
                        onClicked: {
                            settingsPopup.applySettings()
                        }
                        contentItem: Label {
                            text: parent.text
                            color: parent.enabled ? "white" : "#6e6e6e"
                            font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.enabled
                                ? (parent.pressed ? "#c62828" : parent.hovered ? "#ef5350" : "#e94560")
                                : "#37474f"
                            radius: 6
                        }
                        implicitWidth: 90; implicitHeight: 36
                    }

                    // Apply & Close
                    Button {
                        text: "Apply && Close"
                        enabled: settingsPopup.dirty
                        onClicked: {
                            settingsPopup.applySettings()
                            settingsPopup.close()
                        }
                        contentItem: Label {
                            text: "Apply & Close"
                            color: parent.enabled ? "white" : "#6e6e6e"
                            font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.enabled
                                ? (parent.pressed ? "#1565c0" : parent.hovered ? "#42a5f5" : "#2196f3")
                                : "#37474f"
                            radius: 6
                        }
                        implicitWidth: 120; implicitHeight: 36
                    }
                }
            }
        }
    }
}
