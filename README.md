# Music Theme

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) plugin that themes your system (GTK, Qt, terminals, editors) from the album art of the track currently playing, without touching your wallpaper.

<div align="center">
  <img src="assets/screenshot.png" alt="Music Theme plugin in DMS Settings">
</div>

<details>
<summary>More screenshots</summary>
<br>
<div align="center">
  <img src="assets/screenshot-2.png" width="45%" alt="Theme matching a blue album cover">
  <img src="assets/screenshot-3.png" width="45%" alt="Theme matching a purple album cover">
  <br>
  <img src="assets/screenshot-4.png" width="45%" alt="Theme matching another blue album cover">
</div>
</details>

## Features

- Retints the system theme using the accent color already extracted from the playing track's album art
- Uses DMS's own matugen pipeline, so every existing template (GTK, Qt, terminals, Neovim, VSCode, Firefox/Zen) updates automatically
- Never modifies your wallpaper file
- Reverts to your wallpaper theme automatically when playback stops or the plugin is disabled
- No `playerctl` or Python dependency; reads MPRIS and album art natively through DMS
- Configurable palette (Tonal Spot, Vibrant, Expressive, and the rest of the matugen schemes), or follow your system default

## Requirements

- DMS >= 1.5.0
- matugen enabled (default; disable with `DMS_DISABLE_MATUGEN=1`)
- A media player exposing MPRIS with album art (Spotify, browsers, mpv, etc.)

## Installation

```bash
git clone https://github.com/felipeadeildo/dms-music-theme.git \
  ~/.config/DankMaterialShell/plugins/MusicTheme
```

1. Open DMS Settings (Ctrl+,)
2. Navigate to Plugins tab
3. Click "Scan for Plugins"
4. Enable "Music Theme" with the toggle switch

## Configuration

- **Update Delay**: how long to let the album art color settle before retheming
- **Palette**: matugen scheme used to build the full palette from the accent color

## License

MIT
