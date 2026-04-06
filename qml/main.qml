import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtWebEngine
import QtMultimedia

ApplicationWindow {
    id: root
    visible: true
    width: 1400
    height: 800
    minimumWidth: 1000
    minimumHeight: 600
    title: "RovoControl — ROV & USV Ground Station"
    color: "#0a0f0a"

    Material.theme: Material.Dark
    Material.accent: "#ff2020"
    Material.background: "#0a0f0a"
    Material.foreground: "#00ff41"

    // ─── Convenience aliases ────────────────────────────────────────────────
    property var activeVehicle: vehicleManager.activeVehicle
    property var rov: vehicleManager.rovVehicle
    property var usv: vehicleManager.usvVehicle

    // ─── Header Toolbar ─────────────────────────────────────────────────────
    header: ToolBar {
        height: 44
        background: Rectangle {
            color: "#0f1a0f"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#1a3a1a" }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 8

            // App title
            Label {
                text: "RovoControl"
                font.pixelSize: 20; font.bold: true; color: "#ff2020"
            }

            Rectangle { width: 1; height: 24; color: "#1a3a1a" }

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
                        color: "#00ccff"
                        font.pixelSize: 13
                        font.bold: activeVehicle === rov
                    }
                }
                background: Rectangle {
                    color: parent.highlighted ? Qt.rgba(0, 0.8, 1, 0.1) :
                           parent.hovered ? "#2a3f55" : "transparent"
                    radius: 6
                    border.width: parent.highlighted ? 1 : 0
                    border.color: "#00ccff"
                }
            }

            Rectangle { width: 1; height: 24; color: "#1a3a1a" }

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
                        color: "#ffaa00"
                        font.pixelSize: 13
                        font.bold: activeVehicle === usv
                    }
                }
                background: Rectangle {
                    color: parent.highlighted ? Qt.rgba(1, 0.67, 0, 0.1) :
                           parent.hovered ? "#2a3f55" : "transparent"
                    radius: 6
                    border.width: parent.highlighted ? 1 : 0
                    border.color: "#ffaa00"
                }
            }

            Item { Layout.fillWidth: true }

            // ── ARM / DISARM ──
            Button {
                text: "ARM"
                enabled: activeVehicle && activeVehicle.connected && !activeVehicle.armed
                onClicked: if (activeVehicle) activeVehicle.arm()
                background: Rectangle {
                    color: parent.enabled ? (parent.pressed ? "#c62828" : parent.hovered ? "#ef5350" : "#f44336") : "#1a2a1a"
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
                    color: parent.enabled ? (parent.pressed ? "#2e7d32" : parent.hovered ? "#66bb6a" : "#4caf50") : "#1a2a1a"
                    radius: 6
                }
                contentItem: Label {
                    text: "DISARM"; color: parent.parent.enabled ? "white" : "#6e6e6e"
                    font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle { width: 1; height: 24; color: "#1a3a1a" }

            // ── Mode selector ──
            Label { text: "Mode:"; color: "#44aa44"; font.pixelSize: 12 }
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

                background: Rectangle { color: "#1a2a1a"; radius: 6; border.width: 1; border.color: "#1a3a1a" }
                contentItem: Label {
                    text: modeCombo.displayText; color: "#00ff41"
                    font.pixelSize: 11; leftPadding: 8; verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle { width: 1; height: 24; color: "#1a3a1a" }

            // ── Camera Window ──
            Button {
                text: "CAM"
                onClicked: cameraWindowLoader.active = !cameraWindowLoader.active
                background: Rectangle {
                    color: cameraWindowLoader.active ? Qt.rgba(1, 0.13, 0.13, 0.15) :
                           parent.hovered ? "#2a3f55" : "transparent"
                    radius: 6
                    border.width: cameraWindowLoader.active ? 1 : 0
                    border.color: "#ff2020"
                }
                contentItem: Label {
                    text: "CAM"; color: cameraWindowLoader.active ? "#e94560" : "#9e9e9e"
                    font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle { width: 1; height: 24; color: "#1a3a1a" }

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

    // ─── Camera Window (separate) ─────────────────────────────────────────
    Loader {
        id: cameraWindowLoader
        active: false
        sourceComponent: CameraWindow {
            rov: root.rov
            usv: root.usv
            onClosing: cameraWindowLoader.active = false
        }
    }

    // ─── Main Content ───────────────────────────────────────────────────────
    SplitView {
        id: mainSplit
        anchors.fill: parent
        orientation: Qt.Horizontal

        // ═══ Left: Map + Combined HUD ═══════════════════════════════════════
        SplitView {
            orientation: Qt.Vertical
            SplitView.preferredWidth: parent.width * 0.55
            SplitView.minimumWidth: 500

            // ── TOP: Camera View (single, switchable) ──
            Rectangle {
                id: cameraPanel
                color: "#0a0f0a"
                SplitView.preferredHeight: parent.height * 0.55
                SplitView.minimumHeight: 250

                // 0=ROV Cam1, 1=ROV Cam2, 2=USV Cam1, 3=USV Cam2
                property int activeCam: 0
                property var camLabels: ["ROV CAM 1", "ROV CAM 2", "USV CAM 1", "USV CAM 2"]
                property var camColors: ["#00ccff", "#00ccff", "#ffaa00", "#ffaa00"]
                property var camVehicle: activeCam < 2 ? rov : usv
                property string camUri: {
                    switch (activeCam) {
                    case 0: return settings.rovCamera1
                    case 1: return settings.rovCamera2
                    case 2: return settings.usvCamera1
                    case 3: return settings.usvCamera2
                    }
                    return ""
                }

                ColumnLayout {
                    anchors.fill: parent; spacing: 0

                    // Camera toolbar
                    Rectangle {
                        Layout.fillWidth: true; height: 28; color: "#142014"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 4

                            Label { text: "CAMERA"; font.pixelSize: 10; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                            Rectangle { width: 1; height: 16; color: "#1a3a1a" }

                            // Camera switch buttons
                            Repeater {
                                model: 4
                                Button {
                                    flat: true; width: 62; height: 22
                                    contentItem: Label {
                                        text: cameraPanel.camLabels[index]
                                        font.pixelSize: 9; font.bold: true; font.family: "Consolas"
                                        color: cameraPanel.activeCam === index ? cameraPanel.camColors[index] : "#2a5a2a"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    background: Rectangle {
                                        color: cameraPanel.activeCam === index
                                               ? Qt.rgba(cameraPanel.camColors[index] === "#00ccff" ? 0 : 1,
                                                         cameraPanel.camColors[index] === "#00ccff" ? 0.8 : 0.67,
                                                         cameraPanel.camColors[index] === "#00ccff" ? 1 : 0, 0.1)
                                               : (parent.hovered ? "#1a2a1a" : "transparent")
                                        radius: 2
                                        border.width: cameraPanel.activeCam === index ? 1 : 0
                                        border.color: cameraPanel.camColors[index]
                                    }
                                    onClicked: cameraPanel.activeCam = index
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Active camera URI (truncated)
                            Label {
                                text: cameraPanel.camUri ? cameraPanel.camUri.substring(0, 40) : "No URI"
                                font.pixelSize: 8; font.family: "Consolas"; color: "#2a5a2a"
                                elide: Text.ElideRight; Layout.maximumWidth: 200
                            }
                        }
                    }

                    // Camera view area
                    Rectangle {
                        id: camViewArea
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: "#0a0f0a"
                        clip: true

                        property var activeReceiver: videoManager.receiver(cameraPanel.activeCam)

                        // Start/switch stream when camera changes
                        Connections {
                            target: cameraPanel
                            function onActiveCamChanged() { camViewArea.switchStream() }
                        }
                        Component.onCompleted: switchStream()

                        function switchStream() {
                            // Stop all streams first
                            for (var i = 0; i < 4; i++) {
                                var r = videoManager.receiver(i)
                                if (r) r.stop()
                            }
                            // Start the active one
                            var recv = videoManager.receiver(cameraPanel.activeCam)
                            if (recv && cameraPanel.camUri) {
                                recv.setUri(cameraPanel.camUri)
                                recv.setVideoSink(videoOutput.videoSink)
                                recv.start()
                                console.log("Starting stream " + cameraPanel.activeCam + ": " + cameraPanel.camUri)
                            }
                        }

                        // Video output (GStreamer frames render here)
                        VideoOutput {
                            id: videoOutput
                            anchors.fill: parent
                            fillMode: VideoOutput.PreserveAspectFit
                        }

                        // Camera label badge (top-left)
                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8
                            z: 10; color: "#cc0a0f0a"; radius: 3
                            width: camBadge.width + 12; height: camBadge.height + 6
                            border.width: 1; border.color: cameraPanel.camColors[cameraPanel.activeCam]

                            Label {
                                id: camBadge; anchors.centerIn: parent
                                text: cameraPanel.camLabels[cameraPanel.activeCam]
                                font.pixelSize: 11; font.bold: true; font.family: "Consolas"
                                color: cameraPanel.camColors[cameraPanel.activeCam]
                            }
                        }

                        // Vehicle info overlay (top-right)
                        Rectangle {
                            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                            z: 10; color: "#cc0a0f0a"; radius: 3
                            width: vehicleInfo.width + 12; height: vehicleInfo.height + 6
                            visible: cameraPanel.camVehicle !== null

                            Label {
                                id: vehicleInfo; anchors.centerIn: parent
                                text: cameraPanel.camVehicle
                                      ? cameraPanel.camVehicle.name + " | " + cameraPanel.camVehicle.flightMode +
                                        (cameraPanel.camVehicle.armed ? " | ARMED" : "")
                                      : ""
                                font.pixelSize: 10; font.family: "Consolas"
                                color: cameraPanel.camVehicle && cameraPanel.camVehicle.armed ? "#ff2020" : "#00ff41"
                            }
                        }

                        // Stream status overlay (bottom-left)
                        Rectangle {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 8
                            z: 10; color: "#cc0a0f0a"; radius: 3
                            width: statusLbl.width + 12; height: statusLbl.height + 6
                            visible: camViewArea.activeReceiver !== null

                            Label {
                                id: statusLbl; anchors.centerIn: parent
                                text: {
                                    var r = camViewArea.activeReceiver
                                    if (!r) return ""
                                    var s = r.status
                                    if (r.playing) s += " | " + r.width + "x" + r.height + " | " + r.fps + "fps"
                                    return s
                                }
                                font.pixelSize: 9; font.family: "Consolas"; color: "#44aa44"
                            }
                        }

                        // No signal placeholder (shown when not playing)
                        Column {
                            anchors.centerIn: parent; spacing: 8
                            visible: !camViewArea.activeReceiver || !camViewArea.activeReceiver.playing

                            Label {
                                text: "NO SIGNAL"
                                font.pixelSize: 28; font.bold: true; font.family: "Consolas"
                                color: "#1a3a1a"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Label {
                                text: cameraPanel.camLabels[cameraPanel.activeCam]
                                font.pixelSize: 14; font.family: "Consolas"
                                color: cameraPanel.camColors[cameraPanel.activeCam]
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Label {
                                text: camViewArea.activeReceiver ? camViewArea.activeReceiver.status : "No receiver"
                                font.pixelSize: 11; font.family: "Consolas"; color: "#2a5a2a"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Label {
                                text: cameraPanel.camUri || "No stream URI configured"
                                font.pixelSize: 10; font.family: "Consolas"; color: "#2a5a2a"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                                Repeater {
                                    model: ["1: ROV1", "2: ROV2", "3: USV1", "4: USV2"]
                                    Label { text: modelData; font.pixelSize: 9; font.family: "Consolas"; color: "#2a5a2a" }
                                }
                            }
                        }
                    }
                }

                // Keyboard shortcuts 1-4 to switch camera
                Shortcut { sequence: "1"; onActivated: cameraPanel.activeCam = 0 }
                Shortcut { sequence: "2"; onActivated: cameraPanel.activeCam = 1 }
                Shortcut { sequence: "3"; onActivated: cameraPanel.activeCam = 2 }
                Shortcut { sequence: "4"; onActivated: cameraPanel.activeCam = 3 }
            }

            // ── BOTTOM: Combined HUD (both vehicles) ──
            Rectangle {
                color: "#0a0f0a"
                SplitView.fillHeight: true
                SplitView.minimumHeight: 180

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 4; spacing: 4

                    // ── ROV HUD ──
                    VehiclePanel {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        vehicle: rov; accentColor: "#00ccff"; vehicleLabel: "ROV"
                        joystick: null; isActive: activeVehicle === rov
                    }

                    // ── USV HUD ──
                    VehiclePanel {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        vehicle: usv; accentColor: "#ffaa00"; vehicleLabel: "USV"
                        joystick: null; isActive: activeVehicle === usv
                    }
                }
            }
        }

        // ═══ Right: Path Planning ═════════════════════════════════════════════
        Rectangle {
            id: planArea
            color: "#0a0f0a"
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300

            property string planMode: "waypoint"
            property bool planForRov: true
            property bool planMapReady: false
            function planCmd(js) { if (planMapReady) planMapView.runJavaScript(js) }

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                // Toolbar
                Rectangle {
                    Layout.fillWidth: true; height: 28; color: "#111c11"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 4

                        Label { text: "PLAN"; font.pixelSize: 10; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                        Rectangle { width: 1; height: 16; color: "#1a3a1a" }

                        Button {
                            flat: true; width: 44; height: 20
                            contentItem: Label { text: "ROV"; font.pixelSize: 9; font.bold: true; font.family: "Consolas"; color: planArea.planForRov ? "#00ccff" : "#2a5a2a"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: planArea.planForRov ? Qt.rgba(0,0.8,1,0.1) : "transparent"; radius: 2; border.width: planArea.planForRov ? 1 : 0; border.color: "#00ccff" }
                            onClicked: planArea.planForRov = true
                        }
                        Button {
                            flat: true; width: 44; height: 20
                            contentItem: Label { text: "USV"; font.pixelSize: 9; font.bold: true; font.family: "Consolas"; color: !planArea.planForRov ? "#ffaa00" : "#2a5a2a"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: !planArea.planForRov ? Qt.rgba(1,0.67,0,0.1) : "transparent"; radius: 2; border.width: !planArea.planForRov ? 1 : 0; border.color: "#ffaa00" }
                            onClicked: planArea.planForRov = false
                        }

                        Rectangle { width: 1; height: 16; color: "#1a3a1a" }

                        Button {
                            flat: true; width: 44; height: 20
                            contentItem: Label { text: "WPT"; font.pixelSize: 9; font.bold: true; font.family: "Consolas"; color: planArea.planMode === "waypoint" ? "#00ff41" : "#44aa44"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: planArea.planMode === "waypoint" ? "#1a2a1a" : "transparent"; radius: 2; border.width: planArea.planMode === "waypoint" ? 1 : 0; border.color: "#00ff41" }
                            onClicked: { planArea.planMode = "waypoint"; planArea.planCmd("setMode('waypoint')") }
                        }
                        Button {
                            flat: true; width: 44; height: 20
                            contentItem: Label { text: "POLY"; font.pixelSize: 9; font.bold: true; font.family: "Consolas"; color: planArea.planMode === "polygon" ? "#00ff41" : "#44aa44"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: planArea.planMode === "polygon" ? "#1a2a1a" : "transparent"; radius: 2; border.width: planArea.planMode === "polygon" ? 1 : 0; border.color: "#00ff41" }
                            onClicked: { planArea.planMode = "polygon"; planArea.planCmd("setMode('polygon')") }
                        }
                        Button {
                            flat: true; width: 44; height: 20
                            contentItem: Label { text: "LBL"; font.pixelSize: 9; font.bold: true; font.family: "Consolas"; color: planArea.planMode === "label" ? "#00ff41" : "#44aa44"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: planArea.planMode === "label" ? "#1a2a1a" : "transparent"; radius: 2; border.width: planArea.planMode === "label" ? 1 : 0; border.color: "#00ff41" }
                            onClicked: { planArea.planMode = "label"; planArea.planCmd("setMode('label')") }
                        }

                        Rectangle { width: 1; height: 16; color: "#1a3a1a" }

                        Button {
                            flat: true; width: 44; height: 20
                            contentItem: Label { text: "UNDO"; font.pixelSize: 9; font.family: "Consolas"; color: "#ffaa00"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: parent.hovered ? "#1a2a1a" : "transparent"; radius: 2 }
                            onClicked: planArea.planCmd("undoLast()")
                        }
                        Button {
                            flat: true; width: 50; height: 20
                            contentItem: Label { text: "CLEAR"; font.pixelSize: 9; font.family: "Consolas"; color: "#ff2020"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: parent.hovered ? "#1a2a1a" : "transparent"; radius: 2 }
                            onClicked: planArea.planCmd("clearAll()")
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            flat: true; width: 80; height: 22
                            contentItem: Label { text: "UPLOAD"; font.pixelSize: 10; font.bold: true; font.family: "Consolas"; color: "white"; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { color: parent.pressed ? "#1a5a1a" : parent.hovered ? "#1a3a1a" : "#0a2a0a"; radius: 2; border.width: 1; border.color: "#00ff41" }
                            onClicked: {
                                if (!planArea.planMapReady) return
                                planMapView.runJavaScript("getWaypoints()", function(result) {
                                    console.log("Upload to " + (planArea.planForRov ? "ROV" : "USV") + ": " + result)
                                })
                            }
                        }
                    }
                }

                WebEngineView {
                    id: planMapView
                    Layout.fillWidth: true; Layout.fillHeight: true
                    backgroundColor: "#0a0f0a"
                    url: "qrc:/map/plan.html"
                    onContextMenuRequested: function(request) { request.accepted = true }
                    onLoadingChanged: function(lr) {
                        if (lr.status === WebEngineView.LoadSucceededStatus) {
                            planArea.planMapReady = true
                            if (rov && rov.latitude !== 0)
                                runJavaScript("setCenter(" + rov.latitude + "," + rov.longitude + ",17)")
                        }
                    }
                    onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceId) {
                        if (message.indexOf("LABEL_REQUEST:") === 0) {
                            var parts = message.substring(14).split(",")
                            labelDialog.labelLat = parseFloat(parts[0])
                            labelDialog.labelLng = parseFloat(parts[1])
                            labelDialog.open()
                        }
                    }
                }

                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        if (!planArea.planMapReady) return
                        if (rov && rov.latitude !== 0)
                            planMapView.runJavaScript("updateVehiclePosition(" + rov.sysId + "," + rov.latitude + "," + rov.longitude + "," + rov.heading + "," + rov.vehicleType + ")")
                        if (usv && usv.latitude !== 0)
                            planMapView.runJavaScript("updateVehiclePosition(" + usv.sysId + "," + usv.latitude + "," + usv.longitude + "," + usv.heading + "," + usv.vehicleType + ")")
                    }
                }
            }
        }
    }

    // ─── Status Bar (live data) ─────────────────────────────────────────────
    footer: Rectangle {
        height: 28; color: "#0f1a0f"
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#1a3a1a" }

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
                    font.pixelSize: 11; color: "#44aa44"
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
                    font.pixelSize: 11; color: "#44aa44"
                }
            }

            Rectangle { width: 1; height: 14; color: "#1a3a1a" }

            // MAVLink stats
            Label {
                text: "MAVLink: " + mavlinkManager.messagesPerSecond + " msg/s"
                font.pixelSize: 11; color: "#44aa44"
            }

            Item { Layout.fillWidth: true }

            Label { text: "Ports: " + mavlinkManager.ports; font.pixelSize: 11; color: "#2a5a2a" }
            Label { text: "v0.1.0"; font.pixelSize: 11; color: "#2a5a2a" }
        }
    }

    // ─── Label Input Dialog ─────────────────────────────────────────────────
    Popup {
        id: labelDialog
        anchors.centerIn: parent; width: 350; height: 100
        modal: true; padding: 0
        property real labelLat: 0
        property real labelLng: 0
        background: Rectangle { color: "#0a0f0a"; radius: 4; border.width: 1; border.color: "#ffaa00" }
        onOpened: { labelTextField.text = ""; labelTextField.forceActiveFocus() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 6
            Label { text: "ADD LABEL"; font.pixelSize: 11; font.bold: true; font.family: "Consolas"; color: "#ffaa00" }
            RowLayout {
                spacing: 6
                TextField {
                    id: labelTextField; Layout.fillWidth: true
                    placeholderText: "Label text..."
                    font.pixelSize: 12; font.family: "Consolas"; color: "#ffaa00"
                    background: Rectangle { color: "#111c11"; radius: 2; border.width: 1; border.color: "#1a3a1a" }
                    onAccepted: {
                        if (text.length > 0) {
                            planMapView.runJavaScript("addLabel(" + labelDialog.labelLat + "," + labelDialog.labelLng + ",'" + text.replace(/'/g, "\\'") + "')")
                            labelDialog.close()
                        }
                    }
                }
                Button {
                    flat: true; width: 50
                    contentItem: Label { text: "ADD"; font.pixelSize: 10; font.bold: true; font.family: "Consolas"; color: "#ffaa00"; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { color: parent.hovered ? "#1a2a1a" : "#111c11"; radius: 2; border.width: 1; border.color: "#ffaa00" }
                    onClicked: {
                        if (labelTextField.text.length > 0) {
                            planMapView.runJavaScript("addLabel(" + labelDialog.labelLat + "," + labelDialog.labelLng + ",'" + labelTextField.text.replace(/'/g, "\\'") + "')")
                            labelDialog.close()
                        }
                    }
                }
            }
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
            color: "#0a0f0a"; radius: 10
            border.width: 1; border.color: "#1a3a1a"

            // Shadow
            layer.enabled: true
            layer.effect: Item {} // placeholder — shadow not critical
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // ══ Title Bar ════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true; height: 48; color: "#0f1a0f"
                radius: 10

                // Square off bottom corners
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: parent.color }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 8; spacing: 10

                    Label { text: "\u2699"; font.pixelSize: 20; color: "#44aa44" }
                    Label { text: "Settings"; font.pixelSize: 16; font.bold: true; color: "#00ff41" }

                    // Unsaved indicator
                    Rectangle {
                        visible: settingsPopup.dirty
                        width: unsavedLbl.width + 12; height: 18; radius: 9
                        color: "#ff2020"
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
                        Layout.fillWidth: true; radius: 8; color: "#111c11"
                        border.width: 1; border.color: "#00ccff"
                        implicitHeight: rovCol.height + 24

                        ColumnLayout {
                            id: rovCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 10

                            // Header
                            RowLayout {
                                spacing: 8
                                Rectangle { width: 10; height: 10; radius: 5; color: "#00ccff" }
                                Label { text: "ROV — Underwater Drone"; font.pixelSize: 13; font.bold: true; color: "#00ccff" }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: rov && rov.connected ? "Connected" : "Disconnected"
                                    font.pixelSize: 10; color: rov && rov.connected ? "#4caf50" : "#6e6e6e"
                                }
                            }

                            // Fields
                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 10; rowSpacing: 8

                                Label { text: "Vehicle ID:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovSysId
                                    text: settingsPopup.t_rovSysId
                                    Layout.preferredWidth: 70; color: "#00ff41"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 254 }
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fRovSysId.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovSysId = text; settingsPopup.dirty = true }
                                }

                                Label { text: "UDP Port:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovPort
                                    text: settingsPopup.t_rovPort
                                    Layout.preferredWidth: 70; color: "#00ff41"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1024; top: 65535 }
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fRovPort.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovPort = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 1:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovCam1
                                    text: settingsPopup.t_rovCam1
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#00ff41"; font.pixelSize: 11
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fRovCam1.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovCam1 = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 2:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fRovCam2
                                    text: settingsPopup.t_rovCam2
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#00ff41"; font.pixelSize: 11
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fRovCam2.activeFocus ? "#00bcd4" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_rovCam2 = text; settingsPopup.dirty = true }
                                }
                            }
                        }
                    }

                    // ═══ USV ═════════════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true; radius: 8; color: "#111c11"
                        border.width: 1; border.color: "#ffaa00"
                        implicitHeight: usvCol.height + 24

                        ColumnLayout {
                            id: usvCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 10

                            RowLayout {
                                spacing: 8
                                Rectangle { width: 10; height: 10; radius: 5; color: "#ffaa00" }
                                Label { text: "USV — Surface Drone / Boat"; font.pixelSize: 13; font.bold: true; color: "#ffaa00" }
                                Item { Layout.fillWidth: true }
                                Label {
                                    text: usv && usv.connected ? "Connected" : "Disconnected"
                                    font.pixelSize: 10; color: usv && usv.connected ? "#4caf50" : "#6e6e6e"
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 10; rowSpacing: 8

                                Label { text: "Vehicle ID:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvSysId
                                    text: settingsPopup.t_usvSysId
                                    Layout.preferredWidth: 70; color: "#00ff41"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 254 }
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fUsvSysId.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvSysId = text; settingsPopup.dirty = true }
                                }

                                Label { text: "UDP Port:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvPort
                                    text: settingsPopup.t_usvPort
                                    Layout.preferredWidth: 70; color: "#00ff41"; font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    validator: IntValidator { bottom: 1024; top: 65535 }
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fUsvPort.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvPort = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 1:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvCam1
                                    text: settingsPopup.t_usvCam1
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#00ff41"; font.pixelSize: 11
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fUsvCam1.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvCam1 = text; settingsPopup.dirty = true }
                                }

                                Label { text: "Camera 2:"; color: "#44aa44"; font.pixelSize: 12 }
                                TextField {
                                    id: fUsvCam2
                                    text: settingsPopup.t_usvCam2
                                    Layout.columnSpan: 3; Layout.fillWidth: true
                                    color: "#00ff41"; font.pixelSize: 11
                                    background: Rectangle { color: "#1a2a1a"; radius: 4; border.width: 1; border.color: fUsvCam2.activeFocus ? "#ff9800" : "#2a3f55" }
                                    onTextChanged: { settingsPopup.t_usvCam2 = text; settingsPopup.dirty = true }
                                }
                            }
                        }
                    }

                    // ═══ JOYSTICK ════════════════════════════════════════════
                    Rectangle {
                        Layout.fillWidth: true; radius: 8; color: "#111c11"
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
                                font.pixelSize: 11; font.italic: true; color: "#2a5a2a"
                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                            }

                            // Per-joystick config (Repeater)
                            Repeater {
                                model: joystickManager.joysticks

                                Rectangle {
                                    Layout.fillWidth: true; radius: 6; color: "#1a2a1a"
                                    border.width: 1; border.color: "#1a3a1a"
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
                                                font.pixelSize: 12; font.bold: true; color: "#00ff41"
                                            }
                                            Label {
                                                text: "(" + js.axisCount + " axes, " + js.buttonCount + " btns)"
                                                font.pixelSize: 10; color: "#2a5a2a"
                                            }
                                            Item { Layout.fillWidth: true }

                                            // Vehicle assignment
                                            Label { text: "Assign to:"; font.pixelSize: 11; color: "#44aa44" }
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
                                                background: Rectangle { color: "#111c11"; radius: 4; border.width: 1; border.color: "#1a3a1a" }
                                                contentItem: Label { text: jsVehicleCombo.displayText; color: "#00ff41"; font.pixelSize: 11; leftPadding: 6; verticalAlignment: Text.AlignVCenter }
                                            }
                                        }

                                        // ── Axis Mapping ──
                                        Label { text: "AXIS MAPPING"; font.pixelSize: 9; font.bold: true; color: "#2a5a2a" }

                                        GridLayout {
                                            Layout.fillWidth: true; columns: 5; columnSpacing: 6; rowSpacing: 4

                                            // Header
                                            Label { text: "Function"; font.pixelSize: 9; color: "#2a5a2a" }
                                            Label { text: "Axis"; font.pixelSize: 9; color: "#2a5a2a" }
                                            Label { text: "Invert"; font.pixelSize: 9; color: "#2a5a2a" }
                                            Label { text: "Live"; font.pixelSize: 9; color: "#2a5a2a"; Layout.columnSpan: 2 }

                                            // X (Lateral)
                                            Label { text: "X (Lateral)"; font.pixelSize: 11; color: "#44aa44" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapX; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapX = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#111c11"; radius: 3; border.width: 1; border.color: "#1a3a1a" }
                                            }
                                            CheckBox { checked: js.invertX; onToggled: { js.invertX = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#1a2a1a"; border.width: 1; border.color: "#1a3a1a"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#0a0f0a"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisX) * parent.width / 2); x: js.axisX >= 0 ? parent.width/2 : parent.width/2 + js.axisX * parent.width/2; color: "#4caf50"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#2a5a2a" }
                                            }
                                            Label { text: js.axisX.toFixed(2); font.pixelSize: 9; color: "#4caf50"; Layout.preferredWidth: 35 }

                                            // Y (Forward)
                                            Label { text: "Y (Forward)"; font.pixelSize: 11; color: "#44aa44" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapY; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapY = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#111c11"; radius: 3; border.width: 1; border.color: "#1a3a1a" }
                                            }
                                            CheckBox { checked: js.invertY; onToggled: { js.invertY = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#1a2a1a"; border.width: 1; border.color: "#1a3a1a"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#0a0f0a"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisY) * parent.width / 2); x: js.axisY >= 0 ? parent.width/2 : parent.width/2 + js.axisY * parent.width/2; color: "#00ccff"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#2a5a2a" }
                                            }
                                            Label { text: js.axisY.toFixed(2); font.pixelSize: 9; color: "#00ccff"; Layout.preferredWidth: 35 }

                                            // Z (Throttle)
                                            Label { text: "Z (Throttle)"; font.pixelSize: 11; color: "#44aa44" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapZ; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapZ = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#111c11"; radius: 3; border.width: 1; border.color: "#1a3a1a" }
                                            }
                                            CheckBox { checked: js.invertZ; onToggled: { js.invertZ = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#1a2a1a"; border.width: 1; border.color: "#1a3a1a"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#0a0f0a"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisZ) * parent.width / 2); x: js.axisZ >= 0 ? parent.width/2 : parent.width/2 + js.axisZ * parent.width/2; color: "#ffaa00"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#2a5a2a" }
                                            }
                                            Label { text: js.axisZ.toFixed(2); font.pixelSize: 9; color: "#ffaa00"; Layout.preferredWidth: 35 }

                                            // R (Yaw)
                                            Label { text: "R (Yaw)"; font.pixelSize: 11; color: "#44aa44" }
                                            SpinBox { from: 0; to: js.axisCount - 1; value: js.axisMapR; font.pixelSize: 10; implicitWidth: 70; implicitHeight: 28
                                                onValueModified: { js.axisMapR = value; settingsPopup.dirty = true }
                                                background: Rectangle { color: "#111c11"; radius: 3; border.width: 1; border.color: "#1a3a1a" }
                                            }
                                            CheckBox { checked: js.invertR; onToggled: { js.invertR = checked; settingsPopup.dirty = true }
                                                indicator: Rectangle { width: 16; height: 16; radius: 3; color: parent.checked ? "#4caf50" : "#1a2a1a"; border.width: 1; border.color: "#1a3a1a"
                                                    Label { anchors.centerIn: parent; text: parent.parent.checked ? "\u2713" : ""; color: "white"; font.pixelSize: 11 }
                                                }
                                            }
                                            Rectangle { Layout.fillWidth: true; height: 8; color: "#0a0f0a"; radius: 4
                                                Rectangle { height: parent.height; width: Math.max(4, Math.abs(js.axisR) * parent.width / 2); x: js.axisR >= 0 ? parent.width/2 : parent.width/2 + js.axisR * parent.width/2; color: "#ff2020"; radius: 4 }
                                                Rectangle { x: parent.width/2 - 1; width: 2; height: parent.height; color: "#2a5a2a" }
                                            }
                                            Label { text: js.axisR.toFixed(2); font.pixelSize: 9; color: "#ff2020"; Layout.preferredWidth: 35 }
                                        }

                                        // ── Deadzone & Expo ──
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 16

                                            Label { text: "Deadzone:"; font.pixelSize: 11; color: "#44aa44" }
                                            Slider { id: dzSlider; from: 0; to: 0.3; stepSize: 0.01; value: js.deadzone; Layout.preferredWidth: 120
                                                onMoved: { js.deadzone = value; settingsPopup.dirty = true }
                                            }
                                            Label { text: (js.deadzone * 100).toFixed(0) + "%"; font.pixelSize: 10; color: "#00ff41"; Layout.preferredWidth: 30 }

                                            Rectangle { width: 1; height: 16; color: "#1a3a1a" }

                                            Label { text: "Expo:"; font.pixelSize: 11; color: "#44aa44" }
                                            Slider { id: expoSlider; from: 0; to: 1.0; stepSize: 0.05; value: js.expo; Layout.preferredWidth: 120
                                                onMoved: { js.expo = value; settingsPopup.dirty = true }
                                            }
                                            Label { text: (js.expo * 100).toFixed(0) + "%"; font.pixelSize: 10; color: "#00ff41"; Layout.preferredWidth: 30 }
                                        }

                                        // ── Button Bindings ──
                                        Label { text: "BUTTON BINDINGS"; font.pixelSize: 9; font.bold: true; color: "#2a5a2a" }

                                        // Currently pressed indicator
                                        RowLayout {
                                            spacing: 6
                                            Label { text: "Pressed:"; font.pixelSize: 11; color: "#2a5a2a" }
                                            Label {
                                                property int mask: js.pressedButtonsMask
                                                text: {
                                                    if (mask === 0) return "---"
                                                    var btns = []
                                                    for (var i = 0; i < 16; i++) {
                                                        if (mask & (1 << i)) btns.push(i)
                                                    }
                                                    return btns.join(", ")
                                                }
                                                font.pixelSize: 13; font.bold: true; font.family: "JetBrains Mono"
                                                color: mask !== 0 ? "#00d2ff" : "#6e6e6e"
                                            }
                                        }

                                        // Button grid overview
                                        Flow {
                                            Layout.fillWidth: true; spacing: 3
                                            Repeater {
                                                model: Math.min(js.buttonCount, 16)
                                                Rectangle {
                                                    width: 26; height: 20; radius: 3
                                                    color: (js.pressedButtonsMask & (1 << index)) ? "#4caf50" : "#1a2a1a"
                                                    border.width: 1; border.color: (js.pressedButtonsMask & (1 << index)) ? "#4caf50" : "#2a3f55"
                                                    Label {
                                                        anchors.centerIn: parent; text: index
                                                        font.pixelSize: 8; font.family: "JetBrains Mono"
                                                        font.bold: (js.pressedButtonsMask & (1 << index))
                                                        color: (js.pressedButtonsMask & (1 << index)) ? "#1a1a2e" : "#9e9e9e"
                                                    }
                                                }
                                            }
                                        }

                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 4; columnSpacing: 6; rowSpacing: 3

                                            Repeater {
                                                model: Math.min(js.buttonCount, 16)

                                                RowLayout {
                                                    spacing: 4
                                                    Layout.columnSpan: (index % 2 === 0) ? 2 : 2

                                                    // Live indicator (reactive via pressedButtonsMask)
                                                    Rectangle {
                                                        width: 14; height: 14; radius: 3
                                                        color: (js.pressedButtonsMask & (1 << index)) ? "#4caf50" : "#1a2a1a"
                                                        border.width: 1; border.color: "#1a3a1a"
                                                        Label { anchors.centerIn: parent; text: index; font.pixelSize: 7; color: "#44aa44" }
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

                                                        background: Rectangle { color: "#111c11"; radius: 3; border.width: 1; border.color: "#1a3a1a" }
                                                        contentItem: Label { text: parent.displayText; color: "#00ff41"; font.pixelSize: 10; leftPadding: 4; verticalAlignment: Text.AlignVCenter }
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
                        Layout.fillWidth: true; radius: 8; color: "#111c11"
                        border.width: 1; border.color: "#1a3a1a"
                        implicitHeight: statusCol.height + 24

                        ColumnLayout {
                            id: statusCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 8

                            Label { text: "SYSTEM STATUS"; font.pixelSize: 11; font.bold: true; color: "#2a5a2a" }

                            GridLayout {
                                Layout.fillWidth: true; columns: 4; columnSpacing: 16; rowSpacing: 4

                                Label { text: "Vehicles:"; color: "#2a5a2a"; font.pixelSize: 11 }
                                Label { text: vehicleManager.vehicleCount + " connected"; color: "#00ff41"; font.pixelSize: 11; font.bold: true }

                                Label { text: "MAVLink:"; color: "#2a5a2a"; font.pixelSize: 11 }
                                Label { text: mavlinkManager.messagesPerSecond + " msg/s"; color: "#00ff41"; font.pixelSize: 11; font.bold: true }

                                Label { text: "Listening:"; color: "#2a5a2a"; font.pixelSize: 11 }
                                Label {
                                    text: mavlinkManager.listening ? "Yes" : "No"
                                    color: mavlinkManager.listening ? "#4caf50" : "#f44336"; font.pixelSize: 11; font.bold: true
                                }

                                Label { text: "Ports:"; color: "#2a5a2a"; font.pixelSize: 11 }
                                Label { text: mavlinkManager.ports; color: "#00ff41"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                }
            }

            // ══ Bottom Button Bar ════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true; height: 56; color: "#0f1a0f"
                radius: 10
                Rectangle { anchors.top: parent.top; width: parent.width; height: 10; color: parent.color }
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#1a3a1a" }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10

                    Label {
                        text: "RovoControl v0.1.0"
                        font.pixelSize: 10; color: "#2a5a2a"
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
                            text: parent.text; color: "#44aa44"
                            font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#2a3f55" : "transparent"
                            radius: 6; border.width: 1; border.color: "#1a3a1a"
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
                                : "#1a2a1a"
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
                                : "#1a2a1a"
                            radius: 6
                        }
                        implicitWidth: 120; implicitHeight: 36
                    }
                }
            }
        }
    }

    // ─── Vehicle Panel Component ─────────────────────────────────────────────
    component VehiclePanel: Rectangle {
        property var vehicle: null
        property color accentColor: "#00ccff"
        property string vehicleLabel: "VEH"
        property var joystick: null
        property bool isActive: false

        // Dynamic font sizes based on panel dimensions
        property int valFont: Math.max(11, Math.min(18, height * 0.08))
        property int lblFont: Math.max(8, Math.min(11, height * 0.05))
        property int hdrFont: Math.max(10, Math.min(14, height * 0.06))

        color: "#111c11"; radius: 2
        border.width: 1; border.color: vehicle && vehicle.connected ? accentColor : "#1a3a1a"
        opacity: isActive ? 1.0 : 0.7

        RowLayout {
            anchors.fill: parent; anchors.margins: 4; spacing: 4

            // ── Left: Instruments ──
            ColumnLayout {
                Layout.fillHeight: true; spacing: 2

                // Header
                RowLayout {
                    spacing: 4
                    Rectangle { width: 6; height: 6; radius: 3; color: vehicle && vehicle.connected ? "#00ff41" : "#ff2020" }
                    Label { text: vehicle ? vehicle.name : vehicleLabel; font.pixelSize: hdrFont; font.bold: true; font.family: "Consolas"; color: accentColor }
                    Rectangle {
                        width: 40; height: 15; radius: 2
                        color: vehicle && vehicle.armed ? "#ff2020" : "#00aa2a"
                        Label { anchors.centerIn: parent; text: vehicle && vehicle.armed ? "ARM" : "SAFE"; font.pixelSize: 8; font.bold: true; font.family: "Consolas"; color: "white" }
                    }
                    Label { text: vehicle ? vehicle.flightMode : "---"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#44aa44" }
                }

                // Gauges
                RowLayout {
                    Layout.fillHeight: true; spacing: 4

                    AttitudeIndicator {
                        Layout.fillHeight: true; Layout.preferredWidth: height
                        roll: vehicle ? vehicle.roll : 0; pitch: vehicle ? vehicle.pitch : 0
                    }
                    CompassRose {
                        Layout.fillHeight: true; Layout.preferredWidth: height
                        heading: vehicle ? vehicle.heading : 0
                    }
                }
            }

            Rectangle { width: 1; Layout.fillHeight: true; color: "#1a3a1a" }

            // ── Right: Telemetry table (dynamic font) ──
            GridLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.alignment: Qt.AlignVCenter
                columns: 8; columnSpacing: 6; rowSpacing: 2

                Label { text: "HDG"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.heading.toFixed(0) + "\u00B0" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "SPD"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.groundSpeed.toFixed(1) + "m/s" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "DEP"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.depth.toFixed(1) + "m" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "BAT"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.batteryVoltage.toFixed(1) + "V " + (vehicle.batteryPercent >= 0 ? vehicle.batteryPercent + "%" : "") : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: vehicle && vehicle.batteryPercent < 20 ? "#ff2020" : vehicle && vehicle.batteryPercent < 40 ? "#ffaa00" : "#00ff41" }

                Label { text: "ROLL"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.roll.toFixed(1) + "\u00B0" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "PIT"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.pitch.toFixed(1) + "\u00B0" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "YAW"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.yaw.toFixed(1) + "\u00B0" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "CUR"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.batteryCurrent.toFixed(1) + "A" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }

                Label { text: "THR"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.throttle.toFixed(0) + "%" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "ALT"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.altitude.toFixed(1) + "m" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "CLB"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.climbRate.toFixed(1) + "m/s" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: "#00ff41" }
                Label { text: "GPS"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.gpsSatCount + " SAT" : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: vehicle && vehicle.gpsFixType < 2 ? "#ff2020" : "#00ff41" }

                Label { text: "LAT"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.latitude.toFixed(6) : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: accentColor; Layout.columnSpan: 3 }
                Label { text: "LON"; font.pixelSize: lblFont; font.family: "Consolas"; color: "#2a5a2a" }
                Label { text: vehicle ? vehicle.longitude.toFixed(6) : "--"; font.pixelSize: valFont; font.bold: true; font.family: "Consolas"; color: accentColor; Layout.columnSpan: 3 }
            }
        }
    }
}
