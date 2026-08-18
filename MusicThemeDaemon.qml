import QtQuick
import qs.Common
import qs.Services

Item {
    id: root

    property var pluginService: null
    property string pluginId: "musicTheme"

    property int debounceMs: pluginService ? Number(pluginService.loadPluginData(pluginId, "debounceMs", 250)) : 250
    property string schemeSetting: pluginService ? pluginService.loadPluginData(pluginId, "matugenScheme", "system") : "system"

    property string _lastAppliedHex: ""
    readonly property bool _wallpaperThemeActive: _lastAppliedHex === ""

    function _setDesired(kind, value) {
        Theme.setDesiredTheme(kind, value, root._isLight(), root._iconTheme(), root._matugenType());
    }

    function _colorToHex(c) {
        const r = Math.round(c.r * 255).toString(16).padStart(2, "0");
        const g = Math.round(c.g * 255).toString(16).padStart(2, "0");
        const b = Math.round(c.b * 255).toString(16).padStart(2, "0");
        return "#" + r + g + b;
    }

    function _iconTheme() {
        return (typeof SettingsData !== "undefined" && SettingsData.iconTheme) ? SettingsData.iconTheme : "System Default";
    }

    function _matugenType() {
        if (root.schemeSetting && root.schemeSetting !== "system")
            return root.schemeSetting;
        return (typeof SettingsData !== "undefined" && SettingsData.matugenScheme) ? SettingsData.matugenScheme : "scheme-tonal-spot";
    }

    function _isLight() {
        return typeof SessionData !== "undefined" ? SessionData.isLightMode : false;
    }

    function applyAccent() {
        if (!MprisController.activePlayer || !MprisController.activePlayer.isPlaying)
            return;
        if (!MediaAccentService.hasAccent)
            return;

        const hex = root._colorToHex(MediaAccentService.accent);
        if (hex === root._lastAppliedHex)
            return;

        root._lastAppliedHex = hex;
        root._setDesired("hex", hex);
    }

    function restoreWallpaperTheme() {
        if (root._wallpaperThemeActive)
            return;
        if (!Theme.rawWallpaperPath)
            return;

        root._lastAppliedHex = "";

        const kind = Theme.rawWallpaperPath.startsWith("#") ? "hex" : "image";
        root._setDesired(kind, Theme.rawWallpaperPath);
    }

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: root.applyAccent()
    }

    Connections {
        target: MediaAccentService
        function onAccentChanged() {
            debounceTimer.restart();
        }
    }

    Connections {
        target: MprisController
        function onActivePlayerChanged() {
            debounceTimer.restart();
        }
    }

    Connections {
        target: MprisController.activePlayer
        ignoreUnknownSignals: true
        function onIsPlayingChanged() {
            if (MprisController.activePlayer && MprisController.activePlayer.isPlaying)
                debounceTimer.restart();
            else
                root.restoreWallpaperTheme();
        }
    }

    Connections {
        target: root.pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== root.pluginId)
                return;
            const previousScheme = root.schemeSetting;
            root.debounceMs = Number(root.pluginService.loadPluginData(root.pluginId, "debounceMs", 250));
            root.schemeSetting = root.pluginService.loadPluginData(root.pluginId, "matugenScheme", "system");
            if (root.schemeSetting !== previousScheme) {
                root._lastAppliedHex = "";
                root.applyAccent();
            }
        }
    }

    Component.onCompleted: {
        console.info("MusicTheme: daemon started");
        root.applyAccent();
    }

    Component.onDestruction: {
        restoreWallpaperTheme();
    }
}
