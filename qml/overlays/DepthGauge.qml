import QtQuick
import RovoControl

Item {
    id: root

    property real depth: 0
    property real maxDepth: 100

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height

            ctx.clearRect(0, 0, w, h)

            // Background bar
            ctx.fillStyle = Theme.hudBg
            ctx.fillRect(0, 0, w, h)
            ctx.strokeStyle = Theme.hudBorder
            ctx.lineWidth = 1
            ctx.strokeRect(0, 0, w, h)

            // Fill bar based on depth
            var fillRatio = Math.min(root.depth / root.maxDepth, 1.0)
            var fillH = h * fillRatio

            // Gradient from cyan (shallow) to blue (deep)
            var gradient = ctx.createLinearGradient(0, 0, 0, h)
            gradient.addColorStop(0, "#00d2ff")
            gradient.addColorStop(1, "#0f3460")
            ctx.fillStyle = gradient
            ctx.fillRect(2, 2, w - 4, fillH - 2)

            // Depth marks
            ctx.font = "9px " + Theme.monoFamily
            ctx.fillStyle = Theme.textSecondary
            ctx.textAlign = "center"

            var marks = 5
            for (var i = 0; i <= marks; i++) {
                var y = (h / marks) * i
                var depthVal = (root.maxDepth / marks) * i

                // Tick line
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(6, y)
                ctx.strokeStyle = Theme.textDim
                ctx.lineWidth = 1
                ctx.stroke()
            }

            // Current depth indicator
            var depthY = h * fillRatio
            ctx.beginPath()
            ctx.moveTo(w, depthY)
            ctx.lineTo(w - 8, depthY - 5)
            ctx.lineTo(w - 8, depthY + 5)
            ctx.closePath()
            ctx.fillStyle = Theme.accent
            ctx.fill()

            // Depth text
            ctx.font = "bold 12px " + Theme.monoFamily
            ctx.fillStyle = Theme.hudText
            ctx.textAlign = "center"
            ctx.fillText(root.depth.toFixed(1), w / 2, h + 14)
            ctx.font = "9px " + Theme.monoFamily
            ctx.fillText("m", w / 2, h + 24)
        }
    }

    onDepthChanged: canvas.requestPaint()
    onMaxDepthChanged: canvas.requestPaint()
}
