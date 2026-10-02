#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _WEATHER_REVAMPED_WEATHER_LOADED _WEATHER_REVAMPED_WTTR_JSON_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/weather.sh"
  FIXTURE="$(cat "${BATS_TEST_DIRNAME}/../../fixtures/wttr-london.j1.json")"
  export FIXTURE
  DEG="$(printf '\xc2\xb0')"
  # Default fetch seam returns the fixture, never the network.
  weather_fetch() { printf '%s' "${FIXTURE}"; }
  export -f weather_fetch
}

teardown() {
  cleanup_test_environment
}

@test "weather.sh dispatcher - functions are defined" {
  function_exists main
  function_exists weather_refresh
  function_exists weather_refresh_loc
  function_exists weather_tick
  function_exists weather_max_age
  function_exists weather_locations
  function_exists weather_primary_location
  function_exists weather_alerts_enabled
  function_exists weather_popup
  function_exists weather_popup_card
  function_exists weather_doctor
  function_exists _tmux
}

@test "weather.sh dispatcher - weather_max_age converts minutes to seconds" {
  [[ "$(weather_max_age)" == "900" ]]
}

@test "weather.sh dispatcher - weather_max_age honors the interval option" {
  set_tmux_option "@tmux-weather-interval" "5"
  [[ "$(weather_max_age)" == "300" ]]
}

@test "weather.sh dispatcher - weather_max_age defaults junk to 15 minutes" {
  set_tmux_option "@tmux-weather-interval" "abc"
  [[ "$(weather_max_age)" == "900" ]]
}

@test "weather.sh dispatcher - _weather_units defaults to metric" {
  [[ "$(_weather_units)" == "m" ]]
  set_tmux_option "@tmux-weather-units" "u"
  [[ "$(_weather_units)" == "u" ]]
}

@test "weather.sh dispatcher - _weather_loc_slug sanitizes and defaults to auto" {
  [[ "$(_weather_loc_slug "London")" == "London" ]]
  [[ "$(_weather_loc_slug "New York")" == "New_York" ]]
  [[ "$(_weather_loc_slug "")" == "auto" ]]
}

@test "weather.sh dispatcher - weather_locations falls back to the single location" {
  [[ "$(weather_locations)" == "" ]]
  set_tmux_option "@tmux-weather-location" "Tokyo"
  [[ "$(weather_locations)" == "Tokyo" ]]
}

@test "weather.sh dispatcher - weather_locations splits the list on semicolons" {
  set_tmux_option "@tmux-weather-locations" "London;Tokyo;New York"
  run weather_locations
  [[ "${lines[0]}" == "London" ]]
  [[ "${lines[1]}" == "Tokyo" ]]
  [[ "${lines[2]}" == "New York" ]]
}

@test "weather.sh dispatcher - weather_primary_location is the first entry" {
  set_tmux_option "@tmux-weather-locations" "London;Tokyo"
  [[ "$(weather_primary_location)" == "London" ]]
}

@test "weather.sh dispatcher - weather_refresh caches a successful fetch" {
  weather_refresh
  [[ "$(cache_get value_auto)" == "$(wttr_compact "${FIXTURE}")" ]]
}

@test "weather.sh dispatcher - weather_refresh keeps the last value on failure" {
  cache_set value_auto "Cloudy 18C"
  weather_fetch() { printf ''; }
  weather_refresh
  [[ "$(cache_get value_auto)" == "Cloudy 18C" ]]
}

@test "weather.sh dispatcher - weather_refresh_loc keys by location slug" {
  weather_refresh_loc "Tokyo"
  [[ "$(cache_get value_Tokyo)" == "$(wttr_compact "${FIXTURE}")" ]]
}

@test "weather.sh dispatcher - weather_refresh_loc records the prior pressure" {
  weather_refresh_loc "auto"
  weather_refresh_loc "auto"
  [[ "$(get_tmux_option "$(_weather_prev_pressure_opt auto)")" == "1013" ]]
}

@test "weather.sh dispatcher - weather subcommand renders the oneline summary" {
  run main weather
  [[ "${output}" == "Partly cloudy +18${DEG}C" ]]
}

@test "weather.sh dispatcher - temp subcommand renders the cached temperature" {
  run main temp
  [[ "${output}" == "18${DEG}C" ]]
}

@test "weather.sh dispatcher - color subcommand renders the band color" {
  run main color
  [[ "${output}" == "#[fg=green]" ]]
}

@test "weather.sh dispatcher - icon subcommand renders the band icon" {
  set_tmux_option "@weather_revamped_comfortable_icon" "MILD"
  run main icon
  [[ "${output}" == "MILD" ]]
}

@test "weather.sh dispatcher - condition_icon subcommand renders the sky glyph" {
  set_tmux_option "@weather_revamped_clouds_condition_icon" "CLD"
  run main condition_icon
  [[ "${output}" == "CLD" ]]
}

@test "weather.sh dispatcher - condition_tint subcommand reads the override" {
  set_tmux_option "@weather_revamped_clouds_tint" "#[fg=grey]"
  run main condition_tint
  [[ "${output}" == "#[fg=grey]" ]]
}

