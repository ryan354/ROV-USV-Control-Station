import QtQuick
import RovoControl

Canvas {
    id: root

    property real roll: 0    // degrees
    property real pitch: 0   // degrees

    onRollChanged: requestPaint()
    onPitchChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width
        var h = height
        var cx = w / 2
        var cy = h / 2
        var r = Math.min(cx, cy) - 2

        ctx.clearRect(0, 0, w, h)

        ctx.save()

        // Clip to circle
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.clip()

        // Translate and rotate for roll
        ctx.translate(cx, cy)
        ctx.rotate(-roll * Math.PI / 180)

        // Pitch offset (10 pixels per degree, clamped)
        var pitchOffset = Math.max(-r, Math.min(r, pitch * 3))

        // Sky (upper half)
        ctx.fillStyle = "#1a5276"
        ctx.fillRect(-r * 2, -r * 2 + pitchOffset, r * 4, r * 2)

        // Ground (lower half)
        ctx.fillStyle = "#784212"
        ctx.fillRect(-r * 2, pitchOffset, r * 4, r * 2)

        // Horizon line
        ctx.beginPath()
        ctx.moveTo(-r * 2, pitchOffset)
        ctx.lineTo(r * 2, pitchOffset)
        ctx.strokeStyle = "#ffffff"
        ctx.lineWidth = 1.5
        ctx.stroke()

        // Pitch lines
        ctx.font = "9px " + Theme.monoFamily
        ctx.fillStyle = "#ffffff"
        ctx.textAlign = "right"

        for (var deg = -30; deg <= 30; deg += 10) {
            if (deg === 0) continue
            var y = pitchOffset - deg * 3
            var lineW = Math.abs(deg) % 20 === 0 ? 30 : 15

            ctx.beginPath()
            ctx.moveTo(-lineW, y)
            ctx.lineTo(lineW, y)
            ctx.strokeStyle = "rgba(255,255,255,0.5)"
            ctx.lineWidth = 1
            ctx.stroke()

            if (Math.abs(deg) % 20 === 0) {
                ctx.fillText(Math.abs(deg).toString(), -lineW - 4, y + 3)
            }
        }

        ctx.restore()

        // Fixed aircraft symbol (center cross)
        ctx.strokeStyle = Theme.accent
        ctx.lineWidth = 2.5

        // Left wing
        ctx.beginPath()
        ctx.moveTo(cx - r * 0.4, cy)
        ctx.lineTo(cx - r * 0.15, cy)
        ctx.stroke()

        // Right wing
        ctx.beginPath()
        ctx.moveTo(cx + r * 0.15, cy)
        ctx.lineTo(cx + r * 0.4, cy)
        ctx.stroke()

        // Center dot
        ctx.beginPath()
        ctx.arc(cx, cy, 3, 0, Math.PI * 2)
        ctx.fillStyle = Theme.accent
        ctx.fill()

        // Roll indicator arc at top
        ctx.save()
        ctx.translate(cx, cy)

        ctx.beginPath()
        ctx.arc(0, 0, r - 2, -Math.PI * 5/6, -Math.PI * 1/6)
        ctx.strokeStyle = "rgba(255,255,255,0.3)"
        ctx.lineWidth = 1
        ctx.stroke()

        // Roll triangle
        ctx.rotate(-roll * Math.PI / 180)
        ctx.beginPath()
        ctx.moveTo(0, -r + 2)
        ctx.lineTo(-5, -r + 10)
        ctx.lineTo(5, -r + 10)
        ctx.closePath()
        ctx.fillStyle = "#ffffff"
        ctx.fill()

        ctx.restore()

        // Outer ring
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.strokeStyle = Theme.hudBorder
        ctx.lineWidth = 2
        ctx.stroke()
    }
}
