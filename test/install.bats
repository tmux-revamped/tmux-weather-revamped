#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  ROOT="$(cd "${REVAMPED_TESTS_DIR}/.." && pwd)"
}

complete_words() {
  # shellcheck source=completions/weather-revamped.bash
  source "${ROOT}/completions/weather-revamped.bash"
  COMP_WORDS=("$@")
  COMP_CWORD=$(($# - 1))
  _weather_revamped
  printf '%s\n' "${COMPREPLY[@]}"
}

@test "install - make install puts a working tool, its man page and completions under PREFIX" {
  # Arrange
  local prefix="${BATS_TEST_TMPDIR}/prefix with space"

  # Act
  make -s -C "${ROOT}" install PREFIX="${prefix}"

  # Assert
  run "${prefix}/bin/weather-revamped" version
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == weather-revamped\ * ]]
  [[ -f "${prefix}/share/man/man1/weather-revamped.1" ]]
  [[ -f "${prefix}/share/bash-completion/completions/weather-revamped" ]]
  [[ -f "${prefix}/share/zsh/site-functions/_weather-revamped" ]]
  [[ -f "${prefix}/share/fish/vendor_completions.d/weather-revamped.fish" ]]
}

@test "install - a second install replaces the first" {
  # Arrange
  local prefix="${BATS_TEST_TMPDIR}/prefix"
  make -s -C "${ROOT}" install PREFIX="${prefix}"
  printf 'stale\n' >"${prefix}/share/weather-revamped/lib/stale.sh"

  # Act
  make -s -C "${ROOT}" install PREFIX="${prefix}"

  # Assert
  [[ ! -e "${prefix}/share/weather-revamped/lib/stale.sh" ]]
  [[ -x "${prefix}/bin/weather-revamped" ]]
}

@test "install - bash completes the commands" {
  # Arrange
  local word=d

  # Act
  run complete_words weather-revamped "${word}"

  # Assert
  [[ "${output}" == $'daemon\ndoctor' ]]
}

@test "install - bash completes the themes after --theme" {
  # Arrange
  local word=no

  # Act
  run complete_words weather-revamped --theme "${word}"

  # Assert
  [[ "${output}" == "nord" ]]
}
