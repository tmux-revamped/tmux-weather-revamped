#!/usr/bin/env bash
#
# weather.sh: command dispatcher for tmux-weather-revamped.
#
# A single background fetch of wttr.in/<loc>?format=j1 carries the whole reading.
# The hot path reads the cached JSON from a tmux user-option and the pure
# extractors in wttr-json.sh derive every placeholder from it, so no render ever
# waits on the network and no second request is made for the extra fields.
#
# Usage: weather.sh <subcommand> [location]
#   weather feels_like wind humidity pressure pressure_trend precip rain_chance
#   umbrella uv uv_color dew_point dew_comfort moon sunrise sunset forecast
#   today_high today_low tomorrow_high tomorrow_low temp color icon
#   condition_icon condition_tint stale_color alert popup popup_card doctor
#   refresh

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEATHER_CMD="${PLUGIN_DIR}/src/weather.sh"

export CACHE_PREFIX="weather_revamped"
export PLUGIN_LOG_NS="weather-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/publish.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/ticker.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/has-command.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/weather/weather.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/weather/wttr-json.sh"

# weather_max_age -> the refresh interval in seconds from @tmux-weather-interval.
weather_max_age() {
  local minutes
  minutes=$(get_tmux_option "@tmux-weather-interval" "15")
  [[ "${minutes}" =~ ^[0-9]+$ ]] || minutes=15
  echo $(( minutes * 60 ))
}

# _weather_units -> the configured unit family, metric by default.
_weather_units() {
  get_tmux_option "@tmux-weather-units" "m"
}

# _weather_loc_slug LOCATION -> a cache-key-safe slug, "auto" for the empty
# (IP-detected) location.
_weather_loc_slug() {
  local slug
  slug=$(printf '%s' "${1}" | tr -c 'A-Za-z0-9_' '_')
  [[ -z "${slug}" ]] && slug="auto"
  printf '%s' "${slug}"
}

# _weather_prev_pressure_opt SLUG -> the option holding the prior pressure read.
_weather_prev_pressure_opt() {
  echo "@${CACHE_PREFIX}_${1}_pressure_prev"
}

# _weather_ok_ts_opt SLUG -> the option holding the epoch of the last successful
# fetch. The cache timestamp re-stamps on failure to back off, so a separate
# stamp is what tells #{weather_stale_color} how long the host has been offline.
_weather_ok_ts_opt() {
  echo "@${CACHE_PREFIX}_${1}_ok_ts"
}

# _weather_success_age SLUG -> seconds since the last successful fetch for SLUG,
# or a large sentinel when none has succeeded.
_weather_success_age() {
  local ts now
  ts=$(get_tmux_option "$(_weather_ok_ts_opt "${1}")" "")
  if [[ ! "${ts}" =~ ^[0-9]+$ ]]; then
    echo 999999999
    return 0
  fi
  now=$(_cache_now)
  echo $(( now - ts ))
}

# weather_locations -> one location per line. A ;-separated @tmux-weather-locations
# wins; otherwise the single @tmux-weather-location, which may be empty for IP
# detection. Always emits at least one line.
weather_locations() {
  local raw
  raw=$(get_tmux_option "@tmux-weather-locations" "")
  if [[ -n "${raw}" ]]; then
    printf '%s\n' "${raw}" | tr ';' '\n'
  else
    printf '%s\n' "$(get_tmux_option "@tmux-weather-location" "")"
  fi
}

# weather_primary_location -> the first configured location.
weather_primary_location() {
  weather_locations | head -n 1
}

# weather_alerts_enabled -> 0 when @tmux-weather-alerts opts in to the second
# (severe-weather) endpoint. Off by default.
weather_alerts_enabled() {
  case "$(get_tmux_option "@tmux-weather-alerts" "off")" in
    on | 1 | yes | true) return 0 ;;
    *) return 1 ;;
  esac
}

# weather_alert_build_url LOCATION -> the configured alert endpoint with {loc}
# replaced, empty when @tmux-weather-alert-url is unset.
weather_alert_build_url() {
  local url loc
  url=$(get_tmux_option "@tmux-weather-alert-url" "")
  [[ -z "${url}" ]] && return 0
  loc="${1// /+}"
  printf '%s' "${url//\{loc\}/${loc}}"
}

# _read_alert URL -> the alert endpoint body. Host-probe seam; tests override it.
_read_alert() {
  curl -s --max-time "${WEATHER_TIMEOUT}" "${1}" 2>/dev/null
}

# weather_alert_fetch URL -> the first line of the alert body, empty on failure
# or when URL is empty.
weather_alert_fetch() {
  [[ -z "${1}" ]] && return 0
  _read_alert "${1}" | awk 'NF { print; exit }'
}

# weather_render_alert TEXT -> a badge for a non-empty alert, prefixed by the
# optional @weather_revamped_alert_prefix. Empty when there is no alert.
weather_render_alert() {
  [[ -z "${1}" ]] && return 0
  printf '%s%s' "$(get_tmux_option "@weather_revamped_alert_prefix" "")" "${1}"
}

