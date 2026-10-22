import QtQuick
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import qs.Modules.DDash

PluginSettings {
    id: root

    pluginId: "musicTheme"

    // Plugin settings, stored as strings like the pre-3.0 dropdowns did.
    property string palette: "system"
    property string holdMs: "30000"
    property string debounceMs: "250"

    // Published by the daemon; absent while the plugin is off.
    readonly property var daemon: PluginService.globalVars[pluginId]?.status ?? null
    readonly property bool running: daemon?.running === true
    readonly property string appliedHex: running ? (daemon.hex ?? "") : ""
    readonly property string appliedScheme: running ? (daemon.scheme ?? "") : ""
    readonly property double holdUntil: running ? (daemon.holdUntil ?? 0) : 0
    property double now: Date.now()
    // The page stays loaded while the Settings window is closed.
    readonly property bool shown: Window.window?.visible ?? false

    readonly property string nowPlaying: {
        const title = music.player?.trackTitle ?? "";
        const artist = music.player?.trackArtist ?? "";
        if (!title)
            return I18n.trFor("musicTheme", "Nothing playing");
        return artist ? title + " · " + artist : title;
    }

    // The cover playing now, else the one held after a pause, else the theme on screen.
    readonly property string previewSeed: music.seed || appliedHex || MatugenPreviewService.source
    readonly property bool previewIsCover: music.seed !== "" || appliedHex !== ""
    readonly property string previewKey: previewSeed ? MatugenPreviewService.seedKey(previewSeed) : ""
    readonly property var previews: previewKey ? MatugenPreviewService.seedPreviews[previewKey] ?? null : null

    readonly property var holdOptions: [
        {
            "label": I18n.trFor("musicTheme", "Immediately"),
            "value": "0"
        },
        {
            "label": I18n.trFor("musicTheme", "After 10 seconds"),
            "value": "10000"
        },
        {
            "label": I18n.trFor("musicTheme", "After 30 seconds"),
            "value": "30000"
        },
        {
            "label": I18n.trFor("musicTheme", "After 1 minute"),
            "value": "60000"
        },
        {
            "label": I18n.trFor("musicTheme", "After 5 minutes"),
            "value": "300000"
        },
        {
            "label": I18n.trFor("musicTheme", "When the player closes"),
            "value": "-1"
        }
    ]

    readonly property var debounceOptions: [
        {
            "label": I18n.trFor("musicTheme", "Fast (100 ms)"),
            "value": "100"
        },
        {
            "label": I18n.trFor("musicTheme", "Normal (250 ms)"),
            "value": "250"
        },
        {
            "label": I18n.trFor("musicTheme", "Slow (600 ms)"),
            "value": "600"
        }
    ]

    readonly property string blockerText: {
        switch (music.blocker) {
        case "matugen":
            return I18n.trFor("musicTheme", "Not theming: DMS cannot run matugen.");
        case "theme":
            return I18n.trFor("musicTheme", "Not theming: DMS is not on the Dynamic theme.");
        case "accent":
            return I18n.trFor("musicTheme", "Not theming: the media player's album art accent is off.");
        case "seed":
            return I18n.trFor("musicTheme", "Not theming: a custom derived color overrides the album art.");
        }
        return "";
    }

    readonly property string fixText: {
        switch (music.blocker) {
        case "theme":
            return I18n.trFor("musicTheme", "Use Dynamic");
        case "accent":
            return I18n.trFor("musicTheme", "Turn on");
        case "seed":
            return I18n.trFor("musicTheme", "Remove override");
        }
        return "";
    }

    readonly property string statusText: {
        if (!running)
            return I18n.trFor("musicTheme", "Music Theme is off.");
        if (!music.met)
            return blockerText;
        // Held through a track change until the new cover loads.
        if (appliedHex && holdUntil !== 0 && music.playing)
            return I18n.trFor("musicTheme", "Waiting for this track's album art.");
        if (appliedHex && holdUntil < 0)
            return I18n.trFor("musicTheme", "Playback stopped. The album colors stay until the player closes.");
        if (appliedHex && holdUntil > 0)
            return I18n.trFor("musicTheme", "Playback stopped. The wallpaper colors come back in %1.").arg(I18n.duration(Math.max(1, Math.ceil((holdUntil - now) / 1000))));
        if (appliedHex)
            return I18n.trFor("musicTheme", "Theming from this cover.");
        if (!music.player)
            return I18n.trFor("musicTheme", "Waiting for a media player.");
        if (!music.playing)
            return I18n.trFor("musicTheme", "Waiting for playback.");
        if (!music.seed)
            return I18n.trFor("musicTheme", "This track has no album art.");
        return I18n.trFor("musicTheme", "Applying…");
    }

    function fix() {
        switch (music.blocker) {
        case "theme":
            Theme.switchTheme(Theme.dynamic);
            break;
        case "accent":
            DashRegistry.setOption("media", "albumArtAccent", true);
            break;
        case "seed":
            SettingsData.setMatugenSeedColor("");
            break;
        }
    }

    // Primary, secondary and tertiary that `scheme` builds from the preview seed.
    function paletteFor(scheme) {
        return previews?.[scheme]?.[SessionData.isLightMode ? "light" : "dark"] ?? {
            "primary": previewSeed,
            "secondary": previewSeed,
            "tertiary": previewSeed
        };
    }

    function labelOf(options, value) {
        return (options.find(option => option.value === value) ?? options[0]).label;
    }

    function valueOf(options, label) {
        return (options.find(option => option.label === label) ?? options[0]).value;
    }

    function reload() {
        palette = loadValue("matugenScheme", "system");
        holdMs = String(loadValue("holdMs", "30000"));
        debounceMs = String(loadValue("debounceMs", "250"));
    }

    function requestPreview() {
        if (shown && previewSeed)
            MatugenPreviewService.requestSeeds([previewSeed]);
    }

    onPluginServiceChanged: reload()
    onPreviewKeyChanged: requestPreview()
    onShownChanged: requestPreview()
    Component.onCompleted: {
        reload();
        requestPreview();
    }

    ThemeSource {
        id: music
        palette: root.palette
    }

    Connections {
        target: root.pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                root.reload();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.shown && root.holdUntil > 0
        onTriggered: root.now = Date.now()
    }

    SettingsRow {
        title: root.nowPlaying
        singleLineTitle: true
        subtitle: root.statusText
        subtitleColor: root.running && !music.met ? Theme.error : Theme.surfaceVariantText

        leading: ClippingRectangle {
            width: SettingsMetrics.heroLeadingSize
            height: width
            radius: Theme.cornerRadiusM
            color: Theme.surfaceContainerHigh

            Image {
                id: cover
                anchors.fill: parent
                source: music.player ? TrackArtService.resolvedArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
                visible: status === Image.Ready
            }

            DIcon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                name: music.player ? "music_note" : "music_off"
                size: Theme.iconSizeMedium
                color: Theme.surfaceVariantText
            }
        }

        DButton {
            visible: root.running && root.fixText !== ""
            text: root.fixText
            onClicked: root.fix()
        }

        Row {
            visible: root.appliedHex !== ""
            spacing: Theme.spacingS

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.appliedHex
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.monoFontFamily
                color: Theme.surfaceVariantText
            }

            DPaletteSwatch {
                readonly property var colors: root.paletteFor(root.appliedScheme)

                anchors.verticalCenter: parent.verticalCenter
                width: Theme.minimumTouchTargetSize
                height: width
                primaryColor: colors.primary
                secondaryColor: colors.secondary
                tertiaryColor: colors.tertiary
            }
        }
    }

    SettingsGroup {
        SettingsRow {
            title: I18n.trFor("musicTheme", "Palette")
            subtitle: {
                const system = I18n.trFor("musicTheme", "System follows the DMS palette, now %1.").arg(Theme.getMatugenScheme(music.systemScheme).label);
                if (!root.previewIsCover)
                    return system + " " + I18n.trFor("musicTheme", "Play a track to preview its cover.");
                if (music.isNeutral(root.previewSeed))
                    return system + " " + I18n.trFor("musicTheme", "This cover has no strong color, so it gets a neutral theme.");
                return system;
            }

            body: SettingsSwatchGrid {
                options: [
                    {
                        "value": "system",
                        "label": I18n.trFor("musicTheme", "System")
                    }
                ].concat(music.schemes.map(scheme => ({
                            "value": scheme.value,
                            "label": scheme.label
                        })))
                currentValue: music.schemes.some(scheme => scheme.value === root.palette) ? root.palette : "system"
                enabled: Theme.matugenAvailable
                resolveOption: option => root.paletteFor(music.resolveScheme(root.previewSeed, option.value))
                onSelected: value => root.saveValue("matugenScheme", value)
            }
        }

        SettingsDropdownRow {
            text: I18n.trFor("musicTheme", "When playback stops")
            description: I18n.trFor("musicTheme", "How long the album colors stay after a pause before DMS takes the theme back")
            options: root.holdOptions.map(option => option.label)
            currentValue: root.labelOf(root.holdOptions, root.holdMs)
            onValueChanged: value => root.saveValue("holdMs", root.valueOf(root.holdOptions, value))
        }

        SettingsDropdownRow {
            text: I18n.trFor("musicTheme", "Update delay")
            description: I18n.trFor("musicTheme", "How long the album art color has to settle before the theme changes")
            options: root.debounceOptions.map(option => option.label)
            currentValue: root.labelOf(root.debounceOptions, root.debounceMs)
            onValueChanged: value => root.saveValue("debounceMs", root.valueOf(root.debounceOptions, value))
        }
    }
}
