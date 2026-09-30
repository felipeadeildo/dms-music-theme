import QtQuick
import qs.Common

// DMS state the plugin needs before it can theme from album art. Shared by the
// daemon, which waits on `met`, and the settings page, which shows `problem`.
QtObject {
    // Lives in MediaOptions or SettingsData depending on the DMS version. Without
    // either, DMS always uses the album art.
    readonly property bool albumArtAccent: typeof MediaOptions !== "undefined" ? MediaOptions.albumArtAccent : SettingsData.mediaUseAlbumArtAccent !== false

    readonly property string problem: {
        if (!Theme.matugenAvailable)
            return "Paused: DMS cannot run matugen.";
        if (Theme.currentTheme !== Theme.dynamic)
            return "Paused: switch DMS to the Dynamic theme.";
        if (!albumArtAccent)
            return "Paused: turn on \"Use album art accent\" in the DMS media player options.";
        // A custom seed color (DMS "Derived color") replaces any hex sent to matugen.
        if (SettingsData.matugenSeedColor)
            return "Paused: set the Dynamic theme's derived color back to \"From wallpaper\".";
        return "";
    }

    readonly property bool met: problem === ""
}
