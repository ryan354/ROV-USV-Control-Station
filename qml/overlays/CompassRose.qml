import QtQuick
import RovoControl

Canvas {
    id: root

    property real heading: 0

    onHeadingChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width
        var h = height
        var cx = w / 2
        var cy = h / 2
        var r = Math.min(cx, cy) - 4

        ctx.clearRect(0, 0, w, h)

        // ── Background ──
        var bgGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, r)
        bgGrad.addColorStop(0, "#1a2a3a")
        bgGrad.addColorStop(0.8, "#0f1a2a")
        bgGrad.addColorStop(1, "#0a1020")
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.fillStyle = bgGrad
        ctx.fill()

        // Outer ring
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.strokeStyle = "#334455"
        ctx.lineWidth = 2
        ctx.stroke()

        ctx.save()
        ctx.translate(cx, cy)
        ctx.rotate(-heading * Math.PI / 180)

        var fontSize = Math.max(9, r * 0.15)
        var smallFont = Math.max(7, r * 0.1)

        // ── Degree ticks ──
        for (var d = 0; d < 360; d += 5) {
            ctx.save()
            ctx.rotate(d * Math.PI / 180)
            var tickLen, tickWidth, tickColor
            if (d % 90 === 0) {
                tickLen = r * 0.14; tickWidth = 2; tickColor = "#ffffff"
            } else if (d % 30 === 0) {
                tickLen = r * 0.1; tickWidth = 1.5; tickColor = "#cccccc"
            } else if (d % 10 === 0) {
                tickLen = r * 0.07; tickWidth = 1; tickColor = "#888888"
            } else {
                tickLen = r * 0.04; tickWidth = 0.7; tickColor = "#555555"
            }
            ctx.beginPath()
            ctx.moveTo(0, -r + 2)
            ctx.lineTo(0, -r + 2 + tickLen)
            ctx.strokeStyle = tickColor
            ctx.lineWidth = tickWidth
            ctx.stroke()
            ctx.restore()
        }

        // ── Degree numbers (every 30) ──
        ctx.font = smallFont + "px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillStyle = "#999999"

        var nums = [30, 60, 120, 150, 210, 240, 300, 330]
        for (var n = 0; n < nums.length; n++) {
            ctx.save()
            ctx.rotate(nums[n] * Math.PI / 180)
            ctx.translate(0, -r + r * 0.22)
            ctx.rotate(-(nums[n] - heading) * Math.PI / 180)
            ctx.fillText(nums[n].toString(), 0, 0)
            ctx.restore()
        }

        // ── Cardinal labels ──
        var cards = [
            {deg: 0,   text: "N", color: "#ff3333", sz: fontSize * 1.3},
            {deg: 90,  text: "E", color: "#dddddd", sz: fontSize},
            {deg: 180, text: "S", color: "#dddddd", sz: fontSize},
            {deg: 270, text: "W", color: "#dddddd", sz: fontSize}
        ]
        for (var c = 0; c < cards.length; c++) {
            ctx.save()
            ctx.rotate(cards[c].deg * Math.PI / 180)
            ctx.translate(0, -r * 0.68)
            ctx.rotate(-(cards[c].deg - heading) * Math.PI / 180)
            ctx.font = "bold " + cards[c].sz + "px Consolas"
            ctx.fillStyle = cards[c].color
            ctx.fillText(cards[c].text, 0, 0)
            ctx.restore()
        }

        ctx.restore()

        // ── Single compass needle (fixed, points up = vehicle heading) ──
        ctx.save()
        ctx.translate(cx, cy)

        var needleLen = r * 0.55
        var needleW = r * 0.13

        // Shadow
        ctx.save()
        ctx.translate(1.5, 1.5)
        ctx.beginPath()
        ctx.moveTo(0, -needleLen)
        ctx.lineTo(needleW, 0)
        ctx.lineTo(0, needleLen)
        ctx.lineTo(-needleW, 0)
        ctx.closePath()
        ctx.fillStyle = "rgba(0,0,0,0.4)"
        ctx.fill()
        ctx.restore()

        // North half (red)
        ctx.beginPath()
        ctx.moveTo(0, -needleLen)
        ctx.lineTo(needleW, 0)
        ctx.lineTo(0, -needleLen * 0.15)
        ctx.closePath()
        ctx.fillStyle = "#cc2222"
        ctx.fill()

        ctx.beginPath()
        ctx.moveTo(0, -needleLen)
        ctx.lineTo(-needleW, 0)
        ctx.lineTo(0, -needleLen * 0.15)
        ctx.closePath()
        ctx.fillStyle = "#ee3333"
        ctx.fill()

        // White circle at top of north
        ctx.beginPath()
        ctx.arc(0, -needleLen * 0.55, needleW * 0.55, 0, Math.PI * 2)
        ctx.fillStyle = "#ffffff"
        ctx.fill()
        ctx.beginPath()
        ctx.arc(0, -needleLen * 0.55, needleW * 0.35, 0, Math.PI * 2)
        ctx.fillStyle = "#cc2222"
        ctx.fill()

        // South half (silver/white)
        ctx.beginPath()
        ctx.moveTo(0, needleLen)
        ctx.lineTo(needleW, 0)
        ctx.lineTo(0, needleLen * 0.15)
        ctx.closePath()
        ctx.fillStyle = "#aaaaaa"
        ctx.fill()

        ctx.beginPath()
        ctx.moveTo(0, needleLen)
        ctx.lineTo(-needleW, 0)
        ctx.lineTo(0, needleLen * 0.15)
        ctx.closePath()
        ctx.fillStyle = "#cccccc"
        ctx.fill()

        // Center pivot
        ctx.beginPath()
        ctx.arc(0, 0, r * 0.06, 0, Math.PI * 2)
        ctx.fillStyle = "#444444"
        ctx.fill()
        ctx.strokeStyle = "#666666"
        ctx.lineWidth = 1
        ctx.stroke()

        ctx.restore()

        // ── Fixed heading marker at top ──
        ctx.beginPath()
        ctx.moveTo(cx, cy - r + 1)
        ctx.lineTo(cx - 5, cy - r - 8)
        ctx.lineTo(cx + 5, cy - r - 8)
        ctx.closePath()
        ctx.fillStyle = "#00ff41"
        ctx.fill()

        // ── Heading readout ──
        var boxW = 48, boxH = 18
        ctx.fillStyle = "rgba(0,0,0,0.8)"
        ctx.fillRect(cx - boxW/2, cy + r - boxH - 3, boxW, boxH)
        ctx.strokeStyle = "#334455"
        ctx.lineWidth = 1
        ctx.strokeRect(cx - boxW/2, cy + r - boxH - 3, boxW, boxH)
        ctx.font = "bold " + Math.max(10, r * 0.12) + "px Consolas"
        ctx.fillStyle = "#00ff41"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(heading.toFixed(0) + "\u00B0", cx, cy + r - boxH/2 - 3)
    }
}
