# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `@weather_revamped_render 'options'` replaces the `#()` calls with tmux
  option reads, written by one background process per server every
  `@weather_revamped_interval` seconds, 60 by default, so the values change together.
- `@weather_revamped_fixed_width 'on'` pads the temperature to five characters,
  and `@weather_revamped_temp_width` sets the width directly.

### Changed

- The options-mode background process reads every option it needs in one tmux
  call per tick, sends its cache writes and published values in a second, and
  keeps its functions out of the environment of the commands it runs. Options
  mode ticks every `@weather_revamped_interval` seconds, 60 by default.
- `#{weather_condition_tint}` has a default color per condition instead of
  rendering empty, and an empty option turns one off.
- The condition icons are Material Design weather glyphs, which read more
  clearly at status-bar size than the Weather Icons set.

### Fixed

- Every placeholder rendered empty. The full wttr.in JSON, about 40 KB, was
  stored in a tmux option, and tmux refuses a set command over about 15 KB, so
  the cache never filled. The fetch now keeps only the fields the plugin reads,
  in their original order, about 9 KB.
- The compacted cache kept only the first field on each line, so an hourly
  entry written on one line lost its dew point and rain chance. Every field on
  a line is now kept.

## [1.3.0] - 2026-06-30

### Added

- One background fetch now pulls the full reading. The worker requests the
  wttr.in `j1` JSON once and the hot path derives every placeholder from the
  cached document, with no second request and no temp files. New placeholders:
  `#{weather_feels_like}`, `#{weather_wind}`, `#{weather_humidity}`,
  `#{weather_pressure}`, `#{weather_pressure_trend}`, `#{weather_precip}`,
  `#{weather_rain_chance}`, `#{weather_umbrella}`, `#{weather_uv}`,
  `#{weather_uv_color}`, `#{weather_dew_point}`, `#{weather_dew_comfort}`,
  `#{weather_moon}`, `#{weather_sunrise}`, `#{weather_sunset}`,
  `#{weather_forecast}`, `#{weather_today_high}`, `#{weather_today_low}`,
  `#{weather_tomorrow_high}`, `#{weather_tomorrow_low}`,
  `#{weather_condition_tint}`, and `#{weather_stale_color}`.
- UV index bands with per-band colors, and a dew-point comfort word, both parsed
  from the same reading.
- A barometric pressure trend mark that compares the latest reading against the
  previous fetch.
- Multiple locations via `@tmux-weather-locations`, a `;`-separated list. Each
  location runs its own background worker into its own cache option, and every
  placeholder accepts a location name as an argument.
- An opt-in severe-weather alert badge, off by default. Set
  `@tmux-weather-alerts` and `@tmux-weather-alert-url` to fetch a second endpoint
  in its own worker and surface `#{weather_alert}`.
- A detail popup built from the cached reading, bound to `@tmux-weather-popup-key`
  when set, plus a force-refresh key via `@tmux-weather-refresh-key`.
- A `doctor` subcommand that reports tooling, configuration, and which fields the
  current reading yields.

### Changed

- The single fetch now requests the `j1` JSON document instead of a one-line
  format string, which is what lets one request carry feels-like, wind,
  humidity, sun and moon times, UV, dew point, pressure, precipitation, and the
  tomorrow forecast together. `#{weather}` and `#{weather_temp}` are unchanged on
  screen, derived from the JSON.

## [1.2.0] - 2026-06-23

### Added

- `@tmux-weather-hide-units` drops the C or F unit letter from `#{weather_temp}`
  for a tighter status bar (upstream tmux-weather PR #4).

### Fixed

- A place name with spaces, like `New York`, now builds a valid request URL
  instead of breaking on the bare space (upstream tmux-weather #14).
- Temperature parsing no longer depends on the awk locale. The optional degree
  mark was matched as a multibyte literal, which failed under a byte-oriented
  awk such as mawk and dropped readings that had no degree symbol. The pattern
  now uses a portable character class.

### Changed

- Reviewed the upstream `ilya-manin/tmux-weather` issues. The leading plus on a
  positive temperature is already stripped (#13), an empty location already
  auto-detects by IP (PR #16), and the background-fetch design already avoids the
  "no server running" startup spam (#18).

## [1.1.0] - 2026-06-20

### Added

- The `#{weather_color}` and `#{weather_icon}` placeholders, which color and
  icon the reading by temperature band. Bands range from freezing through
  very_hot, each with a configurable color and icon, parsed from the cached
  value with no extra fetch.

## [1.0.0] - 2026-06-19

### Added

- The `#{weather}` placeholder, backed by wttr.in.
- Non-blocking design: `curl` runs with a hard timeout inside a background worker
  and the status line reads a cached tmux user-option, with no temp files.
- Configurable location, units, one-line format, and fetch interval.
- A failed fetch keeps the last good reading on screen.
