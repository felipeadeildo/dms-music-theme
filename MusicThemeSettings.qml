import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "musicTheme"

    StyledText {
        width: parent.width
        text: "Retints GTK/Qt/terminal colors to match the currently playing track's album art, using the same matugen pipeline as wallpaper theming. Your wallpaper file is never changed; the theme reverts automatically when playback stops."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "enabled"
        label: "Enable Music Theming"
        description: "Apply the album art accent color as the system theme while music plays"
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "debounceMs"
        label: "Update Delay"
        description: "How long to wait after a track/color change before retheming"
        options: [
            {label: "Fast (600ms)", value: "600"},
            {label: "Normal (1200ms)", value: "1200"},
            {label: "Slow (2500ms)", value: "2500"}
        ]
        defaultValue: "1200"
    }
}
