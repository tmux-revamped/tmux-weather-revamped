#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/weather_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/weather_helpers.bash"

logged() {
  grep -qxF -- "$1" "${FAKE}/log"
}

other_owner() {
  quiet sleep 'kept=$(grep -v "^@weather_revamped_ticker_pid	" "'"${FAKE}"'/vars" || :)
printf "%s\n@weather_revamped_ticker_pid\tsomeone-else\n" "${kept}" | grep -v "^$" >"'"${FAKE}"'/vars.next"
mv -f "'"${FAKE}"'/vars.next" "'"${FAKE}"'/vars"'
}

settled() {
  local tries=0
  until "$@"; do
    tries=$((tries + 1))
    [[ "${tries}" -lt 200 ]] || return 1
    /bin/sleep 0.05
  done
}

@test "plan - a fresh install binds the forecast popup to M-w and no refresh key" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Weather forecast M-w run-shell ${tool} popup" ]]
}

@test "plan - a key set to off binds nothing, and a key the person names is bound whoever holds it" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  planned
  [[ -z "${output}" ]]
  printf 'bind-key    -T prefix F8     display-message mine\n' >"${FAKE}/keys"
  option popup_key F8

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Weather forecast F8 run-shell ${tool} popup" ]]
}

@test "plan - a tmux older than 3.1 gets its key without a note" {
  # Arrange
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key M-w run-shell "*" popup" ]]
}

@test "plan - the default key is left alone when something else holds it, and bound again when the binding is the plugin's own" {
  # Arrange
  printf 'bind-key    -T prefix M-w     display-message mine\n' >"${FAKE}/keys"
  planned 'weather_revamped_plan; printf "[%s]\n" "${WEATHER_REVAMPED_SKIPPED}"; '
  [[ "${output}" == "[M-w]" ]]
  printf 'bind-key -r -T prefix M-w     run-shell "/old/bin/weather-revamped popup"\n' >"${FAKE}/keys"

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Weather forecast M-w run-shell "*" popup" ]]
}

@test "plan - a refresh key runs the fetch in the background with its output dropped" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option refresh_key R

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Fetch the weather now R run-shell -b ${tool} refresh >/dev/null 2>&1" ]]
}

@test "plan - each placeholder becomes a job that prints it, and the names in use are recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{weather_color}#{weather}#[default] #{weather_wind} #{weather_temp}'
  var status-left '#{weather_uv} #S'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-left #(${tool} status uv) #S" ]]
  [[ "${lines[1]}" == "set-option -gq status-right #(${tool} status color)#(${tool} status weather)#[default] #(${tool} status wind) #(${tool} status temp)" ]]
  [[ "${lines[2]}" == "set-option -gq @weather_revamped_published wind uv color temp weather" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "plan - every placeholder has its job, and a name that starts another is not mistaken for it" {
  # Arrange
  local tool name line="" jobs=""
  local names="feels_like wind humidity pressure_trend pressure precip rain_chance umbrella uv_color uv dew_point dew_comfort moon sunrise sunset forecast today_high today_low tomorrow_high tomorrow_low condition_icon condition_tint stale_color alert color icon temp"
  tool=$(tool_path)
  option popup_key off
  for name in ${names}; do
    line="${line}#{weather_${name}}"
    jobs="${jobs}#(${tool} status ${name})"
  done
  var status-right "${line}#{weather}"

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right ${jobs}#(${tool} status weather)" ]]
  [[ "${lines[1]}" == "set-option -gq @weather_revamped_published ${names} weather" ]]
}

@test "plan - a status line that ends in a semicolon keeps it, escaped, so tmux does not read it as a separator" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{weather};'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status weather)\\;" ]]
}

@test "plan - in options mode each placeholder becomes a read of the option the daemon fills" {
  # Arrange
  option popup_key off
  option render options
  var status-right '#{weather_color}#{weather} | #{weather_wind}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #{E:@weather_revamped_out_color}#{E:@weather_revamped_out_weather} | #{E:@weather_revamped_out_wind}" ]]
  [[ "${lines[1]}" == "set-option -gq @weather_revamped_published wind color weather" ]]
}

@test "plan - a status line already rewritten is left as it is, and its names stay recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option render options
  option published "wind weather"
  var status-right '#{E:@weather_revamped_out_weather} | #{E:@weather_revamped_out_wind}'
  planned
  [[ -z "${output}" ]]
  option render jobs
  option published "wind temp"
  var status-right "#(${tool} status temp) #(${tool} status wind)"

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - a status line with no placeholder is not written, and an old list of names is emptied" {
  # Arrange
  option popup_key off
  option published "weather"
  var status-right '%H:%M #{session_name}'

  # Act
  planned

  # Assert
  [[ "${output}" == 'set-option -gq @weather_revamped_published ""' ]]
}

