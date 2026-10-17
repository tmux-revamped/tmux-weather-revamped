#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

ENTRY="${BATS_TEST_DIRNAME}/../../weather-revamped.tmux"

setup() {
  setup_test_environment
  export SPAWN_LOG="${TEST_TMPDIR}/spawn.log"
  nohup() { printf '%s\n' "$*" >> "${SPAWN_LOG}"; }
  export -f nohup
}

teardown() {
  cleanup_test_environment
}

@test "entry - jobs mode turns a placeholder into a dispatcher call" {
  tmux set-option -gq "status-right" "[#{weather_temp}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/src/weather.sh temp)]" ]]
}

@test "entry - options mode turns a placeholder into an option read" {
  tmux set-option -gq "@weather_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{weather_temp}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#{E:@weather_revamped_out_temp}]" ]]
}

@test "entry - options mode starts the ticker" {
  tmux set-option -gq "@weather_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{weather_temp}]"

  bash "${ENTRY}"

  [[ "$(cat "${SPAWN_LOG}")" == *"/src/weather.sh daemon" ]]
}

@test "entry - jobs mode starts no ticker" {
  tmux set-option -gq "status-right" "[#{weather_temp}]"

  bash "${ENTRY}"

  [ ! -f "${SPAWN_LOG}" ]
}

@test "entry - only metrics on the status line are published" {
  tmux set-option -gq "status-right" "#{weather_temp}"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @weather_revamped_published)")" == "temp" ]]
}

@test "entry - a second run keeps metrics already turned into option reads" {
  tmux set-option -gq "@weather_revamped_render" "options"
  tmux set-option -gq "status-right" "[#{E:@weather_revamped_out_temp}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @weather_revamped_published)")" == "temp" ]]
}

@test "entry - an ampersand in the plugin path survives the replacement" {
  # Arrange
  local copy="${TEST_TMPDIR}/a&b"
  mkdir -p "${copy}"
  cp -R "${BATS_TEST_DIRNAME}/../../src" "${BATS_TEST_DIRNAME}/../../weather-revamped.tmux" "${copy}/"
  tmux set-option -gq "status-right" "[#{weather_temp}]"

  # Act
  bash "${copy}/weather-revamped.tmux"

  # Assert
  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#(${copy}/src/weather.sh temp)]" ]]
}

@test "entry - the popup key quotes a plugin path with a space" {
  # Arrange
  local copy="${TEST_TMPDIR}/my plugins"
  mkdir -p "${copy}"
  cp -R "${BATS_TEST_DIRNAME}/../../src" "${BATS_TEST_DIRNAME}/../../weather-revamped.tmux" "${copy}/"
  export BIND_LOG="${TEST_TMPDIR}/bind.log"
  eval "$(declare -f tmux | sed '1s/^tmux/_mock_tmux/')"
  tmux() {
    if [ "${1}" = "bind-key" ]; then
      printf '%s\n' "${4}" >> "${BIND_LOG}"
      return 0
    fi
    _mock_tmux "$@"
  }
  export -f _mock_tmux tmux
  tmux set-option -gq "@tmux-weather-popup-key" "W"

  # Act
  bash "${copy}/weather-revamped.tmux"

  # Assert
  [[ "$(cat "${BIND_LOG}")" == "${TEST_TMPDIR}/my\\ plugins/src/weather.sh popup" ]]
}

record_bind_keys() {
  export BIND_LOG="${TEST_TMPDIR}/bind.log"
  eval "$(declare -f tmux | sed '1s/^tmux/_mock_tmux/')"
  tmux() {
    if [ "${1}" = "bind-key" ]; then
      printf '%s\n' "$*" >> "${BIND_LOG}"
      return 0
    fi
    _mock_tmux "$@"
  }
  export -f _mock_tmux tmux
}

@test "entry - the popup key defaults to M-w" {
  # Arrange
  record_bind_keys

  # Act
  bash "${ENTRY}"

  # Assert
  [[ "$(cat "${BIND_LOG}")" == "bind-key M-w run-shell "*"/src/weather.sh popup" ]]
}

@test "entry - a popup key of off binds nothing" {
  # Arrange
  record_bind_keys
  tmux set-option -gq "@tmux-weather-popup-key" "off"

  # Act
  bash "${ENTRY}"

  # Assert
  [ ! -e "${BIND_LOG}" ]
}

@test "entry - the refresh key stays unbound by default" {
  # Arrange
  record_bind_keys

  # Act
  bash "${ENTRY}"

  # Assert
  [[ "$(cat "${BIND_LOG}")" != *" refresh"* ]]
}

@test "entry - jobs mode releases a running ticker so the daemon exits" {
  # Arrange
  tmux set-option -gq "@weather_revamped_ticker_pid" "4242"
  tmux set-option -gq "status-right" "[#{weather_temp}]"

  # Act
  bash "${ENTRY}"

  # Assert
  [ ! -f "$(_mock_opt_file @weather_revamped_ticker_pid)" ]
}
