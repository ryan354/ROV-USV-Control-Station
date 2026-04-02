pragma Singleton
import QtQuick

QtObject {
    // ─── Background Colors ──────────────────────────────────────────────────
    readonly property color bgPrimary:   "#1a1a2e"
    readonly property color bgSecondary: "#16213e"
    readonly property color bgTertiary:  "#0f3460"
    readonly property color bgPanel:     "#1e2a3a"
    readonly property color bgInput:     "#243447"
    readonly property color bgHover:     "#2a3f55"

    // ─── Accent Colors ─────────────────────────────────────────────────────
    readonly property color accent:      "#e94560"
    readonly property color accentHover: "#ff5a75"
    readonly property color secondary:   "#00d2ff"
    readonly property color secondaryDim:"#0099bb"

    // ─── Status Colors ──────────────────────────────────────────────────────
    readonly property color success:     "#4caf50"
    readonly property color warning:     "#ff9800"
    readonly property color danger:      "#f44336"
    readonly property color info:        "#2196f3"

    // ─── Vehicle Colors ─────────────────────────────────────────────────────
    readonly property color rovColor:    "#00bcd4"   // Cyan for ROV
    readonly property color usvColor:    "#ff9800"   // Orange for USV

    // ─── Text Colors ────────────────────────────────────────────────────────
    readonly property color textPrimary:   "#e0e0e0"
    readonly property color textSecondary: "#9e9e9e"
    readonly property color textDim:       "#6e6e6e"
    readonly property color textBright:    "#ffffff"

    // ─── Border ─────────────────────────────────────────────────────────────
    readonly property color border:      "#2a3f55"
    readonly property color borderLight: "#3a5570"
    readonly property int   borderWidth: 1
    readonly property int   borderRadius: 6

    // ─── Typography ─────────────────────────────────────────────────────────
    readonly property string fontFamily:     "Inter"
    readonly property string monoFamily:     "JetBrains Mono"
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
    readonly property color hudBg:     "#80000000"
    readonly property color hudText:   "#00ff88"
    readonly property color hudBorder: "#4000ff88"

    // ─── Panel ──────────────────────────────────────────────────────────────
    readonly property int panelHeaderHeight: 32
    readonly property int statusBarHeight:   28
    readonly property int toolbarHeight:     44
}
