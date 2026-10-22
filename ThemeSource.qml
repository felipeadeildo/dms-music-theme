import QtQuick
import qs.Common
import qs.Services

// Everything the plugin reads from DMS: whether it may touch the theme, what
// is playing, and the matugen request the playing track turns into. The daemon
// acts on it and the settings page previews it, so both agree on the result.
QtObject {
    id: root

    // The plugin's "matugenScheme" setting: "system" or a matugen scheme.
    property string palette: "system"

    // First DMS setting that keeps the plugin idle, or "" when it may run.
    readonly property string blocker: {
        if (!Theme.matugenAvailable)
            return "matugen";
        if (Theme.currentTheme !== Theme.dynamic)
            return "theme";
        // With the accent off, MediaAccentService reports Theme.primary as the
        // accent, and theming from it would feed the theme back into itself.
        if (!MediaOptions.albumArtAccent)
            return "accent";
        // A derived color replaces any hex sent to matugen.
        if (SettingsData.matugenSeedColor)
            return "seed";
        return "";
    }
    readonly property bool met: blocker === ""

    readonly property var player: MprisController.activePlayer
    readonly property bool playing: !!player && player.isPlaying

    // The accent DMS picks from the album art, so the theme matches the media
    // player. Empty while the track has no usable art.
    readonly property string seed: MediaOptions.albumArtAccent && MediaAccentService.hasAccent ? toHex(MediaAccentService.accent) : ""
    readonly property bool live: met && playing && seed !== ""

    readonly property string systemScheme: SettingsData.matugenScheme || "scheme-tonal-spot"

    // The schemes DMS offers for the current spec, same as its own picker.
    readonly property var schemes: Theme.availableMatugenSchemes.filter(scheme => {
        if (scheme.value === "scheme-smart" && !DMSService.matugenSmartSupported)
            return false;
        return SettingsData.matugenSpec === "2021" || scheme.spec2025 === true;
    })

    readonly property string scheme: schemeFor(seed)

    function toHex(color) {
        const channel = value => Math.round(value * 255).toString(16).padStart(2, "0");
        return "#" + channel(color.r) + channel(color.g) + channel(color.b);
    }

    // DMS falls back to a desaturated tone for black and white or washed out
    // covers (saturation <= 0.18, against >= 0.23 for a real accent).
    function isNeutral(hex) {
        return Qt.color(hex).hsvSaturation < 0.2;
    }

    // The scheme a seed is generated with when the user picks `choice`.
    // Most schemes pin the chroma, so a gray seed would come out as a strong
    // color with an arbitrary hue (cyan for pure gray). Content keeps the
    // seed's chroma and turns those covers into a neutral theme.
    function resolveScheme(hex, choice) {
        const picked = choice !== "system" && schemes.some(scheme => scheme.value === choice) ? choice : systemScheme;
        if (hex && isNeutral(hex) && !["scheme-content", "scheme-fidelity", "scheme-monochrome"].includes(picked))
            return "scheme-content";
        return picked;
    }

    function schemeFor(hex) {
        return resolveScheme(hex, palette);
    }
}
