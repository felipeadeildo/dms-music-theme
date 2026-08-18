import QtQuick
import qs.Common
import qs.Services

Item {
    id: root

    property var pluginService: null
    property string pluginId: "musicTheme"

    property bool enabled: pluginService ? pluginService.loadPluginData(pluginId, "enabled", true) : true
    property int debounceMs: pluginService ? Number(pluginService.loadPluginData(pluginId, "debounceMs", 250)) : 250
    property string schemeSetting: pluginService ? pluginService.loadPluginData(pluginId, "matugenScheme", "system") : "system"

    property string _lastAppliedHex: ""
    property bool _wallpaperThemeActive: true

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
        if (!root.enabled)
            return;
        if (!MprisController.activePlayer || !MprisController.activePlayer.isPlaying)
            return;
        if (!MediaAccentService.hasAccent)
            return;

        const hex = root._colorToHex(MediaAccentService.accent);
        if (hex === root._lastAppliedHex)
            return;

        root._lastAppliedHex = hex;
        root._wallpaperThemeActive = false;
        Theme.setDesiredTheme("hex", hex, root._isLight(), root._iconTheme(), root._matugenType());
    }

    function restoreWallpaperTheme() {
        if (root._wallpaperThemeActive)
            return;
        if (!Theme.rawWallpaperPath)
            return;

        root._wallpaperThemeActive = true;
        root._lastAppliedHex = "";

        const kind = Theme.rawWallpaperPath.startsWith("#") ? "hex" : "image";
        Theme.setDesiredTheme(kind, Theme.rawWallpaperPath, root._isLight(), root._iconTheme(), root._matugenType());
    }

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        repeat: false
        onTriggered: root.applyAccent()
    }

    Timer {
        id: stopWatchTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            const playing = MprisController.activePlayer && MprisController.activePlayer.isPlaying;
            if (!playing)
                root.restoreWallpaperTheme();
        }
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
            root.applyAccent();
        }
    }

    Connections {
        target: root.pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== root.pluginId)
                return;
            const wasEnabled = root.enabled;
            const previousScheme = root.schemeSetting;
            root.enabled = root.pluginService.loadPluginData(root.pluginId, "enabled", true);
            root.debounceMs = Number(root.pluginService.loadPluginData(root.pluginId, "debounceMs", 250));
            root.schemeSetting = root.pluginService.loadPluginData(root.pluginId, "matugenScheme", "system");
            if (!root.enabled) {
                root.restoreWallpaperTheme();
            } else if (!wasEnabled || root.schemeSetting !== previousScheme) {
                root._lastAppliedHex = "";
                root.applyAccent();
            }
        }
    }

    Component.onCompleted: {
        console.info("MusicTheme: daemon started, enabled =", root.enabled);
        if (root.enabled)
            root.applyAccent();
    }

    Component.onDestruction: {
        restoreWallpaperTheme();
    }
}