@test "weather.sh dispatcher - feels_like subcommand reads the JSON" {
  run main feels_like
  [[ "${output}" == "16" ]]
}

@test "weather.sh dispatcher - wind subcommand reads the JSON" {
  run main wind
  [[ "${output}" == "11km/h NW" ]]
}

@test "weather.sh dispatcher - humidity subcommand reads the JSON" {
  run main humidity
  [[ "${output}" == "65" ]]
}

@test "weather.sh dispatcher - pressure subcommand reads the JSON" {
  run main pressure
  [[ "${output}" == "1013" ]]
}

@test "weather.sh dispatcher - pressure_trend compares against the stored prior" {
  cache_set value_auto "${FIXTURE}"
  set_tmux_option "$(_weather_prev_pressure_opt auto)" "1009"
  run main pressure_trend
  [[ "${output}" == "^" ]]
}

@test "weather.sh dispatcher - precip subcommand reads the JSON" {
  run main precip
  [[ "${output}" == "0.2" ]]
}

@test "weather.sh dispatcher - rain_chance subcommand reads the worst hour" {
  run main rain_chance
  [[ "${output}" == "60" ]]
}

@test "weather.sh dispatcher - umbrella subcommand fires above the threshold" {
  set_tmux_option "@weather_revamped_umbrella_text" "umbrella"
  run main umbrella
  [[ "${output}" == "umbrella" ]]
}

@test "weather.sh dispatcher - uv subcommand reads the JSON" {
  run main uv
  [[ "${output}" == "5" ]]
}

@test "weather.sh dispatcher - uv_color subcommand maps the band" {
  run main uv_color
  [[ "${output}" == "#[fg=yellow]" ]]
}

@test "weather.sh dispatcher - dew_point subcommand averages the hourly values" {
  run main dew_point
  [[ "${output}" == "12" ]]
}

@test "weather.sh dispatcher - dew_comfort subcommand classifies comfort" {
  run main dew_comfort
  [[ "${output}" == "dry" ]]
}

@test "weather.sh dispatcher - moon subcommand reads today's phase" {
  run main moon
  [[ "${output}" == "Waning Gibbous" ]]
}

@test "weather.sh dispatcher - sunrise and sunset subcommands read today" {
  run main sunrise
  [[ "${output}" == "06:00 AM" ]]
  run main sunset
  [[ "${output}" == "06:45 PM" ]]
}

@test "weather.sh dispatcher - forecast subcommand shows tomorrow low and high" {
  run main forecast
  [[ "${output}" == "15-27" ]]
}

@test "weather.sh dispatcher - day forecast subcommands read the right day" {
  run main today_high
  [[ "${output}" == "25" ]]
  run main today_low
  [[ "${output}" == "14" ]]
  run main tomorrow_high
  [[ "${output}" == "27" ]]
  run main tomorrow_low
  [[ "${output}" == "15" ]]
}

@test "weather.sh dispatcher - stale_color dims a long-stale reading" {
  weather_refresh_loc "auto"
  weather_fetch() { printf ''; }
  export MOCK_EPOCH=1003000
  run main stale_color
  [[ "${output}" == "#[dim]" ]]
}

@test "weather.sh dispatcher - stale_color is empty while fresh" {
  weather_refresh_loc "auto"
  run main stale_color
  [[ -z "${output}" ]]
}

@test "weather.sh dispatcher - stale_color is empty on a failed cold start" {
  weather_fetch() { printf ''; }
  run main stale_color
  [[ -z "${output}" ]]
}

@test "weather.sh dispatcher - a named location addresses its own cache" {
  set_tmux_option "@tmux-weather-locations" "London;Tokyo"
  run main weather Tokyo
  [[ "${output}" == "Partly cloudy +18${DEG}C" ]]
  [[ "$(cache_get value_Tokyo)" == "$(wttr_compact "${FIXTURE}")" ]]
}

@test "weather.sh dispatcher - tick spawns one worker per location" {
  set_tmux_option "@tmux-weather-locations" "London;Tokyo"
  weather_tick
  [[ -n "$(cache_get value_London)" ]]
  [[ -n "$(cache_get value_Tokyo)" ]]
}

@test "weather.sh dispatcher - imperial units flow through to the reading" {
  set_tmux_option "@tmux-weather-units" "u"
  run main temp
  [[ "${output}" == "64${DEG}F" ]]
  run main feels_like
  [[ "${output}" == "61" ]]
}

@test "weather.sh dispatcher - refresh subcommand fetches without rendering" {
  run main refresh
  [[ -z "${output}" ]]
  [[ "$(cache_get value_auto)" == "$(wttr_compact "${FIXTURE}")" ]]
}

@test "weather.sh dispatcher - unknown subcommand produces no output" {
  cache_set value_auto "${FIXTURE}"
  run main bogus
  [[ -z "${output}" ]]
}

@test "weather.sh dispatcher - weather_alerts_enabled is off by default" {
  run weather_alerts_enabled
  [[ "${status}" -ne 0 ]]
  set_tmux_option "@tmux-weather-alerts" "on"
  weather_alerts_enabled
}

