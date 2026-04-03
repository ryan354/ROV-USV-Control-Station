pragma Singleton
import QtQuick

QtObject {
    // ─── Background Colors (dark olive/tactical) ───────────────────────────
    readonly property color bgPrimary:   "#0a0f0a"
    readonly property color bgSecondary: "#0f1a0f"
    readonly property color bgTertiary:  "#142014"
    readonly property color bgPanel:     "#111c11"
    readonly property color bgInput:     "#1a2a1a"
    readonly property color bgHover:     "#1f2f1f"

    // ─── Accent Colors ─────────────────────────────────────────────────────
    readonly property color accent:      "#ff2020"
    readonly property color accentHover: "#ff4040"
    readonly property color secondary:   "#00ff41"
    readonly property color secondaryDim:"#00aa2a"

    // ─── Status Colors ──────────────────────────────────────────────────────
    readonly property color success:     "#00ff41"
    readonly property color warning:     "#ffaa00"
    readonly property color danger:      "#ff2020"
    readonly property color info:        "#00aaff"

    // ─── Vehicle Colors ─────────────────────────────────────────────────────
    readonly property color rovColor:    "#00ccff"
    readonly property color usvColor:    "#ffaa00"

    // ─── Text Colors ────────────────────────────────────────────────────────
    readonly property color textPrimary:   "#00ff41"
    readonly property color textSecondary: "#44aa44"
    readonly property color textDim:       "#2a5a2a"
    readonly property color textBright:    "#ffffff"

    // ─── Border ─────────────────────────────────────────────────────────────
    readonly property color border:      "#1a3a1a"
    readonly property color borderLight: "#2a5a2a"
    readonly property int   borderWidth: 1
    readonly property int   borderRadius: 2

    // ─── Typography ─────────────────────────────────────────────────────────
    readonly property string fontFamily:     "Consolas"
    readonly property string monoFamily:     "Consolas"
    readonly property int    fontSizeSmall:  11
    readonly property int    fontSizeNormal: 13
    readonly property int    fontSizeLarge:  16
    readonly property int    fontSizeTitle:  20
    readonly property int    fontSizeHud:    14

    // ─── Spacing ────────────────────────────────────────────────────────────
    readonly property int spacingXs:  4
    readonly property int spacingSm:  8
    readonly property int spacingMd:  12
    readonly property int spacingLg:  16
    readonly property int spacingXl:  24

    // ─── Shadows ────────────────────────────────────────────────────────────
    readonly property color shadowColor: "#40000000"

    // ─── HUD ────────────────────────────────────────────────────────────────
    readonly property color hudBg:     "#cc0a0f0a"
    readonly property color hudText:   "#00ff41"
    readonly property color hudBorder: "#4000ff41"

    // ─── Panel ──────────────────────────────────────────────────────────────
    readonly property int panelHeaderHeight: 32
    readonly property int statusBarHeight:   28
    readonly property int toolbarHeight:     44
}
