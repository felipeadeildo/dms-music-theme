import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "musicTheme"

    SelectionSetting {
        settingKey: "debounceMs"
        label: "Update Delay"
        description: "How long to wait for the album art color to settle before retheming"
        options: [
            {label: "Fast (100ms)", value: "100"},
            {label: "Normal (250ms)", value: "250"},
            {label: "Slow (600ms)", value: "600"}
        ]
        defaultValue: "250"
    }

    SelectionSetting {
        settingKey: "matugenScheme"
        label: "Palette"
        description: "Matugen scheme used to turn the album art color into a full palette"
        options: [
            {label: "Follow system setting", value: "system"},
            {label: "Tonal Spot", value: "scheme-tonal-spot"},
            {label: "Vibrant", value: "scheme-vibrant"},
            {label: "Content", value: "scheme-content"},
            {label: "Expressive", value: "scheme-expressive"},
            {label: "Fidelity", value: "scheme-fidelity"},
            {label: "Fruit Salad", value: "scheme-fruit-salad"},
            {label: "Monochrome", value: "scheme-monochrome"},
            {label: "Neutral", value: "scheme-neutral"},
            {label: "Rainbow", value: "scheme-rainbow"}
        ]
        defaultValue: "system"
    }
}