@test "weather.sh dispatcher - weather_alert_build_url is empty without an endpoint" {
  [[ -z "$(weather_alert_build_url "London")" ]]
}

@test "weather.sh dispatcher - weather_alert_build_url substitutes the location" {
  set_tmux_option "@tmux-weather-alert-url" "https://alerts.example/{loc}"
  [[ "$(weather_alert_build_url "New York")" == "https://alerts.example/New+York" ]]
}

@test "weather.sh dispatcher - weather_alert_fetch is empty for an empty url" {
  [[ -z "$(weather_alert_fetch "")" ]]
}

@test "weather.sh dispatcher - weather_alert_fetch reads the first non-empty line" {
  _read_alert() { printf '\nTornado Warning\nmore\n'; }
  [[ "$(weather_alert_fetch "http://x")" == "Tornado Warning" ]]
}

@test "weather.sh dispatcher - weather_render_alert is empty without an alert" {
  [[ -z "$(weather_render_alert "")" ]]
}

@test "weather.sh dispatcher - weather_render_alert badges a non-empty alert" {
  set_tmux_option "@weather_revamped_alert_prefix" "[!] "
  [[ "$(weather_render_alert "Flood Watch")" == "[!] Flood Watch" ]]
}

@test "weather.sh dispatcher - alert refresh and subcommand round-trip" {
  set_tmux_option "@tmux-weather-alerts" "on"
  set_tmux_option "@tmux-weather-alert-url" "https://alerts.example/{loc}"
  _read_alert() { printf 'Heat Advisory\n'; }
  export -f _read_alert
  cache_set value_auto "${FIXTURE}"
  weather_tick
  run main alert
  [[ "${output}" == "Heat Advisory" ]]
}

@test "weather.sh dispatcher - tick skips alerts when disabled" {
  cache_set value_auto "${FIXTURE}"
  weather_tick
  [[ -z "$(cache_get alert_auto)" ]]
}

@test "weather.sh dispatcher - popup goes through the tmux seam without opening" {
  _tmux() { echo "TMUX $*"; }
  run main popup
  [[ "${output}" == "TMUX display-popup -E "*"weather.sh popup_card"* ]]
}

@test "weather.sh dispatcher - popup_card builds a card from the cache" {
  cache_set value_London "${FIXTURE}"
  set_tmux_option "@tmux-weather-locations" "London"
  run main popup_card London
  [[ "${output}" == *"Weather: London"* ]]
  [[ "${output}" == *"Wind: 11km/h NW"* ]]
  [[ "${output}" == *"Pressure: 1013 hPa"* ]]
  [[ "${output}" == *"Dew point: 12${DEG}C (dry)"* ]]
  [[ "${output}" == *"Tomorrow 15-27${DEG}C"* ]]
}

@test "weather.sh dispatcher - popup_card labels the auto location" {
  cache_set value_auto "${FIXTURE}"
  run main popup_card
  [[ "${output}" == *"Weather: current location"* ]]
}

@test "weather.sh dispatcher - doctor reports tooling and the reading" {
  cache_set value_auto "${FIXTURE}"
  run main doctor
  [[ "${output}" == *"tmux-weather-revamped doctor"* ]]
  [[ "${output}" == *"curl:"* ]]
  [[ "${output}" == *"units: m"* ]]
  [[ "${output}" == *"alerts: off"* ]]
  [[ "${output}" == *"(auto by IP)"* ]]
  [[ "${output}" == *"temp=18"* ]]
}

@test "weather.sh dispatcher - doctor reports a cold start" {
  run main doctor
  [[ "${output}" == *"reading: none yet"* ]]
}

@test "weather.sh dispatcher - doctor lists configured locations and alerts on" {
  set_tmux_option "@tmux-weather-locations" "London;Tokyo"
  set_tmux_option "@tmux-weather-alerts" "on"
  cache_set value_London "${FIXTURE}"
  run main doctor
  [[ "${output}" == *"alerts: on"* ]]
  [[ "${output}" == *"1. London"* ]]
  [[ "${output}" == *"2. Tokyo"* ]]
}

@test "weather.sh dispatcher - _read_alert runs curl behind a stub" {
  curl() { printf 'Storm Warning\nrest\n'; }
  [[ "$(_read_alert "http://example")" == *"Storm Warning"* ]]
}

@test "weather.sh dispatcher - _tmux seam forwards to tmux" {
  tmux() { echo "REAL $*"; }
  run weather_popup "auto"
  [[ "${output}" == "REAL display-popup -E "* ]]
}

@test "weather.sh dispatcher - doctor reports missing curl" {
  has_command() { return 1; }
  run main doctor
  [[ "${output}" == *"curl: MISSING"* ]]
}

@test "weather.sh dispatcher - stale_color dims when no success was recorded" {
  cache_set value_auto "${FIXTURE}"
  weather_fetch() { printf ''; }
  export MOCK_EPOCH=1003000
  run main stale_color
  [[ "${output}" == "#[dim]" ]]
}
