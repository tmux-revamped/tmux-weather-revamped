#!/usr/bin/env bash

[[ -n "${_WEATHER_REVAMPED_WEATHER_LOADED:-}" ]] && return 0
_WEATHER_REVAMPED_WEATHER_LOADED=1

_WEATHER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_WEATHER_SCRIPT_DIR}/../tmux/tmux-ops.sh"

WEATHER_TIMEOUT="${WEATHER_TIMEOUT:-10}"

weather_build_url() {
  local location="${1}" units="${2}" format="${3}"
  location="${location// /+}"
  local unit_flag
  case "${units}" in
    u | f | F | fahrenheit | Fahrenheit | imperial) unit_flag="&u" ;;
    *) unit_flag="&m" ;;
  esac
  echo "https://wttr.in/${location}?format=${format}${unit_flag}"
}

_read_weather() {
  curl -s --max-time "${WEATHER_TIMEOUT}" "${1}" 2>/dev/null
}

weather_fetch() {
  local body
  body=$(_read_weather "${1}")
  case "${body}" in
    *"Unknown location"*|*"ERROR"*|*"Sorry"*) echo "" ;;
    *) printf '%s' "${body}" ;;
  esac
}

weather_temp_from_text() {
  local text="${1}"
  echo "${text}" | awk 'match($0, /[+-]?[0-9]+[^0-9A-Za-z ]*[CF]/) { s=substr($0, RSTART, RLENGTH); gsub(/[^0-9+-]/, "", s); print s+0; exit }'
}

weather_band() {
  local celsius="${1}"
  [[ "${celsius}" =~ ^-?[0-9]+$ ]] || return 0
  if (( celsius < 0 )); then
    echo "freezing"
  elif (( celsius <= 9 )); then
    echo "cold"
  elif (( celsius <= 17 )); then
    echo "cool"
  elif (( celsius <= 23 )); then
    echo "comfortable"
  elif (( celsius <= 31 )); then
    echo "hot"
  else
    echo "very_hot"
  fi
}

_weather_band_default_color() {
  case "${1}" in
    freezing)    echo "#[fg=blue]" ;;
    cold)        echo "#[fg=cyan]" ;;
    cool)        echo "#[fg=green]" ;;
    comfortable) echo "#[fg=green]" ;;
    hot)         echo "#[fg=yellow]" ;;
    very_hot)    echo "#[fg=red]" ;;
    *)           echo "" ;;
  esac
}

weather_render_color() {
  local band
  band=$(weather_band "$(weather_temp_from_text "${1}")")
  [[ -z "${band}" ]] && return 0
  get_tmux_option "@weather_revamped_${band}_color" "$(_weather_band_default_color "${band}")"
}

weather_render_icon() {
  local band
  band=$(weather_band "$(weather_temp_from_text "${1}")")
  [[ -z "${band}" ]] && return 0
  get_tmux_option "@weather_revamped_${band}_icon" ""
}

weather_temp_display_from_text() {
  local tok
  tok=$(echo "${1}" | awk 'match($0, /[+-]?[0-9]+[^0-9A-Za-z ]*[CF]/) { print substr($0, RSTART, RLENGTH); exit }')
  printf '%s' "${tok#+}"
}

weather_strip_units() {
  printf '%s' "${1%[CF]}"
}

weather_render_temp() {
  local disp
  disp=$(weather_temp_display_from_text "${1}")
  case "$(get_tmux_option "@tmux-weather-hide-units" "off")" in
    on | 1 | yes | true) weather_strip_units "${disp}" ;;
    *) printf '%s' "${disp}" ;;
  esac
}

weather_condition_from_text() {
  echo "${1}" | awk 'match($0, /[+-]?[0-9]+[^0-9A-Za-z ]*[CF]/) { c=substr($0, 1, RSTART-1); gsub(/(^[ \t]+|[ \t]+$)/, "", c); print c; exit }'
}

weather_condition_key() {
  local c
  c=$(printf '%s' "${1}" | tr '[:upper:]' '[:lower:]')
  case "${c}" in
    *thunder* | *storm*) echo "storm" ;;
    *snow* | *sleet* | *blizzard* | *ice*) echo "snow" ;;
    *rain* | *drizzle* | *shower*) echo "rain" ;;
    *fog* | *mist* | *haze*) echo "fog" ;;
    *overcast* | *cloud*) echo "clouds" ;;
    *) echo "clear" ;;
  esac
}

weather_condition_default_icon() {
  case "${1}" in
    clouds) printf '\xf3\xb0\x96\x90' ;;
    rain) printf '\xf3\xb0\x96\x97' ;;
    snow) printf '\xf3\xb0\x96\x98' ;;
    storm) printf '\xf3\xb0\x96\x93' ;;
    fog) printf '\xf3\xb0\x96\x91' ;;
    *)      printf '\xf3\xb0\x96\x99' ;;
  esac
}

