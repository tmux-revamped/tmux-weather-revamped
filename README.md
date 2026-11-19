<div align="center">

# tmux-weather-revamped

<strong>Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-weather-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-weather-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-weather-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-weather-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-weather-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-weather-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-weather-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="weather-revamped showing the weather in the status line, opening the forecast popup, switching to Fahrenheit, fetching on the refresh key and switching to the options render mode" width="800">
</p>

```console
$ weather-revamped refresh
Refreshed. wttr.in says Partly cloudy +18°C for Lisbon.
$ weather-revamped status weather
Partly cloudy +18°C
```

**28** placeholders from **1** request per place, **2** render modes, macOS and Linux, tmux **3.2** or later.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor, and the popup |
| curl | any | every fetch, with a 10 second limit |
| gum | optional | the menu, tables and colours of `weather-revamped`; without it every command prints plain text |

It needs network access to [wttr.in](https://wttr.in), and runs on Linux and macOS with BSD, GNU or uutils coreutils.

### Install

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin and a placeholder to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-weather-revamped'
set -g status-right '#{weather} '
```

To install by hand, clone the repository and run the entrypoint from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-weather-revamped ~/.tmux/plugins/tmux-weather-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-weather-revamped/weather-revamped.tmux
```

Set `status-left` or `status-right` before the plugin loads. The plugin replaces the placeholders it finds there once, at load time. [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf) holds a line to copy.

`make install` in the clone also puts `weather-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-weather-revamped/bin/weather-revamped doctor
```

## Usage

Set a place, or leave it empty and wttr.in locates you by IP. Every placeholder comes from the same stored answer, so a richer line costs no extra request. The first render after a cold start is empty while the first fetch runs, and a failed fetch keeps the last reading on screen.

```tmux
set -g @weather_revamped_location 'Lisbon'
set -g status-right '#{weather_color}#{weather_condition_icon} #{weather_temp}#[default] #{weather_wind} '
```

| Placeholder | Output |
|:------------|:-------|
| `#{weather}` | Condition and temperature, such as `Partly cloudy +18°C` |
| `#{weather_temp}` | Temperature without the plus, such as `18°C` |
| `#{weather_feels_like}` | Feels-like temperature, such as `16` |
| `#{weather_wind}` | Wind speed and direction, such as `11km/h NW` |
| `#{weather_humidity}` | Relative humidity in percent |
| `#{weather_pressure}` | Pressure in hPa |
| `#{weather_pressure_trend}` | `^`, `v` or `=` against the fetch before |
| `#{weather_precip}` | Precipitation in millimetres |
| `#{weather_rain_chance}` | The highest rain chance of today's first eight forecast slots |
| `#{weather_umbrella}` | Your umbrella text once the rain chance reaches the threshold |
| `#{weather_uv}` | UV index |
| `#{weather_uv_color}` | A tmux style for the UV level |
| `#{weather_dew_point}` | Mean dew point of today's first eight forecast slots |
| `#{weather_dew_comfort}` | `dry`, `comfortable`, `humid` or `oppressive` |
| `#{weather_moon}` | Moon phase, such as `Waning Gibbous` |
| `#{weather_sunrise}` | Sunrise, such as `06:00 AM` |
| `#{weather_sunset}` | Sunset, such as `06:45 PM` |
| `#{weather_forecast}` | Tomorrow's low and high, such as `15-27` |
| `#{weather_today_high}` | Today's high |
| `#{weather_today_low}` | Today's low |
| `#{weather_tomorrow_high}` | Tomorrow's high |
| `#{weather_tomorrow_low}` | Tomorrow's low |
| `#{weather_condition_icon}` | A Nerd Font glyph for the sky |
| `#{weather_condition_tint}` | A tmux style for the sky |
| `#{weather_color}` | A tmux style for the temperature band, such as `#[fg=green]` |
| `#{weather_icon}` | Your icon for the temperature band, empty until set |
| `#{weather_stale_color}` | `#[dim]` once the last answer is older than three fetch intervals |
| `#{weather_alert}` | An alert line from your own address, empty unless alerts are on |

### Several places

`@weather_revamped_locations` takes places separated by `;`. The first one fills the placeholders. Any other is read by hand, in a status line or a script, and each place keeps its own reading:

```tmux
set -g @weather_revamped_locations 'Lisbon;Oslo'
```

```bash
weather-revamped status weather Oslo
weather-revamped card Oslo
```

### Alerts

wttr.in sends no alerts, so the alert line comes from an address of your own. With `@weather_revamped_alerts` at `on`, the first line of `@weather_revamped_alert_url` that is not empty becomes `#{weather_alert}`, and with `@weather_revamped_notify` at `1` a new alert is also a desktop notification.

### Render mode

In the default `jobs` mode each placeholder is a status job that prints the stored reading at once. With `@weather_revamped_render` at `options`, one background process fetches and writes every placeholder into a tmux option per tick, so a status refresh starts no process.

### The command

| Command | What it does |
|:--------|:-------------|
| `weather-revamped status NAME [PLACE]` | Prints one placeholder, named without `weather_`; the first one is `weather` |
| `weather-revamped refresh [PLACE]` | Fetches now and says what wttr.in answered |
| `weather-revamped card [PLACE]` | Prints the whole reading as a table |
| `weather-revamped popup [PLACE]` | Opens the card in a tmux popup |
| `weather-revamped list` | Prints what `apply` would send to tmux; `--json` prints it as one object |
| `weather-revamped apply` | Binds the keys and fills the placeholders, as the entry point does |
| `weather-revamped doctor` | Checks this machine |

Every tmux option is also an option of the command, such as `--units u`, and an environment variable, such as `WEATHER_REVAMPED_UNITS`. The command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. An on or off option also reads `1`, `yes` and `true` as on, and `0`, `no` and `false` as off; a tmux option that holds any other value takes its default, and `doctor` names it.

## Configuration

### Reading

| Option | Default | What it sets |
|:-------|:--------|:-------------|
| `@weather_revamped_location` | none | City or place. Empty lets wttr.in locate you by IP |
| `@weather_revamped_locations` | none | Places separated by `;`. The first one fills the placeholders, and it outranks the single location |
| `@weather_revamped_units` | `m` | `m` for Celsius and km/h, `u` for Fahrenheit and mph; `f`, `fahrenheit` and `imperial` are read as `u` |
| `@weather_revamped_fetch_minutes` | `15` | Minutes a reading stays fresh before the next fetch, 1 or more |
| `@weather_revamped_alerts` | `off` | `on` fetches the alert address after each reading |
| `@weather_revamped_alert_url` | none | Alert address, with `{loc}` replaced by the place. Its first line that is not empty is the alert |
| `@weather_revamped_alert_prefix` | none | Text before `#{weather_alert}` |
| `@weather_revamped_notify` | `0` | `1` sends a desktop notification for a new alert |

### Display

| Option | Default | What it sets |
|:-------|:--------|:-------------|
| `@weather_revamped_hide_units` | `off` | `on` drops the `C` or `F` from `#{weather_temp}` |
| `@weather_revamped_fixed_width` | `off` | `on` pads the temperature to five characters |
| `@weather_revamped_temp_width` | none | Width of the temperature. It wins over the fixed width |
| `@weather_revamped_show_condition_icon` | `on` | `off` empties `#{weather_condition_icon}` |
| `@weather_revamped_<sky>_condition_icon` | a Nerd Font glyph | Icon of one sky: `clear`, `clouds`, `rain`, `snow`, `storm` or `fog` |
| `@weather_revamped_<sky>_tint` | yellow, brightblack, blue, white, magenta, brightblack | Style of one sky, in the order above |
| `@weather_revamped_<band>_color` | blue, cyan, green, green, yellow, red | Style of one band: `freezing` below 0, `cold` to 9, `cool` to 17, `comfortable` to 23, `hot` to 31, `very_hot` above, in Celsius |
| `@weather_revamped_<band>_icon` | none | Icon of one band |
| `@weather_revamped_uv_<level>_color` | green, yellow, colour208, red, magenta | Style of one UV level: `low` to 2, `moderate` to 5, `high` to 7, `very_high` to 10, `extreme` above |
| `@weather_revamped_stale_color` | `#[dim]` | Style of a stale reading |
| `@weather_revamped_umbrella_text` | none | Text of `#{weather_umbrella}`. `{chance}` becomes the rain chance |
| `@weather_revamped_umbrella_threshold` | `50` | Rain chance in percent from which the umbrella text shows |
| `@weather_revamped_pressure_delta` | `1` | hPa beyond which the pressure counts as rising or falling |
| `@weather_revamped_pressure_rising` | `^` | Rising mark |
| `@weather_revamped_pressure_falling` | `v` | Falling mark |
| `@weather_revamped_pressure_steady` | `=` | Steady mark |

### Render

| Option | Default | What it sets |
|:-------|:--------|:-------------|
| `@weather_revamped_render` | `jobs` | `options` makes each placeholder read a tmux option a background process fills |
| `@weather_revamped_interval` | `60` | Seconds between two ticks of that process |

### Internal state

The plugin keeps its state in tmux options, with no temp files. None of them is a setting.

| Option | Holds |
|:-------|:------|
| `@weather_revamped_value_<place>` | The stored reading of one place, with `_ts`, `_lock` and `_lock_ts` for the last try and the running fetch |
| `@weather_revamped_<place>_ok_ts` | The time of the last answer, read by `#{weather_stale_color}` |
| `@weather_revamped_<place>_pressure_prev` | The pressure of the fetch before, read by the trend |
| `@weather_revamped_alert_<place>` | The stored alert line of one place |
| `@weather_revamped_published` | The placeholders the status line uses, recorded at load |
| `@weather_revamped_out_<name>` | Each rendered value in the `options` mode |
| `@weather_revamped_ticker_pid` | The process that owns the `options` mode |

## Key bindings

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-w` | Forecast popup with the whole reading; Enter closes it | Bound |
| `@weather_revamped_refresh_key` | Fetches at once, in the background | Not bound |

`@weather_revamped_popup_key` names another key, and `off` binds none. The default key is left alone when something else already holds it, and `weather-revamped doctor` says so.

<a id="how-it-works"></a>

## How it works

[`weather-revamped.tmux`](weather-revamped.tmux) runs once when tmux loads the plugin. It records which placeholders `status-left` and `status-right` use in `@weather_revamped_published`, then replaces each one with a call to [`bin/weather-revamped`](bin/weather-revamped) or, in `options` mode, with an option read, and starts the background process.

In the default mode each `#()` call prints the stored reading at once. When the last try is older than the fetch interval, the call starts one fetch in the background and takes a lock, so only one fetch runs at a time. A fetch asks wttr.in for its `j1` answer with `curl`, keeps the 22 fields the plugin reads, and writes them with their times in one tmux call. An answer that says the location is unknown is dropped and the last reading stays.

The condition, the wind direction, the moon, the sun times and the alert have every `#` doubled before they reach the status line, so a text such as `#(cmd)` prints as text instead of running.

The fetch, the reader and every placeholder live in [`lib/weather.sh`](lib/weather.sh), and the settings table in [`lib/state.sh`](lib/state.sh).

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/weather.png" alt="weather-revamped: weather"><br><sub>The condition, the temperature, the wind and the humidity in the status line, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="weather-revamped: popup"><br><sub><code>prefix M-w</code> opens the forecast popup, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fahrenheit.png" alt="weather-revamped: fahrenheit"><br><sub><code>@weather_revamped_units</code> set to <code>u</code> switches to Fahrenheit and miles, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh-key.png" alt="weather-revamped: refresh-key"><br><sub><code>prefix R</code>, the refresh key, fetches at once, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="weather-revamped: options"><br><sub>In the <code>options</code> render mode each placeholder reads a tmux option, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="weather-revamped: list"><br><sub><code>list</code> prints what <code>apply</code> would send to tmux, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="weather-revamped: status"><br><sub><code>status</code> prints one placeholder, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/place.png" alt="weather-revamped: place"><br><sub><code>status</code> for a place given by hand, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="weather-revamped: card"><br><sub><code>card</code> prints the whole reading, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="weather-revamped: refresh"><br><sub><code>refresh</code> fetches now and says what wttr.in answered, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="weather-revamped: version"><br><sub><code>version</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="weather-revamped: doctor"><br><sub><code>doctor</code> names curl, the reading and the notifier, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="weather-revamped: error"><br><sub>A bad value stops the tool before anything runs, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="weather-revamped: accent"><br><sub>The menu with another accent, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="weather-revamped: plain-menu"><br><sub>Without gum the menu is numbered, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="weather-revamped: plain-doctor"><br><sub>Without gum <code>doctor</code> prints plain rows, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/details.png" alt="weather-revamped: details"><br><sub>Temperature, feels-like, wind, humidity, pressure with its trend and precipitation, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/forecast.png" alt="weather-revamped: forecast"><br><sub>Tomorrow, today, the rain chance and the umbrella text, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sky.png" alt="weather-revamped: sky"><br><sub>UV with its colour, the dew point and comfort, the moon and the sun, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/alert.png" alt="weather-revamped: alert"><br><sub>An alert line with its prefix, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="weather-revamped: temp"><br><sub>The sky's tint and icon, the band's colour and icon, hidden units and a fixed width, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="weather-revamped: help"><br><sub><code>help</code>, from <code>help.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="weather-revamped: themes"><br><sub>The eight themes, from <code>themes.tape</code></sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

The recordings run the real plugin and tmux. A small script stands in for `curl`, so the weather on screen is its own.

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | **this plugin**, Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
