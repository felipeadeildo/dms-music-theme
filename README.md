# Music Theme

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin that themes your system (GTK, Qt, terminals, editors) from the album art of the track currently playing, without touching your wallpaper.

## Features

- Retints the system theme using the accent color already extracted from the playing track's album art
- Uses DMS's own matugen pipeline, so every existing template (GTK, Qt, terminals, Neovim, VSCode, Firefox/Zen) updates automatically
- Never modifies your wallpaper file; `dms ipc call wallpaper get` keeps returning your real wallpaper the whole time
- Reverts to your wallpaper theme automatically when playback stops or the plugin is disabled
- No `playerctl` or Python dependency; reads MPRIS and album art natively through DMS
- Configurable palette (Tonal Spot, Vibrant, Expressive, and the rest of the matugen schemes), or follow your system default
- Skips low-saturation album art (black & white covers) to avoid muddy themes

## Requirements

- DMS >= 1.5.0
- matugen enabled (default; disable with `DMS_DISABLE_MATUGEN=1`)
- A media player exposing MPRIS with album art (Spotify, browsers, mpv, etc.)

## Installation

### Manual

```bash
git clone https://github.com/felipeadeildo/dms-music-theme.git \
  ~/.config/DankMaterialShell/plugins/MusicTheme
```

1. Open DMS Settings (Ctrl+,)
2. Navigate to Plugins tab
3. Click "Scan for Plugins"
4. Enable "Music Theme" with the toggle switch

## Configuration

Settings available in plugin settings:

- **Enable Music Theming**: master on/off toggle (default: enabled)
- **Update Delay**: how long to let the album art color settle before retheming (default: `250ms`)
- **Palette**: matugen scheme used to build the full palette from the accent color (default: follow system setting)

## How it works

DMS already computes a live accent color from the playing track's album art (used to color the media player popup). This plugin watches that color and, whenever it changes, calls the same internal function DMS uses when you pick a wallpaper, passing the album art color instead of an image path. Since DMS already treats color sources as either an image or a raw hex value, no wallpaper file is ever created or swapped.

```
music plays -> accent color changes -> theme retinted from that color
music stops -> theme reverts to the one generated from your wallpaper
```

## License

MIT
