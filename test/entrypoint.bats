#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

everything() {
  local options
  options=$(tmux show-options -g)
  grep -vE '@weather_revamped_(value_|alert_)|@weather_revamped_[A-Za-z_]+_(ok_ts|pressure_prev) ' <<<"${options}"
  tmux list-keys
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- weather-revamped.tmux bin/weather-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the popup on M-w and turns the placeholder into its job, which shows the weather" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{weather} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-w' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == "#('${ROOT}/bin/weather-revamped' status weather) end" ]]
  wait_for host_shows $'Partly cloudy +18\xc2\xb0C end'
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{weather} end'
  load_plugin
  wait_for host_shows $'Partly cloudy +18\xc2\xb0C end'
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${before}" == "${after}" ]]
}

@test "entrypoint - a condition that holds a tmux format is shown as text" {
  # Arrange
  answer_says 'Rain #S'
  tmux set-option -g status-right '#{weather} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'Rain #S +18\xc2\xb0C end'
}

@test "entrypoint - a key option set to nothing on a real server means its default" {
  # Arrange
  local keys
  tmux set-option -g @weather_revamped_popup_key ''

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-w' <<<"${keys}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a checkout whose path holds a space, a quote, a hash and a percent sign loads, shows the weather and takes its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 50% plug in"
  mkdir -p "${copy}"
  cp -R "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/weather-revamped.tmux" "${copy}/"
  tmux set-option -g status-right '#{weather_temp} end'
  load_plugin "${copy}"
  wait_for host_shows $'18\xc2\xb0C end'

  # Act
  press C-b M-w

  # Assert
  wait_for host_shows "Press Enter to close."
  host_shows "Humidity"
}

@test "entrypoint - an answer of the size wttr.in sends is stored whole and shown" {
  # Arrange
  cp -f "${BATS_TEST_DIRNAME}/fixtures/wttr-london-full.j1.json" "${BATS_TEST_TMPDIR}/answer"
  tmux set-option -g status-right '#{weather} #{weather_tomorrow_low} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'Clear +10\xc2\xb0C 7 end'
  stored_has '"mintempF":"40","uvIndex":"0"'
}

@test "entrypoint - an alert too long for one tmux command leaves the reading stored and the last alert in place" {
  # Arrange
  awk 'BEGIN { for (i = 0; i < 20000; i++) { printf "x" } printf "\n" }' >"${BATS_TEST_TMPDIR}/alert"
  stand_in curl 'case "$*" in
*wttr.in*) cat "'"${BATS_TEST_TMPDIR}"'/answer" ;;
*) cat "'"${BATS_TEST_TMPDIR}"'/alert" ;;
esac'
  setting alerts on
  setting alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'
  setting alert_auto 'Old warning'
  tmux set-option -g status-right '#{weather} #{weather_alert} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'Partly cloudy +18\xc2\xb0C Old warning end'
}

@test "entrypoint - a default key someone else holds is left alone, and one the person names is bound" {
  # Arrange
  local table
  tmux bind-key -T prefix M-w display-message taken
  load_plugin
  table=$(tmux list-keys -T prefix)
  run grep -c 'M-w  *display-message taken' <<<"${table}"
  [[ "${output}" == "1" ]]
  run grep -c 'weather-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
  tmux bind-key -T prefix x display-message taken-too
  setting popup_key x

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'weather-revamped. popup' <<<"${table}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a key set to off binds nothing" {
  # Arrange
  local table
  setting popup_key off

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'weather-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
}
