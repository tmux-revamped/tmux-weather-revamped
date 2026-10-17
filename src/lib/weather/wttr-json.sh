#!/usr/bin/env bash

[[ -n "${_WEATHER_REVAMPED_WTTR_JSON_LOADED:-}" ]] && return 0
_WEATHER_REVAMPED_WTTR_JSON_LOADED=1

_wttr_unit_suffix() {
  case "${1}" in
    u | f | F | fahrenheit | Fahrenheit | imperial) echo "F" ;;
    *) echo "C" ;;
  esac
}

_wttr_value() {
  local json="${1}" key="${2}" occ="${3:-1}"
  printf '%s\n' "${json}" | awk -v k="${key}" -v want="${occ}" 'BEGIN { c = 0; pat = "\"" k "\"[ \t]*:[ \t]*\"[^\"]*\"" } match($0, pat) { c++; if (c == want) { s = substr($0, RSTART, RLENGTH); sub("^\"" k "\"[ \t]*:[ \t]*\"", "", s); sub("\"$", "", s); print s; exit } }'
}

_wttr_int() {
  local raw
  raw=$(_wttr_value "${1}" "${2}" "${3:-1}")
  [[ -z "${raw}" ]] && return 0
  printf '%s\n' "${raw}" | awk '{ gsub(/[^0-9-]/, "", $0); if ($0 ~ /^-?[0-9]+$/) print $0 + 0 }'
}

wttr_temp() {
  _wttr_int "${1}" "temp_$(_wttr_unit_suffix "${2}")"
}

wttr_feels_like() {
  _wttr_int "${1}" "FeelsLike$(_wttr_unit_suffix "${2}")"
}

wttr_humidity() {
  _wttr_int "${1}" "humidity"
}

wttr_pressure() {
  _wttr_int "${1}" "pressure"
}

wttr_precip_mm() {
  _wttr_value "${1}" "precipMM"
}

wttr_uv() {
  _wttr_int "${1}" "uvIndex"
}

wttr_wind() {
  local json="${1}" units="${2}" speed dir unit key
  if [[ "$(_wttr_unit_suffix "${units}")" == "F" ]]; then
    key="windspeedMiles"
    unit="mph"
  else
    key="windspeedKmph"
    unit="km/h"
  fi
  speed=$(_wttr_int "${json}" "${key}")
  [[ -z "${speed}" ]] && return 0
  dir=$(_wttr_value "${json}" "winddir16Point")
  if [[ -n "${dir}" ]]; then
    printf '%s%s %s' "${speed}" "${unit}" "${dir}"
  else
    printf '%s%s' "${speed}" "${unit}"
  fi
}

wttr_condition() {
  _wttr_value "${1}" "value"
}

wttr_moon() {
  _wttr_value "${1}" "moon_phase"
}

wttr_sunrise() {
  _wttr_value "${1}" "sunrise"
}

wttr_sunset() {
  _wttr_value "${1}" "sunset"
}

wttr_today_high() {
  _wttr_int "${1}" "maxtemp$(_wttr_unit_suffix "${2}")" 1
}

wttr_today_low() {
  _wttr_int "${1}" "mintemp$(_wttr_unit_suffix "${2}")" 1
}

wttr_tomorrow_high() {
  _wttr_int "${1}" "maxtemp$(_wttr_unit_suffix "${2}")" 2
}

wttr_tomorrow_low() {
  _wttr_int "${1}" "mintemp$(_wttr_unit_suffix "${2}")" 2
}

wttr_dewpoint() {
  local json="${1}" key
  key="DewPoint$(_wttr_unit_suffix "${2}")"
  printf '%s\n' "${json}" | awk -v k="${key}" 'BEGIN { n = 0; sum = 0; pat = "\"" k "\"[ \t]*:[ \t]*\"[^\"]*\"" } match($0, pat) { if (n < 8) { s = substr($0, RSTART, RLENGTH); gsub(/[^0-9-]/, "", s); if (s ~ /^-?[0-9]+$/) { sum += s; n++ } } } END { if (n > 0) printf "%d", sum / n }'
}

wttr_rain_chance() {
  printf '%s\n' "${1}" | awk 'BEGIN { n = 0; mx = 0; pat = "\"chanceofrain\"[ \t]*:[ \t]*\"[^\"]*\"" } match($0, pat) { if (n < 8) { s = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); if (s ~ /^[0-9]+$/ && s + 0 > mx) mx = s + 0; n++ } } END { if (n > 0) print mx }'
}

WTTR_KEPT_KEYS="temp_C temp_F FeelsLikeC FeelsLikeF humidity pressure precipMM uvIndex windspeedKmph windspeedMiles winddir16Point value moon_phase sunrise sunset maxtempC maxtempF mintempC mintempF DewPointC DewPointF chanceofrain"

wttr_compact() {
  printf '%s\n' "${1}" | awk -v keep="${WTTR_KEPT_KEYS}" 'BEGIN { n = split(keep, list, " "); for (i = 1; i <= n; i++) wanted[list[i]] = 1 } { rest = $0; while (match(rest, /"[A-Za-z_0-9]+"[ \t]*:[ \t]*"[^"]*"/)) { s = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH); k = s; sub(/^"/, "", k); sub(/".*/, "", k); if (k in wanted) { sub(/"[ \t]*:[ \t]*"/, "\":\"", s); print s } } }'
}

wttr_oneline() {
  local json="${1}" units="${2}" cond temp suffix sign
  suffix=$(_wttr_unit_suffix "${units}")
  temp=$(wttr_temp "${json}" "${units}")
  [[ -z "${temp}" ]] && return 0
  cond=$(wttr_condition "${json}")
  sign=""
  [[ "${temp}" =~ ^[0-9] ]] && sign="+"
  if [[ -n "${cond}" ]]; then
    printf '%s %s%s\xc2\xb0%s' "${cond}" "${sign}" "${temp}" "${suffix}"
  else
    printf '%s%s\xc2\xb0%s' "${sign}" "${temp}" "${suffix}"
  fi
}

export -f _wttr_unit_suffix
export -f _wttr_value
export -f wttr_compact
export -f _wttr_int
export -f wttr_temp
export -f wttr_feels_like
export -f wttr_humidity
export -f wttr_pressure
export -f wttr_precip_mm
export -f wttr_uv
export -f wttr_wind
export -f wttr_condition
export -f wttr_moon
export -f wttr_sunrise
export -f wttr_sunset
export -f wttr_today_high
export -f wttr_today_low
export -f wttr_tomorrow_high
export -f wttr_tomorrow_low
export -f wttr_dewpoint
export -f wttr_rain_chance
export -f wttr_oneline
