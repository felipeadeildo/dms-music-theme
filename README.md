# Music Theme

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) daemon plugin that retints your system theme (GTK, Qt, terminals, and everything else matugen templates) to match the accent color of the album art of the track currently playing — without ever touching your wallpaper.

## How it works

DMS already computes a live accent color from the playing track's album art via `MediaAccentService` (used to color the media player popup). This plugin listens to that same color and, whenever it changes, calls the shell's own `Theme.setDesiredTheme("hex", <color>, ...)` — the exact function DMS uses internally when you pick a wallpaper — with the album art color instead of an image.

Because `matugen`/DMS already treats color sources as either an image path or a raw hex value, no wallpaper file is created, copied, or swapped. `dms ipc call wallpaper get` keeps returning your real wallpaper the entire time; only the generated color palette (GTK/Qt/terminal/etc. templates) changes.

When playback stops (or the plugin is disabled), the theme automatically reverts to the one generated from your actual wallpaper.

```
music plays -> MediaAccentService.accent changes -> debounce -> Theme.setDesiredTheme("hex", "#RRGGBB", ...)
music stops -> Theme.setDesiredTheme(<wallpaper kind>, <wallpaper path>, ...)
```

## Requirements

- DMS >= 1.5.0
- matugen enabled (default; disabled via `DMS_DISABLE_MATUGEN=1`)
- A media player exposing MPRIS with album art (Spotify, browsers, mpv, etc.) — no `playerctl` or other external tool needed, DMS reads MPRIS natively.

## Installation

```bash
git clone https://github.com/felipeadeildo/dms-music-theme.git \
  ~/.config/DankMaterialShell/plugins/MusicTheme
```

Then in DMS: **Settings → Plugins → Scan for Plugins**, and enable **Music Theme**.

## Settings

- **Enable Music Theming** — master on/off toggle.
- **Update Delay** — debounce before retheming after a track/color change (Fast/Normal/Slow), to avoid spamming matugen during track transitions.

## Notes

- Very low-saturation album art (e.g. black & white covers) is skipped to avoid muddy/gray themes; the previous theme is kept until a usable color shows up.
- This plugin does not persist any wallpaper state — it only calls the same `dms matugen queue` pipeline the shell already uses, so it stays compatible with whatever wallpaper/theme workflow you use otherwise.

## License

MIT
