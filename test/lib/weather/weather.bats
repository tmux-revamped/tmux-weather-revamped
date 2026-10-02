#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _WEATHER_REVAMPED_WEATHER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/weather/weather.sh"
  DEG="$(printf '\xc2\xb0')"
}

teardown() {
  cleanup_test_environment
}

@test "weather.sh - weather_build_url uses metric by default" {
  [[ "$(weather_build_url London m 1)" == "https://wttr.in/London?format=1&m" ]]
}

@test "weather.sh - weather_build_url uses imperial when requested" {
  [[ "$(weather_build_url London u 1)" == "https://wttr.in/London?format=1&u" ]]
}

@test "weather.sh - weather_build_url accepts fahrenheit aliases" {
  [[ "$(weather_build_url London f 1)" == *"&u" ]]
  [[ "$(weather_build_url London F 1)" == *"&u" ]]
  [[ "$(weather_build_url London fahrenheit 1)" == *"&u" ]]
}

@test "weather.sh - weather_build_url treats celsius aliases as metric" {
  [[ "$(weather_build_url London c 1)" == *"&m" ]]
  [[ "$(weather_build_url London celsius 1)" == *"&m" ]]
  [[ "$(weather_build_url London '' 1)" == *"&m" ]]
}

@test "weather.sh - weather_build_url allows an empty location" {
  [[ "$(weather_build_url '' m 3)" == "https://wttr.in/?format=3&m" ]]
}

@test "weather.sh - weather_build_url encodes spaces in the location" {
  [[ "$(weather_build_url 'New York' m 1)" == "https://wttr.in/New+York?format=1&m" ]]
  [[ "$(weather_build_url 'Rio de Janeiro' u 1)" == "https://wttr.in/Rio+de+Janeiro?format=1&u" ]]
}

@test "weather.sh - weather_strip_units drops the unit letter, keeps the degree" {
  [[ "$(weather_strip_units '25°C')" == "25°" ]]
  [[ "$(weather_strip_units '70°F')" == "70°" ]]
  [[ "$(weather_strip_units '18')" == "18" ]]
}

@test "weather.sh - weather_render_temp strips the plus and honors hide-units" {
  [[ "$(weather_render_temp 'Sunny +25°C')" == "25°C" ]]
  set_tmux_option "@tmux-weather-hide-units" "on"
  [[ "$(weather_render_temp 'Sunny +25°C')" == "25°" ]]
}