@test "plan - a setting given in the environment rides on the key and on every job" {
  # Arrange
  var status-right '#{weather}'

  # Act
  planned 'export WEATHER_REVAMPED_UNITS=u; '

  # Assert
  [[ "${lines[0]}" == *"weather-revamped' --units 'u' popup" ]]
  [[ "${lines[1]}" == *"weather-revamped' --units 'u' status weather)" ]]
}

@test "plan - settings given in the environment ride in the order of the settings table, and an empty one rides too" {
  # Arrange
  var status-right '#{weather}'

  # Act
  planned 'export WEATHER_REVAMPED_TEMP_WIDTH=7 WEATHER_REVAMPED_ALERT_PREFIX= WEATHER_REVAMPED_UNITS=u WEATHER_REVAMPED_POPUP_KEY=F8; '

  # Assert
  [[ "${lines[0]}" == "bind-key -N Weather forecast F8 run-shell "*"weather-revamped' --units 'u' --alert-prefix '' --temp-width '7' popup" ]]
}

@test "plan - apply sends everything in one tmux call and clears a daemon's claim in jobs mode" {
  # Arrange
  var status-right '#{weather}'

  # Act
  lib_run weather 'weather_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "bind-key -N Weather forecast M-w run-shell "*" popup ; set-option -gq status-right #("*" status weather) ; set-option -gq @weather_revamped_published weather" ]]
  [[ "${lines[1]}" == "set-option -gqu @weather_revamped_ticker_pid" ]]
}

@test "plan - when tmux refuses the batch each command is sent alone, and the bad one fails the run" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key F99
  var status-right '#{weather}'
  printf '%s\n' "bind-key -N Weather forecast F99 run-shell ${tool} popup" >"${FAKE}/refused"

  # Act
  lib_run weather 'weather_revamped_apply'

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^set-option -gq status-right #(.* status weather)$'
  [[ "${output}" == "1" ]]
  holds published weather
}

@test "plan - in options mode apply starts the daemon, which claims the ticker and publishes until another takes over" {
  # Arrange
  london
  option popup_key off
  option render options
  option interval 1
  var status-right '#{weather}'
  other_owner

  # Act
  lib_run weather 'weather_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  settled holds out_weather $'Partly cloudy +18\xc2\xb0C'
  settled holds ticker_pid someone-else
  run sent '^set-option -gq @weather_revamped_ticker_pid [0-9][0-9]*$'
  [[ "${output}" == "1" ]]
}

@test "plan - the daemon ends when another process owns the ticker" {
  # Arrange
  london
  option published "humidity"
  other_owner

  # Act
  tool daemon

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_humidity 65
  holds ticker_pid someone-else
}

@test "plan - the popup runs the card and waits for Enter, in a command that holds no hash" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  lib_run weather 'weather_revamped_popup ""'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 70% -h 80% ${tool} card; printf '\\nPress Enter to close. '; read -r weather_revamped_wait"
}

@test "plan - the popup for a place hands it to the card with no hash left in it" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  lib_run weather 'weather_revamped_popup "New York #1"'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 70% -h 80% ${tool} card 'New York '\"\$(printf '%b' '\\0043')\"'1'; printf '\\nPress Enter to close. '; read -r weather_revamped_wait"
}

@test "plan - the popup carries a setting given in the environment" {
  # Arrange
  export WEATHER_REVAMPED_UNITS=u

  # Act
  lib_run weather 'weather_revamped_popup ""'

  # Assert
  run sent "^display-popup .*weather-revamped' --units 'u' card; "
  [[ "${output}" == "1" ]]
}

@test "plan - on a tmux older than 3.2 the popup key says why it opens nothing" {
  # Arrange
  tmux_is 3.1

  # Act
  lib_run weather 'weather_revamped_popup ""'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "the popup needs tmux 3.2 or later"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - a popup tmux refuses to open leaves the key quiet" {
  # Arrange
  local tool
  tool=$(tool_path)
  printf '%s\n' "display-popup -E -w 70% -h 80% ${tool} card; printf '\\nPress Enter to close. '; read -r weather_revamped_wait" >"${FAKE}/refused"

  # Act
  lib_run weather 'weather_revamped_popup ""'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "plan - a path is quoted for a job with each hash and each percent sign doubled, and for a key with none left" {
  # Arrange
  local script='weather_revamped_job_quote "/a b/it'"'"'s#1 50%"; weather_revamped_literal "/a b/it'"'"'s#1 50%"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${lines[0]}" == "'/a b/it'\\''s##1 50%%'" ]]
  [[ "${lines[1]}" == "'/a b/it'\\''s'\"\$(printf '%b' '\\0043')\"'1 50%'" ]]
}
