#!/usr/bin/env bash
#
# weather.sh: weather string acquisition from wttr.in.
#
# weather_build_url is pure. The network fetch lives behind a seam and runs only
# inside the background worker, so a slow or down endpoint never blocks the render.

[[ -n "${_WEATHER_REVAMPED_WEATHER_LOADED:-}" ]] && return 0
_WEATHER_REVAMPED_WEATHER_LOADED=1

_WEATHER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_WEATHER_SCRIPT_DIR}/../tmux/tmux-ops.sh"

# Seconds before the HTTP request is abandoned.
WEATHER_TIMEOUT="${WEATHER_TIMEOUT:-10}"

# weather_build_url LOCATION UNITS FORMAT -> a wttr.in request URL.
weather_build_url() {
  local location="${1}" units="${2}" format="${3}"
  # A place name with spaces, like "New York", breaks the bare URL. wttr.in
  # accepts a plus for each space, so encode them before building the request.
  location="${location// /+}"
  # Accept friendly aliases for the unit: Fahrenheit and Celsius spellings, plus
  # the wttr.in m and u flags. Anything unrecognized falls back to metric.
  local unit_flag
  case "${units}" in
    u | f | F | fahrenheit | Fahrenheit | imperial) unit_flag="&u" ;;
    *) unit_flag="&m" ;;
  esac
  echo "https://wttr.in/${location}?format=${format}${unit_flag}"
}

# Host-probe seam. Tests override this.
_read_weather() {
  curl -s --max-time "${WEATHER_TIMEOUT}" "${1}" 2>/dev/null
}

# weather_fetch URL -> the response body, empty on failure or a wttr.in error.
weather_fetch() {
  local body
  body=$(_read_weather "${1}")
  # wttr.in returns a plain error sentence when a location cannot be resolved.
  case "${body}" in
    *"Unknown location"*|*"ERROR"*|*"Sorry"*) echo "" ;;
    *) printf '%s' "${body}" ;;
  esac
}

# weather_temp_from_text TEXT -> the signed integer temperature, empty when none.
# A wttr.in one-line value carries the temperature as a signed number before a
# degree mark, for example "+18C clear" or "-3°C". The awk grabs the first such
# token and strips its sign-preserving prefix.
weather_temp_from_text() {
  local text="${1}"
  echo "${text}" | awk 'match($0, /[+-]?[0-9]+[^0-9A-Za-z ]*[CF]/) { s=substr($0, RSTART, RLENGTH); gsub(/[^0-9+-]/, "", s); print s+0; exit }'
}

# weather_band CELSIUS -> a temperature band name, empty when CELSIUS is not an
# integer. Thresholds are hardcoded: freezing <0, cold 0-9, cool 10-17,
# comfortable 18-23, hot 24-31, very_hot >=32.
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

# _weather_band_default_color BAND -> the built-in color for a band.
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

# weather_render_color TEXT -> the tmux color style for the temperature in TEXT,
# read from @weather_revamped_<band>_color, empty when no band is parsed.
weather_render_color() {
  local band
  band=$(weather_band "$(weather_temp_from_text "${1}")")
  [[ -z "${band}" ]] && return 0
  get_tmux_option "@weather_revamped_${band}_color" "$(_weather_band_default_color "${band}")"
}

# weather_render_icon TEXT -> the icon for the temperature in TEXT, read from
# @weather_revamped_<band>_icon, empty by default so no Nerd Font is required.
weather_render_icon() {
  local band
  band=$(weather_band "$(weather_temp_from_text "${1}")")
  [[ -z "${band}" ]] && return 0
  get_tmux_option "@weather_revamped_${band}_icon" ""
}

# weather_temp_display_from_text TEXT -> the temperature token for display, with a
# leading plus removed, for example "Partly cloudy +25°C" -> "25°C".
weather_temp_display_from_text() {
  local tok
  tok=$(echo "${1}" | awk 'match($0, /[+-]?[0-9]+[^0-9A-Za-z ]*[CF]/) { print substr($0, RSTART, RLENGTH); exit }')
  printf '%s' "${tok#+}"
}

# weather_strip_units TOKEN -> the display token with the trailing C or F unit
# letter removed, keeping the degree mark, for example "25°C" -> "25°". Lets a
# crowded status bar show the number alone.
weather_strip_units() {
  printf '%s' "${1%[CF]}"
}

