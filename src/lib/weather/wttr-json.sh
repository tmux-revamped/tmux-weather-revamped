#!/usr/bin/env bash
#
# wttr-json.sh: pure field extractors for the wttr.in j1 JSON document.
#
# One background fetch of wttr.in/<loc>?format=j1 carries the full reading:
# feels-like, wind, humidity, pressure, precip, UV, condition, today and
# tomorrow high/low, sunrise, sunset, moon phase, and the hourly dew point and
# rain chance. Every function here is pure: it takes the cached JSON string and
# echoes one field, with no I/O and no network. The hot path reads the cache and
# calls these, so a slow endpoint never blocks the render.
#
# wttr.in encodes every leaf value as a quoted string, so a single awk matcher
# pulls "key": "value" pairs. current_condition is the first object in the
# document, so the first occurrence of a shared key (humidity, pressure) is the
# current value; per-day keys (maxtempC, sunrise, moon_phase) take an occurrence
# index, with 1 = today and 2 = tomorrow.

[[ -n "${_WEATHER_REVAMPED_WTTR_JSON_LOADED:-}" ]] && return 0
_WEATHER_REVAMPED_WTTR_JSON_LOADED=1

# _wttr_unit_suffix UNITS -> C or F for the configured unit family.
_wttr_unit_suffix() {
  case "${1}" in
    u | f | F | fahrenheit | Fahrenheit | imperial) echo "F" ;;
    *) echo "C" ;;
  esac
}

# _wttr_value JSON KEY [OCCURRENCE] -> the OCCURRENCE-th (default 1) value for
# KEY, empty when absent. KEY is a plain JSON key with no regex metacharacters.
_wttr_value() {
  local json="${1}" key="${2}" occ="${3:-1}"
  printf '%s\n' "${json}" | awk -v k="${key}" -v want="${occ}" 'BEGIN { c = 0; pat = "\"" k "\"[ \t]*:[ \t]*\"[^\"]*\"" } match($0, pat) { c++; if (c == want) { s = substr($0, RSTART, RLENGTH); sub("^\"" k "\"[ \t]*:[ \t]*\"", "", s); sub("\"$", "", s); print s; exit } }'
}

# _wttr_int JSON KEY [OCCURRENCE] -> the value reduced to a signed integer.
_wttr_int() {
  local raw
  raw=$(_wttr_value "${1}" "${2}" "${3:-1}")
  [[ -z "${raw}" ]] && return 0
  printf '%s\n' "${raw}" | awk '{ gsub(/[^0-9-]/, "", $0); if ($0 ~ /^-?[0-9]+$/) print $0 + 0 }'
}

# wttr_temp JSON UNITS -> the current temperature integer for the unit family.
wttr_temp() {
  _wttr_int "${1}" "temp_$(_wttr_unit_suffix "${2}")"
}

# wttr_feels_like JSON UNITS -> the current feels-like temperature integer.
wttr_feels_like() {
  _wttr_int "${1}" "FeelsLike$(_wttr_unit_suffix "${2}")"
}

# wttr_humidity JSON -> the current relative humidity percentage.
wttr_humidity() {
  _wttr_int "${1}" "humidity"
}

# wttr_pressure JSON -> the current barometric pressure in hPa.
wttr_pressure() {
  _wttr_int "${1}" "pressure"
}

# wttr_precip_mm JSON -> the current precipitation figure in millimetres.
wttr_precip_mm() {
  _wttr_value "${1}" "precipMM"
}

# wttr_uv JSON -> the current UV index integer.
wttr_uv() {
  _wttr_int "${1}" "uvIndex"
}

# wttr_wind JSON UNITS -> "<speed><unit> <dir>", for example "11km/h NW".
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

# wttr_condition JSON -> the current sky condition words. current_condition holds
# the first weatherDesc, so the first "value" key is the live description.
wttr_condition() {
  _wttr_value "${1}" "value"
}

# wttr_moon JSON -> today's moon phase words.
wttr_moon() {
  _wttr_value "${1}" "moon_phase"
}

# wttr_sunrise JSON -> today's sunrise clock time.
wttr_sunrise() {
  _wttr_value "${1}" "sunrise"
}

# wttr_sunset JSON -> today's sunset clock time.
wttr_sunset() {
  _wttr_value "${1}" "sunset"
}

# wttr_today_high JSON UNITS -> today's forecast high integer.
wttr_today_high() {
  _wttr_int "${1}" "maxtemp$(_wttr_unit_suffix "${2}")" 1
}

# wttr_today_low JSON UNITS -> today's forecast low integer.
wttr_today_low() {
  _wttr_int "${1}" "mintemp$(_wttr_unit_suffix "${2}")" 1
}

# wttr_tomorrow_high JSON UNITS -> tomorrow's forecast high integer.
wttr_tomorrow_high() {
  _wttr_int "${1}" "maxtemp$(_wttr_unit_suffix "${2}")" 2
}

# wttr_tomorrow_low JSON UNITS -> tomorrow's forecast low integer.
wttr_tomorrow_low() {
  _wttr_int "${1}" "mintemp$(_wttr_unit_suffix "${2}")" 2
}

# wttr_dewpoint JSON UNITS -> the mean of today's first eight hourly dew points,
# rounded toward zero. wttr.in only carries dew point per hour, so an average is
# the single representative comfort number.
wttr_dewpoint() {
  local json="${1}" key
  key="DewPoint$(_wttr_unit_suffix "${2}")"
  printf '%s\n' "${json}" | awk -v k="${key}" 'BEGIN { n = 0; sum = 0; pat = "\"" k "\"[ \t]*:[ \t]*\"[^\"]*\"" } match($0, pat) { if (n < 8) { s = substr($0, RSTART, RLENGTH); gsub(/[^0-9-]/, "", s); if (s ~ /^-?[0-9]+$/) { sum += s; n++ } } } END { if (n > 0) printf "%d", sum / n }'
}

# wttr_rain_chance JSON -> the worst rain chance across today's first eight hours.
wttr_rain_chance() {
  printf '%s\n' "${1}" | awk 'BEGIN { n = 0; mx = 0; pat = "\"chanceofrain\"[ \t]*:[ \t]*\"[^\"]*\"" } match($0, pat) { if (n < 8) { s = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); if (s ~ /^[0-9]+$/ && s + 0 > mx) mx = s + 0; n++ } } END { if (n > 0) print mx }'
}

WTTR_KEPT_KEYS="temp_C temp_F FeelsLikeC FeelsLikeF humidity pressure precipMM uvIndex windspeedKmph windspeedMiles winddir16Point value moon_phase sunrise sunset maxtempC maxtempF mintempC mintempF DewPointC DewPointF chanceofrain"

wttr_compact() {
  printf '%s\n' "${1}" | awk -v keep="${WTTR_KEPT_KEYS}" 'BEGIN { n = split(keep, list, " "); for (i = 1; i <= n; i++) wanted[list[i]] = 1 } match($0, /"[A-Za-z_0-9]+"[ \t]*:[ \t]*"[^"]*"/) { s = substr($0, RSTART, RLENGTH); k = s; sub(/^"/, "", k); sub(/".*/, "", k); if (k in wanted) { sub(/"[ \t]*:[ \t]*"/, "\":\"", s); print s } }'
}

# wttr_oneline JSON UNITS -> a "<condition> +<temp>(deg)<U>" summary that the
# text renderers parse, keeping the legacy #{weather} placeholder working off the
# new JSON source. Empty when no temperature is present.
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
