#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v WEATHER_REVAMPED_); do
    unset "${name}"
  done
  FAKE="${BATS_TEST_TMPDIR}/fake"
  export HOME="${BATS_TEST_TMPDIR}/home" FAKE
  mkdir -p "${HOME}" "${FAKE}" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  : >"${FAKE}/vars"
  : >"${FAKE}/log"
  : >"${FAKE}/asked"
  now 1000000
  fake_tmux
  fake_date
  linux
  harness_hide curl osascript notify-send
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

var() {
  local kept
  kept=$(grep -v "^$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "${kept}" "$1" "$2" | grep -v '^$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}

value() {
  awk -F '\t' -v want="$1" '$1 == want { print $2 }' "${FAKE}/vars"
}

option() {
  var "@weather_revamped_$1" "$2"
}

held() {
  value "@weather_revamped_$1"
}

now() {
  printf '%s\n' "$1" >"${FAKE}/now"
}

fake_date() {
  quiet date 'cat "'"${FAKE}"'/now"'
}

macos() {
  export REVAMPED_TEST_UNAME_S=Darwin
}

linux() {
  export REVAMPED_TEST_UNAME_S=Linux
}

READING='"FeelsLikeC":"16","FeelsLikeF":"61","humidity":"65","precipMM":"0.2","pressure":"1013","temp_C":"18","temp_F":"64","uvIndex":"5","value":"Partly cloudy","winddir16Point":"NW","windspeedKmph":"11","windspeedMiles":"7","moon_phase":"Waning Gibbous","sunrise":"06:00 AM","sunset":"06:45 PM","maxtempC":"25","maxtempF":"77","mintempC":"14","mintempF":"57","DewPointC":"11","DewPointF":"52","chanceofrain":"20","DewPointC":"14","DewPointF":"57","chanceofrain":"60","maxtempC":"27","maxtempF":"81","mintempC":"15","mintempF":"59","DewPointC":"30","DewPointF":"86","chanceofrain":"90"'

reading() {
  option "value_${1:-auto}" "${3:-${READING}}"
  option "value_${1:-auto}_ts" "${2:-1000000}"
  option "${1:-auto}_ok_ts" "${2:-1000000}"
}

with() {
  READING_NOW="${READING}"
  local pair
  for pair in "$@"; do
    READING_NOW=$(printf '%s\n' "${READING_NOW}" | sed "s/\"${pair%%=*}\":\"[^\"]*\"/\"${pair%%=*}\":\"${pair#*=}\"/")
  done
  reading auto 1000000 "${READING_NOW}"
}

answers_with() {
  printf '%s\n' "$1" >"${FAKE}/curl.weather"
  printf '%s\n' "${2:-}" >"${FAKE}/curl.alert"
  quiet curl 'printf "curl %s\n" "$*" >>"'"${FAKE}"'/asked"
case "$*" in
*wttr.in*) cat "'"${FAKE}"'/curl.weather" ;;
*) cat "'"${FAKE}"'/curl.alert" ;;
esac'
}

london() {
  local body
  body=$(<"${REVAMPED_TESTS_DIR}/fixtures/wttr-london.j1.json")
  answers_with "${body}" "${1:-}"
}

full_answer() {
  local body
  body=$(<"${REVAMPED_TESTS_DIR}/fixtures/wttr-london-full.j1.json")
  answers_with "${body}" "${1:-}"
}

notifier() {
  quiet "$1" 'printf "%s\n" "$*" >>"'"${FAKE}"'/notified"'
}

notified() {
  cat "${FAKE}/notified" 2>/dev/null || :
}

asked() {
  cat "${FAKE}/asked"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
expanded() {
  printf '%s\n' "\$1" | awk -v vars="${FAKE}/vars" '
    BEGIN { while ((getline row < vars) > 0) { at = index(row, "\t"); value[substr(row, 1, at - 1)] = substr(row, at + 1) } }
    {
      line = \$0
      out = ""
      while ((at = index(line, "#{")) > 0) {
        stop = index(substr(line, at), "}")
        name = substr(line, at + 2, stop - 3)
        out = out substr(line, 1, at - 1) value[name]
        line = substr(line, at + stop)
      }
      print out line
    }
  '
}
looked() {
  awk -F '\t' -v want="\$1" '\$1 == want { print \$2 }' "${FAKE}/vars"
}
put() {
  kept=\$(grep -v "^\$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "\${kept}" "\$1" "\$2" | grep -v '^\$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}
written() {
  while [ "\$#" -gt 0 ]; do
    if [ "\$1" = set-option ] && [ "\${2:-}" = -gq ] && [ "\$#" -ge 4 ]; then
      put "\$3" "\$4"
      shift 4
      continue
    fi
    shift
  done
}
case "\$1" in
-V)
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  ;;
display-message)
  [ "\$2" != -p ] || expanded "\$3"
  ;;
show-option)
  looked "\$3"
  ;;
list-keys)
  [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
  ;;
list-clients)
  [ ! -f "${FAKE}/clients" ] || cat "${FAKE}/clients"
  ;;
*)
  case "\$*" in
  *" ; "*) [ ! -f "${FAKE}/refused" ] || exit 1 ;;
  *) [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1 ;;
  esac
  written "\$@"
  ;;
esac
exit 0
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

planned() {
  lib_run weather "${1:-}"'weather_revamped_plan; weather_revamped_lines'
}

sends() {
  grep -v -e '^display-message -p' -e '^-V' -e '^list-' -e '^show-option' "${FAKE}/log" || :
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/weather-revamped" "$@"
}

tool_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR}/../bin/weather-revamped"
}

bin_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR%/test}/bin/weather-revamped"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}

answers() {
  export REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

said() {
  grep -qxF -- "display-message weather-revamped: $1" "${FAKE}/log"
}

eventually() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@"
}

holds() {
  local now
  now=$(held "$1")
  [[ "${now}" == "$2" ]]
}
