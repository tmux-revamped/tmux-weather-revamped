#!/usr/bin/env bash
#
# weather-revamped.tmux: TPM entry point.
#
# Replaces every #{weather*} placeholder in status-left and status-right with a
# call to the dispatcher. One background fetch carries the whole reading, so the
# render never waits on the network. Optionally binds a detail-popup key and a
# force-refresh key when the user sets them.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEATHER_CMD="${PLUGIN_DIR}/src/weather.sh"

# Every placeholder maps to the dispatcher subcommand of the same suffix. Listed
# longest-first is unnecessary because each token carries its closing brace, but
# the order is kept readable.
WEATHER_TOKENS="feels_like wind humidity pressure_trend pressure precip \
rain_chance umbrella uv_color uv dew_point dew_comfort moon sunrise sunset \
forecast today_high today_low tomorrow_high tomorrow_low condition_icon \
condition_tint stale_color alert color icon temp weather"

render_mode="$(tmux show-option -gqv "@weather_revamped_render")"

placeholder_for() {
  if [ "${1}" = "weather" ]; then
    printf '#{weather}'
  else
    printf '#{weather_%s}' "${1}"
  fi
}

target_for() {
  if [ "${render_mode}" = "options" ]; then
    printf '#{E:@weather_revamped_out_%s}' "${1}"
  else
    printf '#(%s %s)' "${WEATHER_CMD}" "${1}"
  fi
}

interpolate() {
  local value="${1}" token placeholder
  for token in ${WEATHER_TOKENS}; do
    placeholder="$(placeholder_for "${token}")"
    value="${value//${placeholder}/$(target_for "${token}")}"
  done
  echo "${value}"
}

used_tokens() {
  local text="${1}" token used=""
  for token in ${WEATHER_TOKENS}; do
    case "${text}" in
      *"$(placeholder_for "${token}")"*) used="${used:+${used} }${token}" ;;
    esac
  done
  echo "${used}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${WEATHER_CMD}" 2>/dev/null || true

status_text="$(tmux show-option -gqv status-left) $(tmux show-option -gqv status-right)"
tmux set-option -gq "@weather_revamped_published" "$(used_tokens "${status_text}")"

update_option "status-left"
update_option "status-right"

if [ "${render_mode}" = "options" ]; then
  "${WEATHER_CMD}" start 2>/dev/null || true
fi

# Opt-in key bindings. Unset by default so nothing clashes with user keys.
POPUP_KEY=$(tmux show-option -gqv "@tmux-weather-popup-key")
[ -n "${POPUP_KEY}" ] && tmux bind-key "${POPUP_KEY}" run-shell "${WEATHER_CMD} popup"

REFRESH_KEY=$(tmux show-option -gqv "@tmux-weather-refresh-key")
[ -n "${REFRESH_KEY}" ] && tmux bind-key "${REFRESH_KEY}" run-shell "${WEATHER_CMD} refresh"

true
