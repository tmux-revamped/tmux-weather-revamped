<div align="center">

<h1>tmux-weather-revamped</h1>

**Weather in your tmux status bar, fetched in the background so the render never waits on the network.**

[![Tests](https://github.com/tmux-revamped/tmux-weather-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-weather-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)

</div>

**28** placeholders · **205** tests · **95%+** coverage

A weather lookup is an HTTP request, the slowest thing a status bar can do inline. This plugin runs `curl` with a hard timeout inside a detached worker, caches the result in a tmux server user-option, and serves the status line from that cache. No temp files are used, and a failed fetch keeps the last good reading on screen.

Inspired by [tmux-weather](https://github.com/ilya-manin/tmux-weather). Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template). Weather data comes from [wttr.in](https://github.com/chubin/wttr.in).

<table>
<tr>
<td><b>Non-blocking</b><br/>The fetch runs in a detached worker, so the status render returns instantly.</td>
<td><b>No temp files</b><br/>The reading lives in a tmux server user-option, not on disk.</td>
</tr>
<tr>
<td><b>Cross-platform</b><br/>Runs anywhere `curl` is on <code>PATH</code>, on every supported architecture.</td>
<td><b>Tested</b><br/>205 tests at 95%+ coverage guard every code path.</td>
</tr>
</table>

## Placeholders

A single background fetch of the wttr.in `j1` JSON carries the whole reading, so
every placeholder below is derived from one cached request with no extra network
call. Each placeholder also accepts a location name when you run several, for
example `#(weather.sh temp Tokyo)`.

| Placeholder | Output |
|-------------|--------|
| `#{weather}` | the one-line forecast, for example `Partly cloudy +18°C` |
| `#{weather_temp}` | just the temperature, leading plus removed, for example `18°C` |
| `#{weather_feels_like}` | the feels-like temperature number, for example `16` |
| `#{weather_wind}` | wind speed and direction, for example `11km/h NW` |
| `#{weather_humidity}` | relative humidity percentage, for example `65` |
| `#{weather_pressure}` | barometric pressure in hPa, for example `1013` |
| `#{weather_pressure_trend}` | a trend mark versus the previous fetch: `^`, `v`, or `=` |
| `#{weather_precip}` | precipitation in millimetres, for example `0.2` |
| `#{weather_rain_chance}` | the worst rain chance across today's hours, for example `60` |
| `#{weather_umbrella}` | the umbrella hint text when rain chance crosses the threshold |
| `#{weather_uv}` | the UV index, for example `5` |
| `#{weather_uv_color}` | a tmux color for the UV band |
| `#{weather_dew_point}` | the mean dew point for today, for example `12` |
| `#{weather_dew_comfort}` | a comfort word: `dry`, `comfortable`, `humid`, `oppressive` |
| `#{weather_moon}` | today's moon phase, for example `Waning Gibbous` |
| `#{weather_sunrise}` | today's sunrise time, for example `06:00 AM` |
| `#{weather_sunset}` | today's sunset time, for example `06:45 PM` |
| `#{weather_forecast}` | tomorrow's low and high, for example `15-27` |
| `#{weather_today_high}` / `#{weather_today_low}` | today's high and low |
| `#{weather_tomorrow_high}` / `#{weather_tomorrow_low}` | tomorrow's high and low |
| `#{weather_condition_icon}` | a Nerd Font glyph for the sky condition |
| `#{weather_condition_tint}` | a per-condition color override, empty until you set one |
| `#{weather_color}` | a tmux color style for the current temperature band, for example `#[fg=green]` |
| `#{weather_icon}` | an icon for the current temperature band, empty until you set one |
| `#{weather_stale_color}` | a dim style when the host has been offline past three intervals |
| `#{weather_alert}` | a severe-weather badge, empty unless alerts are enabled |

Pair the color with the value, and reset afterward, to tint the reading by
temperature. A clean Nerd Font layout is the condition glyph, then the
temperature, colored by band:

```tmux
set -g status-right '#{weather_color}#{weather_condition_icon} #{weather_temp}#[default] '
```

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-revamped/tmux-weather-revamped'
set -g status-right '#{weather} '
```

Press `prefix + I` to install. `curl` must be on `PATH`.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@tmux-weather-location` | empty | a city or location; empty auto-detects by IP |
| `@tmux-weather-units` | `m` | Celsius or Fahrenheit; accepts `m`/`c`/`celsius` and `u`/`f`/`fahrenheit` |
| `@tmux-weather-format` | `%C+%t` | a wttr.in one-line format code; the default carries the condition and temperature |
| `@tmux-weather-interval` | `15` | minutes between background fetches |
| `@tmux-weather-hide-units` | `off` | set to `on` to drop the `C`/`F` unit letter from `#{weather_temp}`, keeping just the number and degree mark |
| `@weather_revamped_show_condition_icon` | `on` | set to `off` to hide the sky glyph from `#{weather_condition_icon}` |
| `@weather_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/weather-revamped-logs` |
| `@tmux-weather-locations` | empty | a `;`-separated list of locations; each gets its own background worker and cache |
| `@tmux-weather-alerts` | `off` | set to `on` to fetch the second severe-weather endpoint |
| `@tmux-weather-alert-url` | empty | the alert endpoint, with `{loc}` replaced by the location |
| `@tmux-weather-popup-key` | empty | a key to bind the detail popup (tmux 3.2+) |
| `@tmux-weather-refresh-key` | empty | a key to bind an immediate force-refresh |
| `@weather_revamped_umbrella_text` | empty | the `#{weather_umbrella}` hint text |
| `@weather_revamped_umbrella_threshold` | `50` | rain chance percent at which the umbrella hint fires |
| `@weather_revamped_alert_prefix` | empty | text prepended to `#{weather_alert}` |
| `@weather_revamped_stale_color` | `#[dim]` | the style `#{weather_stale_color}` emits when stale |

See the [wttr.in format options](https://github.com/chubin/wttr.in#one-line-output)
for format codes.

### Temperature bands

`#{weather_color}` and `#{weather_icon}` classify the current temperature into a
band, then read a per-band color and icon. The temperature is parsed from the
cached wttr.in value, so no extra fetch happens. Bands use these Celsius
thresholds:

| Band | Range (°C) | Default color | Color option | Icon option |
|------|------------|---------------|--------------|-------------|
| freezing | below 0 | `#[fg=blue]` | `@weather_revamped_freezing_color` | `@weather_revamped_freezing_icon` |
| cold | 0 to 9 | `#[fg=cyan]` | `@weather_revamped_cold_color` | `@weather_revamped_cold_icon` |
| cool | 10 to 17 | `#[fg=green]` | `@weather_revamped_cool_color` | `@weather_revamped_cool_icon` |
| comfortable | 18 to 23 | `#[fg=green]` | `@weather_revamped_comfortable_color` | `@weather_revamped_comfortable_icon` |
| hot | 24 to 31 | `#[fg=yellow]` | `@weather_revamped_hot_color` | `@weather_revamped_hot_icon` |
| very_hot | 32 and up | `#[fg=red]` | `@weather_revamped_very_hot_color` | `@weather_revamped_very_hot_icon` |

Every icon option defaults to empty, so no Nerd Font is required. Set the ones
you want:

```tmux
set -g @weather_revamped_freezing_icon 'COLD '
set -g @weather_revamped_hot_color '#[fg=colour208]'
```

When the temperature cannot be parsed, both placeholders render empty.

### Sky conditions

`#{weather_condition_icon}` reads the wttr.in condition text and maps it to a
Nerd Font weather glyph. For this to work the fetch format must include the
condition, which the default `@tmux-weather-format` of `%C+%t` already does.
Conditions are normalized into six keys, each with a Nerd Font default that you
can override:

| Key | Matches conditions containing | Icon option |
|-----|-------------------------------|-------------|
| clear | sun, clear | `@weather_revamped_clear_condition_icon` |
| clouds | cloud, overcast | `@weather_revamped_clouds_condition_icon` |
| rain | rain, drizzle, shower | `@weather_revamped_rain_condition_icon` |
| snow | snow, sleet, blizzard, ice | `@weather_revamped_snow_condition_icon` |
| storm | thunder, storm | `@weather_revamped_storm_condition_icon` |
| fog | fog, mist, haze | `@weather_revamped_fog_condition_icon` |

Storm and snow are matched before rain, so a thundery shower maps to storm and
sleet to snow. Override any key to a different glyph or plain text:

```tmux
set -g @weather_revamped_rain_condition_icon 'RAIN'
```

## One fetch, the whole reading

The background worker requests the wttr.in `j1` JSON once per interval and caches
it in a tmux user-option. Every placeholder reads that one document, so adding
wind, humidity, UV, dew point, pressure, sun and moon times, and the tomorrow
forecast costs no extra request. A rich line might read:

```tmux
set -g status-right '#{weather_color}#{weather_condition_icon} #{weather_temp} #[default]#{weather_wind} #{weather_humidity}%% UV#{weather_uv} #{weather_forecast} '
```

`#{weather_uv_color}` colors the UV index by WHO band, and `#{weather_dew_comfort}`
turns the dew point into a comfort word. `#{weather_pressure_trend}` compares the
latest reading to the previous fetch and shows `^`, `v`, or `=`.
`#{weather_umbrella}` stays empty until the rain chance crosses
`@weather_revamped_umbrella_threshold`, then shows your
`@weather_revamped_umbrella_text`.

## Multiple locations

Set `@tmux-weather-locations` to a `;`-separated list to track several places at
once. Each location runs its own background worker into its own cache option, so
one slow lookup never blocks another. Address a location by name on any
placeholder:

```tmux
set -g @tmux-weather-locations 'London;Tokyo;New York'
set -g status-right '#(~/.tmux/plugins/tmux-weather-revamped/src/weather.sh temp London) #(~/.tmux/plugins/tmux-weather-revamped/src/weather.sh temp Tokyo) '
```

## Severe-weather alerts

Alerts are off by default and use a second endpoint. Turn them on and point them
at an endpoint that returns a short alert line, with `{loc}` replaced by the
location:

```tmux
set -g @tmux-weather-alerts 'on'
set -g @tmux-weather-alert-url 'https://example.com/alerts/{loc}'
set -g @weather_revamped_alert_prefix '[!] '
set -g status-right '#{weather_alert}#{weather} '
```

`#{weather_alert}` stays empty when there is no alert, so the badge appears only
when it matters.

## Detail popup and refresh keys

Bind a key to open a full card built from the cached reading, no re-probing, and
another to force an immediate refresh. Both are unset by default so nothing
clashes with your own bindings:

```tmux
set -g @tmux-weather-popup-key 'W'
set -g @tmux-weather-refresh-key 'R'
```

`prefix + W` then shows condition, feels-like, wind, humidity, pressure, UV, dew
point, precipitation, sun and moon times, and today and tomorrow's range. The
popup needs tmux 3.2 or newer.

## Doctor

```sh
~/.tmux/plugins/tmux-weather-revamped/src/weather.sh doctor
```

Reports whether `curl` is on `PATH`, the configured units, interval, locations,
and whether the current reading parsed, so an empty token is easy to explain.

## Theme color suggestions

The defaults use the 16 ANSI color names, which the active terminal theme remaps,
so the bands match whatever theme you run out of the box. For exact hex values
that pin a band to a specific shade, copy one block below.

### Catppuccin Mocha

```tmux
set -g @weather_revamped_freezing_color '#[fg=#89b4fa]'
set -g @weather_revamped_cold_color '#[fg=#94e2d5]'
set -g @weather_revamped_cool_color '#[fg=#a6e3a1]'
set -g @weather_revamped_comfortable_color '#[fg=#a6e3a1]'
set -g @weather_revamped_hot_color '#[fg=#f9e2af]'
set -g @weather_revamped_very_hot_color '#[fg=#f38ba8]'
```

### Dracula

```tmux
set -g @weather_revamped_freezing_color '#[fg=#bd93f9]'
set -g @weather_revamped_cold_color '#[fg=#8be9fd]'
set -g @weather_revamped_cool_color '#[fg=#50fa7b]'
set -g @weather_revamped_comfortable_color '#[fg=#50fa7b]'
set -g @weather_revamped_hot_color '#[fg=#f1fa8c]'
set -g @weather_revamped_very_hot_color '#[fg=#ff5555]'
```

### Nord

```tmux
set -g @weather_revamped_freezing_color '#[fg=#81a1c1]'
set -g @weather_revamped_cold_color '#[fg=#88c0d0]'
set -g @weather_revamped_cool_color '#[fg=#a3be8c]'
set -g @weather_revamped_comfortable_color '#[fg=#a3be8c]'
set -g @weather_revamped_hot_color '#[fg=#ebcb8b]'
set -g @weather_revamped_very_hot_color '#[fg=#bf616a]'
```

### Gruvbox Dark

```tmux
set -g @weather_revamped_freezing_color '#[fg=#83a598]'
set -g @weather_revamped_cold_color '#[fg=#8ec07c]'
set -g @weather_revamped_cool_color '#[fg=#b8bb26]'
set -g @weather_revamped_comfortable_color '#[fg=#b8bb26]'
set -g @weather_revamped_hot_color '#[fg=#fabd2f]'
set -g @weather_revamped_very_hot_color '#[fg=#fb4934]'
```

### Tokyo Night

```tmux
set -g @weather_revamped_freezing_color '#[fg=#7aa2f7]'
set -g @weather_revamped_cold_color '#[fg=#7dcfff]'
set -g @weather_revamped_cool_color '#[fg=#9ece6a]'
set -g @weather_revamped_comfortable_color '#[fg=#9ece6a]'
set -g @weather_revamped_hot_color '#[fg=#e0af68]'
set -g @weather_revamped_very_hot_color '#[fg=#f7768e]'
```

### Solarized Dark

```tmux
set -g @weather_revamped_freezing_color '#[fg=#268bd2]'
set -g @weather_revamped_cold_color '#[fg=#2aa198]'
set -g @weather_revamped_cool_color '#[fg=#859900]'
set -g @weather_revamped_comfortable_color '#[fg=#859900]'
set -g @weather_revamped_hot_color '#[fg=#b58900]'
set -g @weather_revamped_very_hot_color '#[fg=#dc322f]'
```

## Support by platform and architecture

Works on every supported platform and architecture. The only requirement is
`curl` on `PATH`, which ships with macOS (Intel and Apple Silicon) and is a one
package install on Linux (x86_64 and arm64).

## Development

```sh
bats test          # run the suite
shellcheck src/**/*.sh   # lint
kcov coverage bats test  # coverage
```

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | **this plugin**, Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