@test "weather.sh - weather_fetch returns a successful body" {
  _read_weather() { echo "Partly cloudy 18°C"; }
  [[ "$(weather_fetch "http://x")" == "Partly cloudy 18°C" ]]
}

@test "weather.sh - weather_fetch is empty for an unknown location" {
  _read_weather() { echo "Unknown location: zzz"; }
  [[ -z "$(weather_fetch "http://x")" ]]
}

@test "weather.sh - weather_fetch is empty for a server error" {
  _read_weather() { echo "ERROR: upstream"; }
  [[ -z "$(weather_fetch "http://x")" ]]
}

@test "weather.sh - weather_fetch is empty when the probe is empty" {
  _read_weather() { echo ""; }
  [[ -z "$(weather_fetch "http://x")" ]]
}

@test "weather.sh - weather_temp_from_text reads a positive temperature" {
  [[ "$(weather_temp_from_text "+18°C clear")" == "18" ]]
}

@test "weather.sh - weather_temp_from_text reads a negative temperature" {
  [[ "$(weather_temp_from_text "-3°C snow")" == "-3" ]]
}

@test "weather.sh - weather_temp_from_text reads an unsigned fahrenheit value" {
  [[ "$(weather_temp_from_text "64F sunny")" == "64" ]]
}

@test "weather.sh - weather_temp_from_text is empty when no temperature is present" {
  [[ -z "$(weather_temp_from_text "partly cloudy")" ]]
}

@test "weather.sh - weather_band classifies freezing" {
  [[ "$(weather_band -5)" == "freezing" ]]
}

@test "weather.sh - weather_band classifies cold" {
  [[ "$(weather_band 5)" == "cold" ]]
}

@test "weather.sh - weather_band classifies cool" {
  [[ "$(weather_band 15)" == "cool" ]]
}

@test "weather.sh - weather_band classifies comfortable" {
  [[ "$(weather_band 20)" == "comfortable" ]]
}

@test "weather.sh - weather_band classifies hot" {
  [[ "$(weather_band 28)" == "hot" ]]
}

@test "weather.sh - weather_band classifies very_hot" {
  [[ "$(weather_band 35)" == "very_hot" ]]
}

@test "weather.sh - weather_band is empty for a non-integer" {
  [[ -z "$(weather_band "abc")" ]]
}

@test "weather.sh - _weather_band_default_color maps every band" {
  [[ "$(_weather_band_default_color freezing)" == "#[fg=blue]" ]]
  [[ "$(_weather_band_default_color cold)" == "#[fg=cyan]" ]]
  [[ "$(_weather_band_default_color cool)" == "#[fg=green]" ]]
  [[ "$(_weather_band_default_color comfortable)" == "#[fg=green]" ]]
  [[ "$(_weather_band_default_color hot)" == "#[fg=yellow]" ]]
  [[ "$(_weather_band_default_color very_hot)" == "#[fg=red]" ]]
  [[ -z "$(_weather_band_default_color nonsense)" ]]
}

@test "weather.sh - weather_render_color uses the band default" {
  [[ "$(weather_render_color "+20°C clear")" == "#[fg=green]" ]]
}

@test "weather.sh - weather_render_color colors a freezing reading blue" {
  [[ "$(weather_render_color "-5°C snow")" == "#[fg=blue]" ]]
}

@test "weather.sh - weather_render_color colors a very hot reading red" {
  [[ "$(weather_render_color "+35°C")" == "#[fg=red]" ]]
}

@test "weather.sh - weather_render_color honors the band option" {
  set_tmux_option "@weather_revamped_hot_color" "#[fg=magenta]"
  [[ "$(weather_render_color "+28°C")" == "#[fg=magenta]" ]]
}

@test "weather.sh - weather_render_color passes a named color through verbatim" {
  set_tmux_option "@weather_revamped_hot_color" "#[fg=red]"
  [[ "$(weather_render_color "+28°C")" == "#[fg=red]" ]]
}

@test "weather.sh - weather_render_color passes a 256-palette color through verbatim" {
  set_tmux_option "@weather_revamped_hot_color" "#[fg=colour203]"
  [[ "$(weather_render_color "+28°C")" == "#[fg=colour203]" ]]
}

@test "weather.sh - weather_render_color passes a hex foreground through verbatim" {
  set_tmux_option "@weather_revamped_hot_color" "#[fg=#f38ba8]"
  [[ "$(weather_render_color "+28°C")" == "#[fg=#f38ba8]" ]]
}

@test "weather.sh - weather_render_color passes a hex fg and bg pair through verbatim" {
  set_tmux_option "@weather_revamped_hot_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(weather_render_color "+28°C")" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "weather.sh - weather_render_color passes a bright color name through verbatim" {
  set_tmux_option "@weather_revamped_hot_color" "#[fg=brightred]"
  [[ "$(weather_render_color "+28°C")" == "#[fg=brightred]" ]]
}

@test "weather.sh - weather_render_color is empty without a parseable temperature" {
  [[ -z "$(weather_render_color "partly cloudy")" ]]
}

@test "weather.sh - weather_render_icon is empty by default" {
  [[ -z "$(weather_render_icon "+20°C clear")" ]]
}

@test "weather.sh - weather_render_icon honors the band option" {
  set_tmux_option "@weather_revamped_freezing_icon" "ICE"
  [[ "$(weather_render_icon "-5°C")" == "ICE" ]]
}

@test "weather.sh - weather_render_icon is empty without a parseable temperature" {
  [[ -z "$(weather_render_icon "partly cloudy")" ]]
}

@test "weather.sh - weather_temp_display_from_text strips a leading plus" {
  [[ "$(weather_temp_display_from_text "Partly cloudy +25°C")" == "25°C" ]]
  [[ "$(weather_temp_display_from_text "Light snow -3°C")" == "-3°C" ]]
}

@test "weather.sh - weather_condition_from_text returns the words before the temp" {
  [[ "$(weather_condition_from_text "Partly cloudy +25°C")" == "Partly cloudy" ]]
  [[ "$(weather_condition_from_text "Sunny +30°C")" == "Sunny" ]]
}

@test "weather.sh - weather_condition_key normalizes conditions" {
  [[ "$(weather_condition_key "Thundery outbreaks possible")" == "storm" ]]
  [[ "$(weather_condition_key "Light snow")" == "snow" ]]
  [[ "$(weather_condition_key "Patchy rain possible")" == "rain" ]]
  [[ "$(weather_condition_key "Fog")" == "fog" ]]
  [[ "$(weather_condition_key "Overcast")" == "clouds" ]]
  [[ "$(weather_condition_key "Sunny")" == "clear" ]]
}

@test "weather.sh - condition icon has a Nerd Font default and is overridable" {
  [[ -n "$(weather_render_condition_icon "Light rain +18°C")" ]]
  set_tmux_option "@weather_revamped_rain_condition_icon" "R"
  [[ "$(weather_render_condition_icon "Light rain +18°C")" == "R" ]]
}

@test "weather.sh - the condition icon can be hidden" {
  set_tmux_option "@weather_revamped_show_condition_icon" "off"
  [[ -z "$(weather_render_condition_icon "Light rain +18°C")" ]]
}

@test "weather.sh - weather_uv_band classifies the WHO bands" {
  [[ "$(weather_uv_band 0)" == "low" ]]
  [[ "$(weather_uv_band 2)" == "low" ]]
  [[ "$(weather_uv_band 3)" == "moderate" ]]
  [[ "$(weather_uv_band 5)" == "moderate" ]]
  [[ "$(weather_uv_band 6)" == "high" ]]
  [[ "$(weather_uv_band 7)" == "high" ]]
  [[ "$(weather_uv_band 8)" == "very_high" ]]
  [[ "$(weather_uv_band 10)" == "very_high" ]]
  [[ "$(weather_uv_band 11)" == "extreme" ]]
}

@test "weather.sh - weather_uv_band is empty for a non-integer" {
  [[ -z "$(weather_uv_band "n/a")" ]]
}

@test "weather.sh - _weather_uv_default_color maps every band" {
  [[ "$(_weather_uv_default_color low)" == "#[fg=green]" ]]
  [[ "$(_weather_uv_default_color moderate)" == "#[fg=yellow]" ]]
  [[ "$(_weather_uv_default_color high)" == "#[fg=colour208]" ]]
  [[ "$(_weather_uv_default_color very_high)" == "#[fg=red]" ]]
  [[ "$(_weather_uv_default_color extreme)" == "#[fg=magenta]" ]]
  [[ -z "$(_weather_uv_default_color nonsense)" ]]
}

@test "weather.sh - weather_uv_color uses the band default" {
  [[ "$(weather_uv_color 9)" == "#[fg=red]" ]]
}

@test "weather.sh - weather_uv_color honors the band option" {
  set_tmux_option "@weather_revamped_uv_high_color" "#[fg=#fab387]"
  [[ "$(weather_uv_color 6)" == "#[fg=#fab387]" ]]
}

@test "weather.sh - weather_uv_color is empty for a non-integer" {
  [[ -z "$(weather_uv_color "x")" ]]
}

@test "weather.sh - weather_dew_comfort classifies comfort by celsius" {
  [[ "$(weather_dew_comfort 5)" == "dry" ]]
  [[ "$(weather_dew_comfort 12)" == "dry" ]]
  [[ "$(weather_dew_comfort 13)" == "comfortable" ]]
  [[ "$(weather_dew_comfort 15)" == "comfortable" ]]
  [[ "$(weather_dew_comfort 16)" == "humid" ]]
  [[ "$(weather_dew_comfort 18)" == "humid" ]]
  [[ "$(weather_dew_comfort 19)" == "oppressive" ]]
}

@test "weather.sh - weather_dew_comfort handles a negative dew point" {
  [[ "$(weather_dew_comfort -2)" == "dry" ]]
}

@test "weather.sh - weather_dew_comfort is empty for a non-integer" {
  [[ -z "$(weather_dew_comfort "n/a")" ]]
}

@test "weather.sh - weather_umbrella_hint fires above the threshold" {
  set_tmux_option "@weather_revamped_umbrella_text" "take an umbrella"
  [[ "$(weather_umbrella_hint 60)" == "take an umbrella" ]]
}

@test "weather.sh - weather_umbrella_hint is silent below the threshold" {
  set_tmux_option "@weather_revamped_umbrella_text" "take an umbrella"
  [[ -z "$(weather_umbrella_hint 40)" ]]
}

@test "weather.sh - weather_umbrella_hint honors a custom threshold" {
  set_tmux_option "@weather_revamped_umbrella_text" "umbrella"
  set_tmux_option "@weather_revamped_umbrella_threshold" "30"
  [[ "$(weather_umbrella_hint 35)" == "umbrella" ]]
}

@test "weather.sh - weather_umbrella_hint defaults junk threshold to fifty" {
  set_tmux_option "@weather_revamped_umbrella_text" "umbrella"
  set_tmux_option "@weather_revamped_umbrella_threshold" "abc"
  [[ "$(weather_umbrella_hint 55)" == "umbrella" ]]
  [[ -z "$(weather_umbrella_hint 45)" ]]
}

@test "weather.sh - weather_umbrella_hint is empty for a non-integer chance" {
  [[ -z "$(weather_umbrella_hint "n/a")" ]]
}

@test "weather.sh - weather_pressure_trend marks rising falling steady" {
  [[ "$(weather_pressure_trend 1015 1010)" == "^" ]]
  [[ "$(weather_pressure_trend 1010 1015)" == "v" ]]
  [[ "$(weather_pressure_trend 1013 1013)" == "=" ]]
}

@test "weather.sh - weather_pressure_trend honors a custom delta" {
  set_tmux_option "@weather_revamped_pressure_delta" "5"
  [[ "$(weather_pressure_trend 1016 1013)" == "=" ]]
  [[ "$(weather_pressure_trend 1020 1013)" == "^" ]]
}

@test "weather.sh - weather_pressure_trend defaults junk delta to one" {
  set_tmux_option "@weather_revamped_pressure_delta" "abc"
  [[ "$(weather_pressure_trend 1016 1013)" == "^" ]]
}

@test "weather.sh - weather_pressure_trend honors custom marks" {
  set_tmux_option "@weather_revamped_pressure_rising" "up"
  [[ "$(weather_pressure_trend 1020 1010)" == "up" ]]
}

@test "weather.sh - weather_pressure_trend is empty without two integers" {
  [[ -z "$(weather_pressure_trend 1013 "")" ]]
  [[ -z "$(weather_pressure_trend "" 1013)" ]]
}

@test "weather.sh - weather_condition_tint reads a per-condition override" {
  set_tmux_option "@weather_revamped_clouds_tint" "#[fg=grey]"
  [[ "$(weather_condition_tint "Partly cloudy +18${DEG}C")" == "#[fg=grey]" ]]
}

@test "weather.sh - weather_condition_tint has a default per condition" {
  [[ "$(weather_condition_tint "Sunny +25${DEG}C")" == "#[fg=yellow]" ]]
  [[ "$(weather_condition_tint "Light rain +18${DEG}C")" == "#[fg=blue]" ]]
}

@test "weather.sh - weather_stale_color dims a long-stale reading" {
  [[ "$(weather_stale_color 3000 900)" == "#[dim]" ]]
}

@test "weather.sh - weather_stale_color is empty while fresh" {
  [[ -z "$(weather_stale_color 100 900)" ]]
}

@test "weather.sh - weather_stale_color honors a custom dim style" {
  set_tmux_option "@weather_revamped_stale_color" "#[fg=grey]"
  [[ "$(weather_stale_color 3000 900)" == "#[fg=grey]" ]]
}

@test "weather.sh - weather_stale_color is empty for non-integers" {
  [[ -z "$(weather_stale_color "x" 900)" ]]
  [[ -z "$(weather_stale_color 100 "y")" ]]
}

@test "weather.sh - _read_weather runs curl behind a stub" {
  curl() { printf 'Sunny 20C'; }
  [[ "$(_read_weather "http://example")" == "Sunny 20C" ]]
}

@test "weather.sh - an empty tint turns the default off" {
  _weather_option_exists() { [[ "${1}" == "@weather_revamped_rain_tint" ]]; }

  run weather_condition_tint "Light rain +18${DEG}C"

  [ -z "${output}" ]
}

@test "weather.sh - every condition has a default tint and icon" {
  local key
  for key in clear clouds rain snow storm fog; do
    [[ -n "$(weather_condition_default_tint "${key}")" ]] || { echo "no tint for ${key}"; return 1; }
    [[ -n "$(weather_condition_default_icon "${key}")" ]] || { echo "no icon for ${key}"; return 1; }
  done
}

@test "weather.sh - rain gets the material rain glyph" {
  run weather_condition_default_icon rain

  [[ "${output}" == $'\xf3\xb0\x96\x97' ]]
}
