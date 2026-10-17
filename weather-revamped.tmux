#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEATHER_CMD="${PLUGIN_DIR}/src/weather.sh"

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
  local value="${1}" token placeholder target
  for token in ${WEATHER_TOKENS}; do
    placeholder="$(placeholder_for "${token}")"
    target="$(target_for "${token}")"
    value=${value//"${placeholder}"/"${target}"}
  done
  echo "${value}"
}

used_tokens() {
  local text="${1}" token used=""
  for token in ${WEATHER_TOKENS}; do
    case "${text}" in
      *"$(placeholder_for "${token}")"* | *"@weather_revamped_out_${token}}"*) used="${used:+${used} }${token}" ;;
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
else
  tmux set-option -gqu "@weather_revamped_ticker_pid"
fi

HASH="#"
QUOTED_CMD=$(printf '%q' "${WEATHER_CMD}")
QUOTED_CMD="${QUOTED_CMD//"${HASH}"/${HASH}${HASH}}"

POPUP_KEY=$(tmux show-option -gqv "@tmux-weather-popup-key")
[ -z "${POPUP_KEY}" ] && POPUP_KEY="M-w"
[ "${POPUP_KEY}" != "off" ] && tmux bind-key "${POPUP_KEY}" run-shell "${QUOTED_CMD} popup"

REFRESH_KEY=$(tmux show-option -gqv "@tmux-weather-refresh-key")
[ -n "${REFRESH_KEY}" ] && tmux bind-key "${REFRESH_KEY}" run-shell "${QUOTED_CMD} refresh"

true
