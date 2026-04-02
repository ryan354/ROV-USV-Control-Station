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

        // Background circle
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.fillStyle = Theme.hudBg
        ctx.fill()
        ctx.strokeStyle = Theme.hudBorder
        ctx.lineWidth = 1
        ctx.stroke()

        ctx.save()
        ctx.translate(cx, cy)
        ctx.rotate(-heading * Math.PI / 180)

        // Cardinal marks
        var cardinals = ["N", "E", "S", "W"]
        var angles = [0, 90, 180, 270]
        ctx.font = "bold 10px " + Theme.monoFamily
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"

        for (var i = 0; i < 4; i++) {
            ctx.save()
            ctx.rotate(angles[i] * Math.PI / 180)

            // Tick mark
            ctx.beginPath()
            ctx.moveTo(0, -r + 2)
            ctx.lineTo(0, -r + 8)
            ctx.strokeStyle = Theme.hudText
            ctx.lineWidth = 2
            ctx.stroke()

            // Label
            ctx.save()
            ctx.translate(0, -r + 16)
            ctx.rotate(-(-heading + angles[i]) * Math.PI / 180)
            ctx.fillStyle = cardinals[i] === "N" ? Theme.accent : Theme.hudText
            ctx.fillText(cardinals[i], 0, 0)
            ctx.restore()

            ctx.restore()
        }

        // Minor ticks every 30 degrees
        for (var j = 0; j < 12; j++) {
            if (j % 3 !== 0) {
                ctx.save()
                ctx.rotate(j * 30 * Math.PI / 180)
                ctx.beginPath()
                ctx.moveTo(0, -r + 2)
                ctx.lineTo(0, -r + 5)
                ctx.strokeStyle = Theme.textDim
                ctx.lineWidth = 1
                ctx.stroke()
                ctx.restore()
            }
        }

        ctx.restore()

        // Center triangle (always pointing up = vehicle heading)
        ctx.beginPath()
        ctx.moveTo(cx, cy - 8)
        ctx.lineTo(cx - 5, cy + 4)
        ctx.lineTo(cx + 5, cy + 4)
        ctx.closePath()
        ctx.fillStyle = Theme.accent
        ctx.fill()
    }
}
