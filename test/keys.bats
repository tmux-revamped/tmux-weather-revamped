#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

loaded_with_status() {
  local line='#{weather_temp} end' shown=$'18\xc2\xb0C end'
  [[ -z "${1:-}" ]] || line="$1"
  [[ -z "${2:-}" ]] || shown="$2"
  tmux set-option -g status-right "${line}"
  load_plugin
  wait_for host_shows "${shown}"
}

@test "keys - prefix M-w opens the card in a popup, with every reading it has" {
  # Arrange
  loaded_with_status

  # Act
  press C-b M-w

  # Assert
  wait_for host_shows "Press Enter to close."
  host_shows "Location"
  host_shows "Partly cloudy"
  host_shows "11km/h NW"
  host_shows "Waning Gibbous"
  host_shows "Read. wttr.in answered"
}

@test "keys - Enter closes the popup and leaves the status line running" {
  # Arrange
  loaded_with_status
  press C-b M-w
  wait_for host_shows "Press Enter to close."

  # Act
  press Enter

  # Assert
  wait_for host_lacks "Press Enter to close."
  wait_for host_shows $'18\xc2\xb0C end'
}

@test "keys - Ctrl-C closes the popup and leaves no error over the pane" {
  # Arrange
  loaded_with_status
  press C-b M-w
  wait_for host_shows "Press Enter to close."

  # Act
  press C-c

  # Assert
  wait_for host_lacks "Press Enter to close."
  host_lacks "returned"
  run tmux display-message -p -t test '#{pane_in_mode}'
  [[ "${output}" == "0" ]]
}

@test "keys - a key the person names opens the popup, and the default one then does nothing" {
  # Arrange
  setting popup_key F8
  loaded_with_status
  press C-b M-w
  host_lacks "Press Enter to close."

  # Act
  press C-b F8

  # Assert
  wait_for host_shows "Press Enter to close."
}

@test "keys - the refresh key fetches at once, and the status line shows the new reading" {
  # Arrange
  setting refresh_key R
  loaded_with_status '#{weather} end' $'Partly cloudy +18\xc2\xb0C end'
  answer_says Sunny

  # Act
  press C-b R

  # Assert
  wait_for stored_has '"value":"Sunny"'
  wait_for host_shows $'Sunny +18\xc2\xb0C end'
}

@test "keys - in options mode the status line reads options a daemon fills" {
  # Arrange
  setting render options
  tmux set-option -g status-right '#{weather_temp} | #{weather_humidity} end'

  # Act
  load_plugin

  # Assert
  run tmux show-option -gqv status-right
  [[ "${output}" == "#{E:@weather_revamped_out_temp} | #{E:@weather_revamped_out_humidity} end" ]]
  wait_for host_shows $'18\xc2\xb0C | 65 end'
  run tmux show-option -gqv @weather_revamped_ticker_pid
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "keys - in options mode an alert near the size limit of a tmux command is published, and so is every other name" {
  # Arrange
  local long
  long=$(awk 'BEGIN { for (i = 0; i < 16000; i++) { printf "a" } }')
  setting render options
  setting alert_auto "${long}"
  tmux set-option -g status-right '#{weather_temp} #{weather_humidity} #{weather_pressure} #{weather_uv} #{weather_feels_like} #{weather_moon} #{weather_sunrise} #{weather_sunset} #{weather_alert}'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'18\xc2\xb0C 65 1013 5 16 Waning Gibbous 06:00 AM 06:45 PM aaaa'
  wait_for holds out_alert "${long}"
}

@test "keys - in options mode the popup key still opens the card" {
  # Arrange
  setting render options
  loaded_with_status

  # Act
  press C-b M-w

  # Assert
  wait_for host_shows "Press Enter to close."
  host_shows "Humidity"
}
