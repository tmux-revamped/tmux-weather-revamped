#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME}/../tmux_helpers.bash"

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  command tmux -S "${HOST}" capture-pane -p -t host || :
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

host_lacks() {
  ! host_shows "$1"
}

stays() {
  local delay
  for delay in 0.1 0.2 0.3 0.4; do
    sleep "${delay}"
    host_shows "$1" || return 1
  done
}

fetched() {
  [[ -s "${BATS_TEST_TMPDIR}/fetched" ]]
}

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  export TMPDIR="${BATS_TEST_TMPDIR}/tmp"
  mkdir -p "${HOME}" "${STUBS}" "${TMPDIR}"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s"\ncat "%s"\n' "${BATS_TEST_TMPDIR}/fetched" "${ROOT}/test/fixtures/wttr-london.j1.json" >"${STUBS}/curl"
  chmod +x "${STUBS}/curl"
  PATH="${STUBS}:${PATH}"
  HOST="${TMUX_SOCKET}-host"
  setup_tmux_server
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux set-option -g @tmux-weather-locations "London"
  tmux set-option -g @tmux-weather-refresh-key F6
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 40 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  tmux run-shell "'${ROOT}/weather-revamped.tmux'"
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

@test "keys - the refresh key fetches the reading, and prefix M-w shows it in a card that stays until a key" {
  # Arrange
  press C-b F6
  wait_for fetched

  # Act
  press C-b M-w

  # Assert
  wait_for host_shows "Weather: London"
  wait_for host_shows "Wind: 11km/h NW"
  wait_for host_shows "Tomorrow 15-27"
  stays "Tomorrow 15-27"
  press Enter
  wait_for host_lacks "Weather: London"
}

@test "keys - the popup opens on the key the person set" {
  # Arrange
  tmux set-option -g @tmux-weather-popup-key F7
  tmux run-shell "'${ROOT}/weather-revamped.tmux'"

  # Act
  press C-b F7

  # Assert
  wait_for host_shows "Weather: London"
  stays "Weather: London"
}
