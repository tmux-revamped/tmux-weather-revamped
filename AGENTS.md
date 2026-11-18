# tmux-weather-revamped

Guidance for anyone, human or agent, changing tmux-weather-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-weather-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`weather-revamped.tmux`](weather-revamped.tmux) | The entry point TPM runs |
| [`src/weather.sh`](src/weather.sh) | The script the placeholders, keys and popups call |
| [`src/lib/weather/`](src/lib/weather) | This member's modules |
| [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) | This member's constants, including its version |
| [`src/lib/utils/`](src/lib/utils), [`src/lib/tmux/`](src/lib/tmux) | The shared library. Every file there except `constants.sh` is identical in every member |
| [`test/`](test) | The bats suite. `helpers.bash` and `tmux_helpers.bash` are identical in every member; this member's own mocks go in the `_local` files. [`test/entry/keys.bats`](test/entry/keys.bats) presses the popup and refresh keys through a second tmux attached to a private server, with a stand-in `curl` |

## Names

- Settings are meant to be tmux options named `@weather_revamped_<setting>`; see the gaps for the ones that are not yet.
- Placeholders include `#{weather_temp}`.
- Public functions carry `weather_`; private ones start with `_`.
- The version constant is `WEATHER_REVAMPED_VERSION`.
- Its command-line tool, once it exists, is `weather-revamped`.

## Behaviour

- Shows weather from wttr.in in the status line, fetched in the background so the status line never waits.
- `M-w` opens the forecast popup, a card that stays until Enter: the popup's command waits on a `read` after the card, since `display-popup -E` closes the moment its command ends.
- At load the entry point replaces each placeholder with a `#()` call, or with an option read in render mode. A stored reading older than the interval starts a detached refresh.

## Domain rules

- A response containing `Unknown location`, `ERROR` or `Sorry` is discarded and the previous reading stays.
- A successful response is cut down to the 22 JSON fields the plugin reads, about 9 KB instead of the 40 KB wttr.in sends.
- The condition text and the alert line have every `#` doubled.

## Release

- `WEATHER_REVAMPED_VERSION` in [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) holds the version. Nobody edits it by hand.
- After a green `Tests` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release from [`.releaserc.json`](.releaserc.json): a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17:

- Every script is bash, under `#!/usr/bin/env bash`, not POSIX `sh`, so it is untested under `dash`, `zsh` and BusyBox `sh`.
- The code lives in [`src/`](src) and [`src/lib/`](src/lib); there is no `bin/weather-revamped`, `lib/state.sh` or `lib/core.sh`.
- No `weather-revamped` command with `help`, `version` and `doctor` in the family's form, no man page, no completions and no `manifest.json`.
- No gum interface: no `lib/ui.sh`, `lib/table.awk`, themes or `test/bin/gum`.
- No `screens/`: no VHS recording of each feature, no on-screen caption of the keys each recording presses, and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- Coverage is kcov with a 95 percent floor on Linux, not bashcov at 100 percent merged from macOS and Linux.
- CI tests GNU, BSD and uutils tools in `tests.yml`, but not the six toolsets through `.github/scripts/toolset.sh`, and no shell matrix under `sh`, `dash`, `bash` and `zsh`.
- No golden transcripts, `call.sh`, `run-matrix.sh` or `linux-container.sh`.
- [`release.yml`](.github/workflows/release.yml) follows `Tests` and has no `recover` job, and [`.releaserc.json`](.releaserc.json) and `set-version.sh` name `src/lib/utils/constants.sh`, so the three differ from the family's copies; there is no `ci-state.sh`, `recover.sh`, `bot-merge.yml` or Renovate.
- CI is `tests.yml` and `security.yml`, not `ci.yml`, and no job starts with `step-security/harden-runner`.
- No `.editorconfig`, `.yamllint.yml` or shfmt; the Makefile has `help`, `test`, `test-unit`, `coverage`, `lint` and `clean`, not the family's targets.
- Its settings are named `@tmux-weather-*`, such as `@tmux-weather-location`, outside the `@weather_revamped_*` pattern.
- No `@weather_revamped_notify` for a severe-weather alert yet.
- `get_tmux_option` keeps a tmux option set to nothing as an empty value, where FAMILY.md has it mean the default; the ticker's own reader already takes the default.
