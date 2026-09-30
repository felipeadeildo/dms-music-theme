import QtQuick
import qs.Common
import qs.Services

// Reseeds the dynamic theme from the album art accent while a track plays and
// hands the theme back to DMS when it stops.
Item {
    id: root

    property var pluginService: null
    property string pluginId: "musicTheme"

    property int debounceMs: 250
    property string paletteSetting: "system"

    // Last request sent to matugen; empty while DMS owns the theme.
    property string appliedHex: ""
    property string appliedScheme: ""

    readonly property var player: MprisController.activePlayer
    readonly property bool active: requirements.met && MediaAccentService.hasAccent && !!player && player.isPlaying

    readonly property string wantedHex: active ? toHex(MediaAccentService.accent) : ""
    readonly property string wantedScheme: paletteSetting !== "system" ? paletteSetting : (SettingsData.matugenScheme || "scheme-tonal-spot")
    // Seed of the palette on screen. When DMS regenerates on its own (wallpaper,
    // light mode, scheme) this stops matching wantedHex and the accent goes back on.
    readonly property string shownHex: String(Theme.getMatugenColor("source_color", "")).toLowerCase()

    onWantedHexChanged: syncTimer.restart()
    onWantedSchemeChanged: syncTimer.restart()
    onShownHexChanged: syncTimer.restart()

    function toHex(color) {
        const channel = value => Math.round(value * 255).toString(16).padStart(2, "0");
        return "#" + channel(color.r) + channel(color.g) + channel(color.b);
    }

    function sync() {
        if (!wantedHex) {
            if (appliedHex)
                restore();
            return;
        }

        const sent = appliedHex === wantedHex && appliedScheme === wantedScheme;
        if (sent && (shownHex === wantedHex || Theme.workerRunning))
            return;

        appliedHex = wantedHex;
        appliedScheme = wantedScheme;
        Theme.setDesiredTheme("hex", wantedHex, SessionData.isLightMode, SettingsData.iconTheme || "System Default", wantedScheme);
    }

    function restore() {
        appliedHex = "";
        appliedScheme = "";
        Theme.generateSystemThemesFromCurrentTheme();
    }

    function loadSettings() {
        if (!pluginService)
            return;
        debounceMs = Number(pluginService.loadPluginData(pluginId, "debounceMs", 250));
        paletteSetting = pluginService.loadPluginData(pluginId, "matugenScheme", "system");
    }

    Requirements {
        id: requirements
    }

    Timer {
        id: syncTimer
        interval: root.debounceMs
        onTriggered: root.sync()
    }

    Connections {
        target: root.pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                root.loadSettings();
        }
    }

    onPluginServiceChanged: loadSettings()

    Component.onCompleted: {
        loadSettings();
        syncTimer.restart();
    }

    Component.onDestruction: {
        if (appliedHex)
            restore();
    }
}
