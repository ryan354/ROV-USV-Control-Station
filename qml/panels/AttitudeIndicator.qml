import QtQuick
import RovoControl

Canvas {
    id: root

    property real roll: 0
    property real pitch: 0

    onRollChanged: requestPaint()
    onPitchChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width
        var h = height
        var cx = w / 2
        var cy = h / 2
        var r = Math.min(cx, cy) - 4

        ctx.clearRect(0, 0, w, h)

        // Clip to circle
        ctx.save()
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.clip()

        ctx.translate(cx, cy)
        ctx.rotate(-roll * Math.PI / 180)

        var ppd = r / 25
        var pitchPx = pitch * ppd

        // Sky
        var skyGrad = ctx.createLinearGradient(0, -r * 3 + pitchPx, 0, pitchPx)
        skyGrad.addColorStop(0, "#0a2a0a")
        skyGrad.addColorStop(0.5, "#0f3f0f")
        skyGrad.addColorStop(1, "#1a5a1a")
        ctx.fillStyle = skyGrad
        ctx.fillRect(-r * 3, -r * 3 + pitchPx, r * 6, r * 3)

        // Ground
        var gndGrad = ctx.createLinearGradient(0, pitchPx, 0, r * 3 + pitchPx)
        gndGrad.addColorStop(0, "#2a1a0a")
        gndGrad.addColorStop(0.4, "#1a0f05")
        gndGrad.addColorStop(1, "#0a0500")
        ctx.fillStyle = gndGrad
        ctx.fillRect(-r * 3, pitchPx, r * 6, r * 3)

        // Horizon line
        ctx.beginPath()
        ctx.moveTo(-r * 3, pitchPx)
        ctx.lineTo(r * 3, pitchPx)
        ctx.strokeStyle = "#00ff41"
        ctx.lineWidth = 2
        ctx.stroke()

        // Pitch ladder
        ctx.fillStyle = "#00ff41"
        ctx.font = Math.max(8, r * 0.1) + "px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"

        for (var deg = -40; deg <= 40; deg += 5) {
            if (deg === 0) continue
            var y = pitchPx - deg * ppd
            var isMain = (deg % 10 === 0)
            var lineW = isMain ? r * 0.3 : r * 0.12

            ctx.beginPath()
            if (!isMain) {
                ctx.setLineDash([3, 3])
                ctx.moveTo(-lineW, y)
                ctx.lineTo(lineW, y)
            } else {
                ctx.setLineDash([])
                ctx.moveTo(-lineW, y)
                ctx.lineTo(lineW, y)
                var tickDir = deg > 0 ? 1 : -1
                ctx.moveTo(-lineW, y)
                ctx.lineTo(-lineW, y + tickDir * r * 0.04)
                ctx.moveTo(lineW, y)
                ctx.lineTo(lineW, y + tickDir * r * 0.04)
            }
            ctx.strokeStyle = "rgba(0, 255, 65, 0.6)"
            ctx.lineWidth = isMain ? 1.5 : 1
            ctx.stroke()
            ctx.setLineDash([])

            if (isMain) {
                ctx.fillText(Math.abs(deg).toString(), -lineW - r * 0.1, y)
                ctx.fillText(Math.abs(deg).toString(), lineW + r * 0.1, y)
            }
        }

        ctx.restore()

        // Roll arc
        ctx.save()
        ctx.translate(cx, cy)

        var arcR = r - 6
        ctx.beginPath()
        ctx.arc(0, 0, arcR, -Math.PI * 5/6, -Math.PI / 6)
        ctx.strokeStyle = "rgba(0, 255, 65, 0.2)"
        ctx.lineWidth = 1.5
        ctx.stroke()

        // Roll ticks
        var rollTicks = [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]
        for (var t = 0; t < rollTicks.length; t++) {
            var tickAngle = (-90 + rollTicks[t]) * Math.PI / 180
            var isLong = (rollTicks[t] % 30 === 0)
            var inner = isLong ? arcR - 10 : arcR - 6
            ctx.beginPath()
            ctx.moveTo(Math.cos(tickAngle) * arcR, Math.sin(tickAngle) * arcR)
            ctx.lineTo(Math.cos(tickAngle) * inner, Math.sin(tickAngle) * inner)
            ctx.strokeStyle = rollTicks[t] === 0 ? "#00ff41" : "rgba(0,255,65,0.5)"
            ctx.lineWidth = isLong ? 2 : 1
            ctx.stroke()
        }

        // Fixed reference triangle
        ctx.beginPath()
        ctx.moveTo(0, -arcR)
        ctx.lineTo(-5, -arcR - 8)
        ctx.lineTo(5, -arcR - 8)
        ctx.closePath()
        ctx.fillStyle = "#00ff41"
        ctx.fill()

        // Roll indicator triangle
        ctx.rotate(-roll * Math.PI / 180)
        ctx.beginPath()
        ctx.moveTo(0, -arcR + 1)
        ctx.lineTo(-5, -arcR + 9)
        ctx.lineTo(5, -arcR + 9)
        ctx.closePath()
        ctx.fillStyle = "#ffaa00"
        ctx.fill()

        ctx.restore()

        // Aircraft symbol (fixed)
        ctx.save()
        ctx.translate(cx, cy)
        ctx.strokeStyle = "#ffaa00"
        ctx.lineWidth = 3
        ctx.lineCap = "round"

        // Left wing
        ctx.beginPath()
        ctx.moveTo(-r * 0.45, 0)
        ctx.lineTo(-r * 0.15, 0)
        ctx.lineTo(-r * 0.15, r * 0.05)
        ctx.stroke()

        // Right wing
        ctx.beginPath()
        ctx.moveTo(r * 0.45, 0)
        ctx.lineTo(r * 0.15, 0)
        ctx.lineTo(r * 0.15, r * 0.05)
        ctx.stroke()

        // Center dot
        ctx.fillStyle = "#ffaa00"
        ctx.fillRect(-3, -3, 6, 6)
        ctx.restore()

        // Outer ring
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.strokeStyle = "#334433"
        ctx.lineWidth = 2
        ctx.stroke()

        // Readouts
        ctx.font = "bold " + Math.max(8, r * 0.1) + "px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"

        // Pitch readout
        ctx.fillStyle = "rgba(0,0,0,0.7)"
        ctx.fillRect(cx - 28, cy + r - 16, 56, 14)
        ctx.fillStyle = "#00ff41"
        ctx.fillText("P " + pitch.toFixed(1) + "\u00B0", cx, cy + r - 9)

        // Roll readout
        ctx.fillStyle = "rgba(0,0,0,0.7)"
        ctx.fillRect(cx - 28, cy - r + 2, 56, 14)
        ctx.fillStyle = "#00ff41"
        ctx.fillText("R " + roll.toFixed(1) + "\u00B0", cx, cy - r + 9)
    }
}
