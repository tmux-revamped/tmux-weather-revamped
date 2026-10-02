#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _WEATHER_REVAMPED_WTTR_JSON_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/weather/wttr-json.sh"
  J="$(cat "${BATS_TEST_DIRNAME}/../../fixtures/wttr-london.j1.json")"
  DEG="$(printf '\xc2\xb0')"
}

teardown() {
  cleanup_test_environment
}

@test "wttr-json.sh - functions are defined" {
  function_exists _wttr_value
  function_exists _wttr_int
  function_exists wttr_temp
  function_exists wttr_oneline
  function_exists wttr_dewpoint
}

@test "wttr-json.sh - _wttr_unit_suffix maps unit families" {
  [[ "$(_wttr_unit_suffix m)" == "C" ]]
  [[ "$(_wttr_unit_suffix c)" == "C" ]]
  [[ "$(_wttr_unit_suffix '')" == "C" ]]
  [[ "$(_wttr_unit_suffix u)" == "F" ]]
  [[ "$(_wttr_unit_suffix f)" == "F" ]]
  [[ "$(_wttr_unit_suffix Fahrenheit)" == "F" ]]
}

@test "wttr-json.sh - _wttr_value reads the first occurrence" {
  [[ "$(_wttr_value "${J}" humidity)" == "65" ]]
}

@test "wttr-json.sh - _wttr_value reads the nth occurrence" {
  [[ "$(_wttr_value "${J}" maxtempC 2)" == "27" ]]
}

@test "wttr-json.sh - _wttr_value is empty for a missing key" {
  [[ -z "$(_wttr_value "${J}" nope)" ]]
}

@test "wttr-json.sh - _wttr_value keeps colons in a time value" {
  [[ "$(_wttr_value "${J}" sunrise)" == "06:00 AM" ]]
}

@test "wttr-json.sh - _wttr_int strips units and is empty for non-numbers" {
  [[ "$(_wttr_int "${J}" temp_C)" == "18" ]]
  [[ -z "$(_wttr_int "${J}" nope)" ]]
}

@test "wttr-json.sh - _wttr_int is empty when the value has no digits" {
  local doc='"weird": "abc"'
  [[ -z "$(_wttr_int "${doc}" weird)" ]]
}

@test "wttr-json.sh - wttr_temp reads metric and imperial" {
  [[ "$(wttr_temp "${J}" m)" == "18" ]]
  [[ "$(wttr_temp "${J}" u)" == "64" ]]
}

@test "wttr-json.sh - wttr_feels_like reads metric and imperial" {
  [[ "$(wttr_feels_like "${J}" m)" == "16" ]]
  [[ "$(wttr_feels_like "${J}" u)" == "61" ]]
}

@test "wttr-json.sh - wttr_humidity reads the current humidity" {
  [[ "$(wttr_humidity "${J}")" == "65" ]]
}

@test "wttr-json.sh - wttr_pressure reads the current pressure" {
  [[ "$(wttr_pressure "${J}")" == "1013" ]]
}

@test "wttr-json.sh - wttr_precip_mm reads the precipitation figure" {
  [[ "$(wttr_precip_mm "${J}")" == "0.2" ]]
}

@test "wttr-json.sh - wttr_uv reads the UV index" {
  [[ "$(wttr_uv "${J}")" == "5" ]]
}

@test "wttr-json.sh - wttr_wind reports metric speed and direction" {
  [[ "$(wttr_wind "${J}" m)" == "11km/h NW" ]]
}

@test "wttr-json.sh - wttr_wind reports imperial speed and direction" {
  [[ "$(wttr_wind "${J}" u)" == "7mph NW" ]]
}

@test "wttr-json.sh - wttr_wind omits the direction when absent" {
  local doc='"windspeedKmph": "9"'
  [[ "$(wttr_wind "${doc}" m)" == "9km/h" ]]
}

@test "wttr-json.sh - wttr_wind is empty when speed is absent" {
  [[ -z "$(wttr_wind '"x": "1"' m)" ]]
}

@test "wttr-json.sh - wttr_condition reads the sky description" {
  [[ "$(wttr_condition "${J}")" == "Partly cloudy" ]]
}

