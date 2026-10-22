import QtQuick
import Quickshell
import qs.Common
import qs.Services

// Reseeds the Dynamic theme from the album art of the playing track, and hands
// the theme back to DMS once playback has been stopped for the hold time.
Scope {
    id: root

    property var pluginService: null
    property string pluginId: "musicTheme"

    readonly property var log: Log.scoped("MusicTheme")

    // loadSettings() fills these from the plugin data.
    property int debounceMs: 250
    // How long the album theme outlives a pause. -1 keeps it until the player closes.
    property int holdMs: 30000

    // Our request, from the moment it is sent until DMS owns the theme again.
    property string appliedHex: ""
    property string appliedScheme: ""
    // When the hold on a stopped track ends, in ms since the epoch. -1 holds
    // until the player closes, 0 means no hold.
    property double holdUntil: 0
    // Set when the previous session went down with its seed on screen.
    property bool recovered: false

    // Seed of the palette on screen. When DMS regenerates on its own (wallpaper,
    // light mode, scheme) this stops matching appliedHex and ours goes back on.
    readonly property string shownHex: String(Theme.getMatugenColor("source_color", "")).toLowerCase()

    // Covers load after the track changes; this long without art is not a stop.
    readonly property int artGapMs: 3000

    // Joins every input sync() reads, so any change schedules one sync.
    readonly property string inputs: [music.met, music.playing, !!music.player, music.seed, music.scheme, music.schemeFor(appliedHex), shownHex].join("|")

    onInputsChanged: syncTimer.restart()
    onHoldMsChanged: {
        endHold();
        syncTimer.restart();
    }

    function sync() {
        if (music.live) {
            recovered = false;
            endHold();
            apply(music.seed, music.scheme);
            return;
        }
        if (!appliedHex)
            return;

        // A seed left over from the previous session is stale: never hold it.
        const hold = recovered ? 0 : holdTime();
        recovered = false;
        if (hold === 0) {
            restore();
            return;
        }
        if (holdUntil === 0)
            startHold(hold);
        // Keep ours on screen through DMS's own regenerations while holding.
        apply(appliedHex, music.schemeFor(appliedHex));
    }

    // The hold in ms. 0 restores now, -1 holds until the player closes.
    function holdTime() {
        if (!music.met || !music.player)
            return 0;
        if (holdMs < 0)
            return -1;
        return music.playing ? Math.max(holdMs, artGapMs) : holdMs;
    }

    function apply(hex, scheme) {
        const sent = appliedHex === hex && appliedScheme === scheme;
        if (sent && (shownHex === hex || Theme.workerRunning))
            return;

        log.info("Theming from album art", hex, scheme);
        appliedHex = hex;
        appliedScheme = scheme;
        saveApplied();
        // DMS queues the request while its worker runs and skips it when the
        // inputs match the last run.
        Theme.setDesiredTheme("hex", hex, SessionData.isLightMode, SettingsData.iconTheme || "System Default", scheme);
    }

    function restore() {
        log.info("Handing the theme back to DMS");
        endHold();
        appliedHex = "";
        appliedScheme = "";
        saveApplied();
        Theme.generateSystemThemesFromCurrentTheme();
    }

    function startHold(ms) {
        holdUntil = ms < 0 ? -1 : Date.now() + ms;
        if (ms > 0) {
            holdTimer.interval = ms;
            holdTimer.restart();
        }
    }

    function endHold() {
        holdUntil = 0;
        holdTimer.stop();
    }

    function saveApplied() {
        pluginService?.savePluginState(pluginId, "appliedHex", appliedHex);
    }

    // The settings page reads this.
    function publish() {
        pluginService?.setGlobalVar(pluginId, "status", {
            "running": true,
            "hex": appliedHex,
            "scheme": appliedScheme,
            "holdUntil": holdUntil
        });
    }

    onAppliedHexChanged: publish()
    onAppliedSchemeChanged: publish()
    onHoldUntilChanged: publish()

    function loadSettings() {
        if (!pluginService)
            return;
        debounceMs = Number(pluginService.loadPluginData(pluginId, "debounceMs", 250));
        holdMs = Number(pluginService.loadPluginData(pluginId, "holdMs", 30000));
        music.palette = pluginService.loadPluginData(pluginId, "matugenScheme", "system");
    }

    ThemeSource {
        id: music
    }

    Timer {
        id: syncTimer
        interval: root.debounceMs
        onTriggered: root.sync()
    }

    Timer {
        id: holdTimer
        onTriggered: {
            if (!music.live)
                root.restore();
        }
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
        appliedHex = pluginService?.loadPluginState(pluginId, "appliedHex", "") ?? "";
        recovered = appliedHex !== "";
        publish();
        syncTimer.restart();
    }

    Component.onDestruction: {
        pluginService?.setGlobalVar(pluginId, "status", {
            "running": false
        });
        if (appliedHex)
            restore();
    }
}
