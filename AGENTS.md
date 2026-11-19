# tmux-weather-revamped

Guidance for anyone, human or agent, changing tmux-weather-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-weather-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`weather-revamped.tmux`](weather-revamped.tmux) | The entry point TPM runs: it runs `bin/weather-revamped apply` |
| [`bin/weather-revamped`](bin/weather-revamped) | The command: `apply`, `list`, `status`, `refresh`, `card`, `popup`, `daemon`, `doctor`, `version`, `help` and the menu. `apply`, `status`, `popup` and `daemon` run without loading the interface modules |
| [`lib/weather.sh`](lib/weather.sh) | Reading the settings and the stored reading of a place, the fetch with its alert and notification, the one awk run that reads a stored answer, every placeholder, the publisher's tick, the popup and the bindings |
| [`lib/state.sh`](lib/state.sh) | Every global, including `WEATHER_REVAMPED_SETTINGS`, the table of setting names and defaults, `WEATHER_REVAMPED_TOKENS`, the placeholder names, and `WEATHER_REVAMPED_KEPT`, the fields kept from an answer |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/readers.bats`](test/readers.bats), [`test/weather.bats`](test/weather.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The fetch with the answers it drops, alerts, notifications, the status call and the tick; every placeholder in both units; the bindings with both render modes, the daemon and the popup; and every command, against a stand-in tmux from [`test/weather_helpers.bash`](test/weather_helpers.bash) that keeps options in a file, with a stand-in `curl` that serves [`test/fixtures/wttr-london.j1.json`](test/fixtures/wttr-london.j1.json), a short answer, or [`test/fixtures/wttr-london-full.j1.json`](test/fixtures/wttr-london-full.j1.json), an answer as wttr.in sent it, 39,601 bytes |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with the popup key and the refresh key pressed through a second tmux attached to it, in both render modes; both share [`test/server_helpers.bash`](test/server_helpers.bash) |
| [`screens/`](screens) | The tapes and the recording's tmux config. `prepare.sh` copies the plugin to a neutral folder and writes a stand-in `curl` |
| [`examples/`](examples) | A status line to copy |

## Names

- Settings are the tmux options `@weather_revamped_<setting>` listed in `WEATHER_REVAMPED_SETTINGS`, the long options with dashes, such as `--fetch-minutes`, and the environment variables `WEATHER_REVAMPED_<SETTING>`.
- The stored reading of a place is `@weather_revamped_value_<place>` with `_ts`, `_lock` and `_lock_ts`, `@weather_revamped_<place>_ok_ts`, `@weather_revamped_<place>_pressure_prev` and `@weather_revamped_alert_<place>`. In those names the place has every character other than a plain letter, a digit or an underscore written as an underscore, one per byte, and no place is `auto`. `apply` writes `@weather_revamped_published`, the daemon `@weather_revamped_out_<name>` and `@weather_revamped_ticker_pid`. None of them is a setting.
- The placeholders are `#{weather}` and `#{weather_<name>}` for the 27 other names in `WEATHER_REVAMPED_TOKENS`; `status` names each one without the `weather_`, and the first one `weather`.
- The version constant is `WEATHER_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.

## Behaviour

- `apply` reads every setting with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends the bindings and the replaced status strings in one tmux call. When that call fails, it sends each command alone and `apply` exits 1.
- In `jobs` mode each placeholder in `status-left` or `status-right` becomes `#(<tool> status <name>)`, with the tool's path quoted for a shell and every `#` and `%` doubled, since tmux reads the status line both as a format and as a time format. In `options` mode it becomes `#{E:@weather_revamped_out_<name>}`, `apply` starts the daemon, and a status refresh starts no process. A string already rewritten is not written again, and the names it uses stay in `@weather_revamped_published`, so loading twice changes nothing.
- `status` makes two tmux reads and one `date` call: the settings, then the stored options of the one place it prints, whose names depend on a setting. It prints the stored reading at once. Only when the last try is older than `@weather_revamped_fetch_minutes`, and no fetch from the last 30 seconds is under way, does it start one in the background through the shared cache module.
- A fetch asks wttr.in once, keeps the fields it reads, and writes the reading, its times and the previous pressure in one tmux call. With alerts on, the alert is written in a second call, since tmux refuses a command of more than about 16 kB and an alert has no size limit, while a reading is about 9 kB. A stored answer is read by one awk run per call.
- The daemon is the shared ticker: it claims `@weather_revamped_ticker_pid`, fetches every stale place of the list in its own shell, publishes every name in `@weather_revamped_published` for the first place in one tmux call per tick, with an alert of more than 1,000 characters in a call of its own so that it cannot push the others past tmux's limit, sleeps for `@weather_revamped_interval`, and ends when another process holds the claim or the server is gone. At the ticker's tick cap it starts itself again.
- `M-w` opens `card` in a popup that waits for Enter, 70 by 80 percent of the window, which holds the card's 13 rows on a terminal of 24 lines. A key set to `off` binds nothing. Only the default key is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it. On a tmux older than 3.2 the key says why it opens nothing.
- The refresh key runs `refresh` through `run-shell -b` with its output dropped, since a `run-shell` that prints opens tmux's own output screen and a fetch can take ten seconds.
- A setting `apply` got from the command line or the environment rides, as an option, on both keys and on every status call; `WEATHER_REVAMPED_CARRIED` lists the ones that ride. The daemon inherits the environment of the `apply` that started it.