weather_render_condition_icon() {
  case "$(get_tmux_option "@weather_revamped_show_condition_icon" "on")" in
    off | 0 | no | false) return 0 ;;
  esac
  local key
  key=$(weather_condition_key "$(weather_condition_from_text "${1}")")
  get_tmux_option "@weather_revamped_${key}_condition_icon" "$(weather_condition_default_icon "${key}")"
}

export -f weather_build_url
export -f _read_weather
export -f weather_fetch
export -f weather_temp_from_text
export -f weather_band
export -f _weather_band_default_color
export -f weather_render_color
export -f weather_render_icon
export -f weather_temp_display_from_text
export -f weather_strip_units
export -f weather_render_temp
export -f weather_condition_from_text
export -f weather_condition_key
export -f weather_condition_default_icon
export -f weather_render_condition_icon

weather_uv_band() {
  local uv="${1}"
  [[ "${uv}" =~ ^[0-9]+$ ]] || return 0
  if (( uv <= 2 )); then
    echo "low"
  elif (( uv <= 5 )); then
    echo "moderate"
  elif (( uv <= 7 )); then
    echo "high"
  elif (( uv <= 10 )); then
    echo "very_high"
  else
    echo "extreme"
  fi
}

_weather_uv_default_color() {
  case "${1}" in
    low)       echo "#[fg=green]" ;;
    moderate)  echo "#[fg=yellow]" ;;
    high)      echo "#[fg=colour208]" ;;
    very_high) echo "#[fg=red]" ;;
    extreme)   echo "#[fg=magenta]" ;;
    *)         echo "" ;;
  esac
}

weather_uv_color() {
  local band
  band=$(weather_uv_band "${1}")
  [[ -z "${band}" ]] && return 0
  get_tmux_option "@weather_revamped_uv_${band}_color" "$(_weather_uv_default_color "${band}")"
}

weather_dew_comfort() {
  local dew="${1}"
  [[ "${dew}" =~ ^-?[0-9]+$ ]] || return 0
  if (( dew < 13 )); then
    echo "dry"
  elif (( dew <= 15 )); then
    echo "comfortable"
  elif (( dew <= 18 )); then
    echo "humid"
  else
    echo "oppressive"
  fi
}

weather_umbrella_hint() {
  local chance="${1}" threshold text
  [[ "${chance}" =~ ^[0-9]+$ ]] || return 0
  threshold=$(get_tmux_option "@weather_revamped_umbrella_threshold" "50")
  [[ "${threshold}" =~ ^[0-9]+$ ]] || threshold=50
  (( chance >= threshold )) || return 0
  text=$(get_tmux_option "@weather_revamped_umbrella_text" "")
  text=${text//"{chance}"/"${chance}"}
  printf '%s\n' "${text}"
  return 0
}

weather_pressure_trend() {
  local cur="${1}" prev="${2}" delta
  [[ "${cur}" =~ ^-?[0-9]+$ ]] || return 0
  [[ "${prev}" =~ ^-?[0-9]+$ ]] || return 0
  delta=$(get_tmux_option "@weather_revamped_pressure_delta" "1")
  [[ "${delta}" =~ ^[0-9]+$ ]] || delta=1
  if (( cur - prev > delta )); then
    get_tmux_option "@weather_revamped_pressure_rising" "^"
  elif (( prev - cur > delta )); then
    get_tmux_option "@weather_revamped_pressure_falling" "v"
  else
    get_tmux_option "@weather_revamped_pressure_steady" "="
  fi
}

weather_condition_default_tint() {
  case "${1}" in
    storm)  printf '#[fg=magenta]' ;;
    snow)   printf '#[fg=white]' ;;
    rain)   printf '#[fg=blue]' ;;
    fog)    printf '#[fg=brightblack]' ;;
    clouds) printf '#[fg=brightblack]' ;;
    *)      printf '#[fg=yellow]' ;;
  esac
}

_weather_option_exists() {
  [[ -n "$(tmux show-option -gq "${1}" 2>/dev/null)" ]]
}

weather_condition_tint() {
  local key option
  key=$(weather_condition_key "$(weather_condition_from_text "${1}")")
  option="@weather_revamped_${key}_tint"
  if _weather_option_exists "${option}"; then
    tmux show-option -gqv "${option}" 2>/dev/null
  else
    weather_condition_default_tint "${key}"
  fi
  return 0
}

weather_stale_color() {
  local age="${1}" max_age="${2}"
  [[ "${age}" =~ ^[0-9]+$ ]] || return 0
  [[ "${max_age}" =~ ^[0-9]+$ ]] || return 0
  (( age > max_age * 3 )) || return 0
  get_tmux_option "@weather_revamped_stale_color" "#[dim]"
}

export -f weather_uv_band
export -f _weather_uv_default_color
export -f weather_uv_color
export -f weather_dew_comfort
export -f weather_umbrella_hint
export -f weather_pressure_trend
export -f weather_condition_default_tint
export -f _weather_option_exists
export -f weather_condition_tint
export -f weather_stale_color