# weather_render_temp TEXT -> the temperature for display: the leading plus is
# always dropped, and when @tmux-weather-hide-units is on the C or F unit letter
# is dropped too.
weather_render_temp() {
  local disp
  disp=$(weather_temp_display_from_text "${1}")
  case "$(get_tmux_option "@tmux-weather-hide-units" "off")" in
    on | 1 | yes | true) weather_strip_units "${disp}" ;;
    *) printf '%s' "${disp}" ;;
  esac
}

# weather_condition_from_text TEXT -> the sky condition words, the part of TEXT
# before the temperature token, for example "Partly cloudy +25°C" -> "Partly
# cloudy". Empty when no temperature is present.
weather_condition_from_text() {
  echo "${1}" | awk 'match($0, /[+-]?[0-9]+[^0-9A-Za-z ]*[CF]/) { c=substr($0, 1, RSTART-1); gsub(/(^[ \t]+|[ \t]+$)/, "", c); print c; exit }'
}

# weather_condition_key CONDITION -> a normalized key. Storm and snow are checked
# before rain so "thundery rain" maps to storm and "sleet" to snow.
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

# weather_condition_default_icon KEY -> the built-in Nerd Font weather glyph,
# emitted through printf escapes so no literal glyph lives in the source.
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

# weather_render_condition_icon TEXT -> the Nerd Font glyph for the sky condition
# in TEXT, overridable via @weather_revamped_<key>_condition_icon.
weather_render_condition_icon() {
  # A single switch to hide the sky glyph without editing the status format.
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

# --- Presentation helpers for the enriched single-fetch reading ---------------
# These take already-extracted numbers or strings and turn them into status-bar
# tokens: bands, comfort words, hints, and trend marks. They stay pure so each
# is covered with fixture inputs and no network.

# weather_uv_band UV -> a UV exposure band, empty when UV is not an integer.
# Bands follow the WHO scale: low 0-2, moderate 3-5, high 6-7, very_high 8-10,
# extreme 11+.
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

# _weather_uv_default_color BAND -> the built-in color for a UV band.
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

# weather_uv_color UV -> the tmux color for the UV band, overridable through
# @weather_revamped_uv_<band>_color, empty when UV is not an integer.
weather_uv_color() {
  local band
  band=$(weather_uv_band "${1}")
  [[ -z "${band}" ]] && return 0
  get_tmux_option "@weather_revamped_uv_${band}_color" "$(_weather_uv_default_color "${band}")"
}

# weather_dew_comfort DEW_C -> a comfort word from the Celsius dew point: dry
# below 13, comfortable 13-15, humid 16-18, oppressive 19 and up. Empty when the
# dew point is not an integer.
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

# weather_umbrella_hint CHANCE -> the configured umbrella hint when the rain
# chance reaches @weather_revamped_umbrella_threshold (default 50), empty
# otherwise or when CHANCE is not an integer. The hint text defaults to empty so
# no glyph is required; set @weather_revamped_umbrella_text to enable it.
weather_umbrella_hint() {
  local chance="${1}" threshold
  [[ "${chance}" =~ ^[0-9]+$ ]] || return 0
  threshold=$(get_tmux_option "@weather_revamped_umbrella_threshold" "50")
  [[ "${threshold}" =~ ^[0-9]+$ ]] || threshold=50
  (( chance >= threshold )) || return 0
  get_tmux_option "@weather_revamped_umbrella_text" ""
  return 0
}

# weather_pressure_trend CURRENT PREVIOUS -> a trend mark comparing two pressure
# readings: rising, falling, or steady within @weather_revamped_pressure_delta
# (default 1) hPa. Marks default to ASCII and are overridable. Empty when either
# reading is not an integer.
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

# weather_condition_tint TEXT -> a tmux color override for the sky condition in
# TEXT, read from @weather_revamped_<key>_tint, empty when none is configured.
# Lets rain or storm paint the whole segment without touching the band color.
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

# weather_stale_color AGE MAX_AGE -> a dim style when the reading is older than
# three refresh intervals, signalling a long offline stretch. Empty while fresh
# or when either argument is not an integer. Overridable via
# @weather_revamped_stale_color.
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