@test "wttr-json.sh - wttr_moon reads today's moon phase" {
  [[ "$(wttr_moon "${J}")" == "Waning Gibbous" ]]
}

@test "wttr-json.sh - wttr_sunrise and wttr_sunset read today's times" {
  [[ "$(wttr_sunrise "${J}")" == "06:00 AM" ]]
  [[ "$(wttr_sunset "${J}")" == "06:45 PM" ]]
}

@test "wttr-json.sh - today and tomorrow highs and lows read the right day" {
  [[ "$(wttr_today_high "${J}" m)" == "25" ]]
  [[ "$(wttr_today_low "${J}" m)" == "14" ]]
  [[ "$(wttr_tomorrow_high "${J}" m)" == "27" ]]
  [[ "$(wttr_tomorrow_low "${J}" m)" == "15" ]]
  [[ "$(wttr_tomorrow_high "${J}" u)" == "81" ]]
}

@test "wttr-json.sh - wttr_dewpoint averages today's hourly metric dew points" {
  [[ "$(wttr_dewpoint "${J}" m)" == "12" ]]
}

@test "wttr-json.sh - wttr_dewpoint averages today's hourly imperial dew points" {
  [[ "$(wttr_dewpoint "${J}" u)" == "53" ]]
}

@test "wttr-json.sh - wttr_dewpoint is empty without hourly data" {
  [[ -z "$(wttr_dewpoint '"x": "1"' m)" ]]
}

@test "wttr-json.sh - wttr_rain_chance takes the worst of today's hours" {
  [[ "$(wttr_rain_chance "${J}")" == "60" ]]
}

@test "wttr-json.sh - wttr_rain_chance is empty without hourly data" {
  [[ -z "$(wttr_rain_chance '"x": "1"')" ]]
}

@test "wttr-json.sh - wttr_oneline builds a parseable metric summary" {
  [[ "$(wttr_oneline "${J}" m)" == "Partly cloudy +18${DEG}C" ]]
}

@test "wttr-json.sh - wttr_oneline builds an imperial summary" {
  [[ "$(wttr_oneline "${J}" u)" == "Partly cloudy +64${DEG}F" ]]
}

@test "wttr-json.sh - wttr_oneline omits a missing condition" {
  local doc='"temp_C": "7"'
  [[ "$(wttr_oneline "${doc}" m)" == "+7${DEG}C" ]]
}

@test "wttr-json.sh - wttr_oneline handles a negative temperature" {
  local doc='"weatherDesc":[{"value":"Light snow"}] "temp_C": "-3"'
  [[ "$(wttr_oneline "${doc}" m)" == *"-3${DEG}C" ]]
}

@test "wttr-json.sh - wttr_oneline is empty without a temperature" {
  [[ -z "$(wttr_oneline '"x": "1"' m)" ]]
}

@test "wttr-json - compaction keeps the fields the plugin reads" {
  local json
  json=$'{\n  "current_condition": [\n    {\n      "FeelsLikeC": "11",\n      "cloudcover": "100",\n      "temp_C": "12",\n      "weatherDesc": [\n        {\n          "value": "Patchy rain"\n        }\n      ]\n    }\n  ]\n}'

  run wttr_compact "${json}"

  [[ "${output}" == $'"FeelsLikeC":"11"\n"temp_C":"12"\n"value":"Patchy rain"' ]]
}

@test "wttr-json - extractors read the compacted document" {
  local json compact
  json=$'{\n  "temp_C": "12",\n  "humidity": "93",\n  "weatherDesc": [ { "value": "Clear" } ]\n}'
  compact="$(wttr_compact "${json}")"

  run wttr_oneline "${compact}" m

  [[ "${output}" == $'Clear +12\xc2\xb0C' ]]
}

@test "wttr-json - compaction drops structure and unread keys" {
  local json
  json=$'{\n  "nearest_area": [ { "latitude": "1.0" } ],\n  "humidity": "40"\n}'

  run wttr_compact "${json}"

  [[ "${output}" == '"humidity":"40"' ]]
}