# weather_refresh_loc LOCATION -> fetch the j1 reading for LOCATION into its cache
# key, keeping the last good value on failure. Records the prior pressure first
# so #{weather_pressure_trend} can compare across fetches.
weather_refresh_loc() {
  local loc="${1}" slug key url value prev
  slug=$(_weather_loc_slug "${loc}")
  key="value_${slug}"
  prev=$(wttr_pressure "$(cache_get "${key}")")
  [[ -n "${prev}" ]] && set_tmux_option "$(_weather_prev_pressure_opt "${slug}")" "${prev}"
  url=$(weather_build_url "${loc}" "$(_weather_units)" "j1")
  value=$(wttr_compact "$(weather_fetch "${url}")")
  if [[ -n "${value}" ]]; then
    cache_set "${key}" "${value}"
    set_tmux_option "$(_weather_ok_ts_opt "${slug}")" "$(_cache_now)"
  else
    cache_set "${key}" "$(cache_get "${key}")"
  fi
}

# weather_refresh_alert LOCATION -> fetch the severe-weather alert for LOCATION
# into its alert cache key. Always stores, so a cleared alert clears the badge.
weather_refresh_alert() {
  local loc="${1}" slug
  slug=$(_weather_loc_slug "${loc}")
  cache_set "alert_${slug}" "$(weather_alert_fetch "$(weather_alert_build_url "${loc}")")"
}

# weather_refresh [LOCATION] -> force a synchronous refresh of one location,
# defaulting to the primary. Used by the force-refresh key.
weather_refresh() {
  local loc="${1:-$(weather_primary_location)}"
  weather_refresh_loc "${loc}"
}

# weather_tick -> trigger a background refresh per configured location when its
# reading is stale, plus an alert refresh per location when alerts are enabled.
weather_tick() {
  local max loc
  max=$(weather_max_age)
  while IFS= read -r loc; do
    cache_refresh_if_stale "value_$(_weather_loc_slug "${loc}")" "${max}" \
      weather_refresh_loc "${loc}"
    if weather_alerts_enabled; then
      cache_refresh_if_stale "alert_$(_weather_loc_slug "${loc}")" "${max}" \
        weather_refresh_alert "${loc}"
    fi
  done < <(weather_locations)
}

# weather_popup_card JSON UNITS LOCATION -> a multi-line detail card built purely
# from the cached reading, with no re-probing.
weather_popup_card() {
  local json="${1}" units="${2}" loc="${3}" deg label suffix
  deg=$(printf '\xc2\xb0')
  suffix=$(_wttr_unit_suffix "${units}")
  label="${loc:-current location}"
  printf 'Weather: %s\n' "${label}"
  printf 'Now: %s %s%s%s (feels %s%s%s)\n' \
    "$(wttr_condition "${json}")" "$(wttr_temp "${json}" "${units}")" "${deg}" "${suffix}" \
    "$(wttr_feels_like "${json}" "${units}")" "${deg}" "${suffix}"
  printf 'Wind: %s   Humidity: %s%%\n' "$(wttr_wind "${json}" "${units}")" "$(wttr_humidity "${json}")"
  printf 'Pressure: %s hPa   UV: %s\n' "$(wttr_pressure "${json}")" "$(wttr_uv "${json}")"
  printf 'Dew point: %s%s%s (%s)\n' \
    "$(wttr_dewpoint "${json}" "${units}")" "${deg}" "${suffix}" \
    "$(weather_dew_comfort "$(wttr_dewpoint "${json}" m)")"
  printf 'Precip: %s mm   Rain chance: %s%%\n' "$(wttr_precip_mm "${json}")" "$(wttr_rain_chance "${json}")"
  printf 'Sun up %s / down %s   Moon: %s\n' \
    "$(wttr_sunrise "${json}")" "$(wttr_sunset "${json}")" "$(wttr_moon "${json}")"
  printf 'Today %s-%s%s%s   Tomorrow %s-%s%s%s\n' \
    "$(wttr_today_low "${json}" "${units}")" "$(wttr_today_high "${json}" "${units}")" "${deg}" "${suffix}" \
    "$(wttr_tomorrow_low "${json}" "${units}")" "$(wttr_tomorrow_high "${json}" "${units}")" "${deg}" "${suffix}"
}

# _tmux ARGS... -> tmux seam for the popup. Tests override it so no popup opens.
_tmux() {
  tmux "$@"
}

# weather_popup [LOCATION] -> open the detail card in a tmux popup (3.2+),
# rendered by re-invoking this script so the popup reads the same cache.
weather_popup() {
  local loc="${1:-$(weather_primary_location)}"
  _tmux display-popup -E "${WEATHER_CMD} popup_card ${loc}"
}