## Domain rules

- The address is `https://wttr.in/<place>?format=j1&m`, or `&u` for the units `u`, with each space of the place written as a plus sign. The fetch is `curl -s --max-time 10`.
- An answer holding `Unknown location`, `ERROR` or `Sorry` is dropped: the last reading stays, the time of the try moves, and the time of the last answer does not.
- An answer is cut down to the 22 fields in `WEATHER_REVAMPED_KEPT` and stored on one line, as `"key":"value"` pairs joined by commas. A reading stored over several lines is joined and read the same way.
- The first pair of a field is the current reading. Today and tomorrow are the first and second `maxtemp` and `mintemp`. The dew point is the truncated mean of the first eight `DewPoint` values and the rain chance the highest of the first eight `chanceofrain`.
- The line is the condition, a plus for a temperature that is not negative, the temperature, the degree sign and `C` or `F`. The condition, the wind direction, the moon, the sun times and the alert have every `#` doubled where a placeholder prints them; `card` prints them as read.
- The temperature band and the dew comfort always come from the Celsius values, whatever the units: below 0, to 9, to 17, to 23, to 31 and above for the band; below 13, to 15, to 18 and above for the comfort. The UV levels end at 2, 5, 7 and 10.
- The sky is read from the condition in lowercase, in this order: thunder or storm; snow, sleet, blizzard or ice; rain, drizzle or shower; fog, mist or haze; overcast or cloud; else clear.
- The previous pressure is stored only when a fetch succeeds over an older reading. The trend compares the two against `@weather_revamped_pressure_delta`.
- The fetch interval is `@weather_revamped_fetch_minutes`, in minutes as the bash version's was, so a value carried over keeps its meaning. Zero is an unknown value: the default of 15 applies and `doctor` names it. A number is read as decimal whatever zeros lead it.
- The stale colour prints once the last answer is older than three fetch intervals, and only with a reading.
- The alert is the first line that is not empty of `@weather_revamped_alert_url`, with `{loc}` replaced by the place. With `@weather_revamped_notify` at `1`, an alert that differs from the stored one is sent through [`lib/notify.sh`](lib/notify.sh). An alert tmux did not store is neither shown nor sent: the last one stays.
- Units are `m` or `u`; `f`, `F`, `fahrenheit`, `Fahrenheit` and `imperial` are read as `u`. An on or off setting reads `1`, `yes` and `true` as on, and `0`, `no` and `false` as off. A tmux option that holds any other value, or a number that is not whole, takes its default, and `doctor` names it in its `settings` row; the same value on the command line or in the environment stops the tool. An empty tmux option means its default, so a tint or a stale colour set to nothing prints its default.
- A check for plain characters writes the letters out one by one, since bash 3.2 takes an accented letter for part of `A-Z` in a UTF-8 locale.
- An argument that ends in `;` is sent as `\;`: tmux reads a bare trailing semicolon in an argument as a command separator. The command list keeps an empty argument as the marker in `WEATHER_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `WEATHER_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-18, none.