# weather_doctor -> a capability report: tooling, configuration, and which fields
# the current primary reading yields.
weather_doctor() {
  local loc slug json units
  loc=$(weather_primary_location)
  slug=$(_weather_loc_slug "${loc}")
  units=$(_weather_units)
  json=$(cache_get "value_${slug}")
  printf 'tmux-weather-revamped doctor\n'
  if has_command curl; then
    printf 'curl: found\n'
  else
    printf 'curl: MISSING (the fetch cannot run)\n'
  fi
  printf 'units: %s\n' "${units}"
  printf 'interval: %s min\n' "$(get_tmux_option "@tmux-weather-interval" "15")"
  if weather_alerts_enabled; then
    printf 'alerts: on\n'
  else
    printf 'alerts: off\n'
  fi
  printf 'locations:\n'
  weather_locations | awk 'BEGIN { i = 0 } { i++; printf "  %d. %s\n", i, ($0 == "" ? "(auto by IP)" : $0) }'
  if [[ -n "${json}" ]]; then
    printf 'reading: %s old, temp=%s condition=%s\n' \
      "$(cache_age "value_${slug}")s" "$(wttr_temp "${json}" "${units}")" "$(wttr_condition "${json}")"
  else
    printf 'reading: none yet (cold start or every fetch failed)\n'
  fi
}

weather_publish() {
  local token
  for token in $(get_tmux_option "@weather_revamped_published" ""); do
    publish_add "@weather_revamped_out_${token}" "$(main "${token}")"
  done
  publish_commit
}

_weather_reexec() { exec "${PLUGIN_DIR}/src/weather.sh" daemon; }

weather_daemon() {
  if ticker_run weather_revamped weather_publish "$$" 60; then
    _weather_reexec
  fi
}

main() {
  local cmd="${1:-}" arg="${2:-}"

  case "${cmd}" in
    refresh)    weather_refresh "${arg}"; return 0 ;;
    popup)      weather_popup "${arg}"; return 0 ;;
    doctor)     weather_doctor; return 0 ;;
    start)      ticker_start "${PLUGIN_DIR}/src/weather.sh"; return 0 ;;
    daemon)     weather_daemon; return 0 ;;
    popup_card)
      local pslug punits
      pslug=$(_weather_loc_slug "${arg:-$(weather_primary_location)}")
      punits=$(_weather_units)
      weather_popup_card "$(cache_get "value_${pslug}")" "${punits}" "${arg}"
      return 0
      ;;
  esac

  weather_tick

  local loc slug units json oneline
  loc="${arg:-$(weather_primary_location)}"
  slug=$(_weather_loc_slug "${loc}")
  units=$(_weather_units)
  json=$(cache_get "value_${slug}")
  oneline=$(wttr_oneline "${json}" "${units}")

  case "${cmd}" in
    weather)        printf '%s' "${oneline}" ;;
    temp)           publish_pad "$(weather_render_temp "${oneline}")" "$(publish_width weather_revamped temp 5)" ;;
    color)          weather_render_color "${oneline}" ;;
    icon)           weather_render_icon "${oneline}" ;;
    condition_icon) weather_render_condition_icon "${oneline}" ;;
    condition_tint) weather_condition_tint "${oneline}" ;;
    stale_color)
      if [[ -n "${json}" ]]; then
        weather_stale_color "$(_weather_success_age "${slug}")" "$(weather_max_age)"
      fi
      ;;
    feels_like)     wttr_feels_like "${json}" "${units}" ;;
    wind)           wttr_wind "${json}" "${units}" ;;
    humidity)       wttr_humidity "${json}" ;;
    pressure)       wttr_pressure "${json}" ;;
    pressure_trend) weather_pressure_trend "$(wttr_pressure "${json}")" \
                      "$(get_tmux_option "$(_weather_prev_pressure_opt "${slug}")" "")" ;;
    precip)         wttr_precip_mm "${json}" ;;
    rain_chance)    wttr_rain_chance "${json}" ;;
    umbrella)       weather_umbrella_hint "$(wttr_rain_chance "${json}")" ;;
    uv)             wttr_uv "${json}" ;;
    uv_color)       weather_uv_color "$(wttr_uv "${json}")" ;;
    dew_point)      wttr_dewpoint "${json}" "${units}" ;;
    dew_comfort)    weather_dew_comfort "$(wttr_dewpoint "${json}" m)" ;;
    moon)           wttr_moon "${json}" ;;
    sunrise)        wttr_sunrise "${json}" ;;
    sunset)         wttr_sunset "${json}" ;;
    forecast)       printf '%s-%s' "$(wttr_tomorrow_low "${json}" "${units}")" \
                      "$(wttr_tomorrow_high "${json}" "${units}")" ;;
    today_high)     wttr_today_high "${json}" "${units}" ;;
    today_low)      wttr_today_low "${json}" "${units}" ;;
    tomorrow_high)  wttr_tomorrow_high "${json}" "${units}" ;;
    tomorrow_low)   wttr_tomorrow_low "${json}" "${units}" ;;
    alert)          weather_render_alert "$(cache_get "alert_${slug}")" ;;
    *)              return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
