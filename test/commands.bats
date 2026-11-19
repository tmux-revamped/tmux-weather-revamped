#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/weather_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/weather_helpers.bash"

curl_version() {
  quiet curl 'printf "curl 8.7.1 (x86_64-apple-darwin25.0) libcurl/8.7.1\n"'
}

@test "commands - status prints one placeholder from the stored reading" {
  # Arrange
  reading auto 1000000
  now 1000001

  # Act
  tool status weather

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'Partly cloudy +18\xc2\xb0C' ]]
}

@test "commands - status without a name is a usage error, and an unknown name a bad value" {
  # Arrange
  tool status
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: no placeholder given. run 'weather-revamped help' for usage." ]]

  # Act
  tool status latency

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: status must be a placeholder name such as weather, temp or wind, listed by weather-revamped help, got: latency" ]]
}

@test "commands - status takes a place after the name" {
  # Arrange
  reading Oslo 1000000 '"temp_C":"-4","value":"Light snow"'
  now 1000001

  # Act
  tool status temp Oslo

  # Assert
  [[ "${output}" == $'-4\xc2\xb0C' ]]
}

@test "commands - refresh fetches now and says what wttr.in answered for the place" {
  # Arrange
  london
  option location Lisbon

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'Refreshed. wttr.in says Partly cloudy +18\xc2\xb0C for Lisbon.' ]]
}

@test "commands - refresh takes a place, and without one names the current location" {
  # Arrange
  london
  tool refresh
  [[ "${output}" == $'Refreshed. wttr.in says Partly cloudy +18\xc2\xb0C for the current location.' ]]

  # Act
  tool refresh "New York"

  # Assert
  [[ "${output}" == $'Refreshed. wttr.in says Partly cloudy +18\xc2\xb0C for New York.' ]]
  run asked
  [[ "${lines[1]}" == "curl -s --max-time 10 https://wttr.in/New+York?format=j1&m" ]]
}

@test "commands - refresh fails when wttr.in gives no reading, and the last one stays" {
  # Arrange
  reading auto 1000000
  answers_with "Unknown location; please try ~51.5,-0.1"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: wttr.in gave no reading for the current location, so the last one stays" ]]
  holds value_auto "${READING}"
}

@test "commands - refresh fails when no tmux server takes the reading" {
  # Arrange
  london
  : >"${FAKE}/refused"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: no tmux server is running, so the reading has nowhere to go" ]]
}

@test "commands - card prints one row per reading and says how old the answer is" {
  # Arrange
  reading auto 1000000
  now 1000300

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Location           the current location" ]]
  [[ "${lines[1]}" == $'Now                Partly cloudy +18\xc2\xb0C, feels 16\xc2\xb0C' ]]
  [[ "${lines[2]}" == "Wind               11km/h NW" ]]
  [[ "${lines[3]}" == "Humidity           65%" ]]
  [[ "${lines[4]}" == "Pressure           1013 hPa" ]]
  [[ "${lines[5]}" == "UV                 5" ]]
  [[ "${lines[6]}" == $'Dew point          18\xc2\xb0C, humid' ]]
  [[ "${lines[7]}" == "Precipitation      0.2 mm" ]]
  [[ "${lines[8]}" == "Rain chance        90%" ]]
  [[ "${lines[9]}" == "Sun                06:00 AM to 06:45 PM" ]]
  [[ "${lines[10]}" == "Moon               Waning Gibbous" ]]
  [[ "${lines[11]}" == $'Today              14 to 25\xc2\xb0C' ]]
  [[ "${lines[12]}" == $'Tomorrow           15 to 27\xc2\xb0C' ]]
  [[ "${lines[13]}" == "Read. wttr.in answered 5 minutes ago." ]]
  [[ "${#lines[@]}" -eq 14 ]]
}

@test "commands - card says one minute in the singular" {
  # Arrange
  reading auto 1000000
  now 1000060

  # Act
  tool card

  # Assert
  [[ "${lines[13]}" == "Read. wttr.in answered 1 minute ago." ]]
}

@test "commands - card fetches first when the reading is stale, for the place it was given" {
  # Arrange
  london
  now 1000000

  # Act
  tool card Oslo

  # Assert
  [[ "${lines[0]}" == "Location           Oslo" ]]
  [[ "${lines[1]}" == $'Now                Partly cloudy +18\xc2\xb0C, feels 16\xc2\xb0C' ]]
  [[ "${lines[13]}" == "Read. wttr.in answered 0 minutes ago." ]]
  run asked
  [[ "${output}" == "curl -s --max-time 10 https://wttr.in/Oslo?format=j1&m" ]]
}

@test "commands - with no reading and no answer the card has a dash in every row and says so" {
  # Arrange
  answers_with ""

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[1]}" == "Now                -" ]]
  [[ "${lines[9]}" == "Sun                -" ]]
  [[ "${lines[12]}" == "Tomorrow           -" ]]
  [[ "${lines[13]}" == "Read. wttr.in has given no reading for the current location yet." ]]
}

@test "commands - with alerts on the card has an alert row, with the alert or none" {
  # Arrange
  reading auto 1000000
  now 1000001
  option alerts on
  tool card
  [[ "${lines[13]}" == "Alert              none" ]]
  option alert_auto "Flood warning"

  # Act
  tool card

  # Assert
  [[ "${lines[13]}" == "Alert              Flood warning" ]]
  [[ "${#lines[@]}" -eq 15 ]]
}

@test "commands - in Fahrenheit the card shows every temperature in Fahrenheit" {
  # Arrange
  reading auto 1000000
  now 1000001

  # Act
  tool --units u card

  # Assert
  [[ "${lines[1]}" == $'Now                Partly cloudy +64\xc2\xb0F, feels 61\xc2\xb0F' ]]
  [[ "${lines[2]}" == "Wind               7mph NW" ]]
  [[ "${lines[6]}" == $'Dew point          65\xc2\xb0F, humid' ]]
  [[ "${lines[11]}" == $'Today              57 to 77\xc2\xb0F' ]]
}

@test "commands - where gum draws the card is a table and a closing sentence" {
  # Arrange
  reading auto 1000000
  now 1000300
  export REVAMPED_TEST_GUM=1

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Reading"*"Value"* ]]
  [[ "${output}" == *"Humidity"*"65%"* ]]
  [[ "${output}" == *"Read. wttr.in answered 5 minutes ago."* ]]
}

@test "commands - apply binds the popup key and prints nothing" {
  # Arrange
  local started='^bind-key -N Weather forecast M-w run-shell'

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${started}"
  [[ "${output}" == "1" ]]
}

@test "commands - popup opens the card in a tmux popup and prints nothing" {
  # Arrange
  local opened='^display-popup -E -w 70% -h 80% .* card; '

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${opened}"
  [[ "${output}" == "1" ]]
}

@test "commands - popup hands a place on to the card" {
  # Arrange
  local opened="^display-popup -E -w 70% -h 80% .* card 'Oslo'; "

  # Act
  tool popup Oslo

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent "${opened}"
  [[ "${output}" == "1" ]]
}

@test "commands - list prints what apply would send, and --json the same plan as one object" {
  # Arrange
  local path
  path=$(bin_path)
  option popup_key 'C-"'
  tool list
  [[ "${output}" == "bind-key -N Weather forecast C-\" run-shell ${path} popup" ]]

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[["bind-key","-N","Weather forecast","C-\"","run-shell","'*' popup"]]}' ]]
  run sends
  [[ -z "${output}" ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  reading

  # Act
  tool --json card

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: option '--json' works only with list. run 'weather-revamped help' for usage." ]]
}

@test "commands - the command line wins over the environment, and the environment over the tmux option" {
  # Arrange
  reading auto 1000000
  now 1000001
  option alert_auto "Flood"
  option alert_prefix 'option: '
  tool status alert
  [[ "${output}" == "option: Flood" ]]
  export WEATHER_REVAMPED_ALERT_PREFIX='environment: '
  tool status alert
  [[ "${output}" == "environment: Flood" ]]

  # Act
  tool --alert-prefix 'line: ' status alert

  # Assert
  [[ "${output}" == "line: Flood" ]]
}

@test "commands - an option takes its value after a space or an equals sign, and an empty one is used as given" {
  # Arrange
  reading auto 1000000
  now 1000001
  option alert_auto "Flood"
  option alert_prefix 'option: '
  tool --alert-prefix=A: status alert
  [[ "${output}" == "A:Flood" ]]

  # Act
  tool --alert-prefix '' status alert

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Flood" ]]
}

@test "commands - an unknown option, one without its value and a word after a double dash are usage errors" {
  # Arrange
  tool --colour red status weather
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: unknown option '--colour'. run 'weather-revamped help' for usage." ]]
  tool --colour=red status weather
  [[ "${output}" == "weather-revamped: unknown option '--colour'. run 'weather-revamped help' for usage." ]]
  tool -x
  [[ "${output}" == "weather-revamped: unknown option '-x'. run 'weather-revamped help' for usage." ]]
  tool status --interval
  [[ "${output}" == "weather-revamped: option '--interval' needs a value. run 'weather-revamped help' for usage." ]]

  # Act
  tool -- --interval

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: unknown command '--interval'. run 'weather-revamped help' for usage." ]]
}

@test "commands - a number is checked before anything runs, whichever setting carries it" {
  # Arrange
  tool --interval soon status weather
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: --interval must be a whole number, got: soon" ]]
  tool --fetch-minutes often status weather
  [[ "${output}" == "weather-revamped: --fetch-minutes must be a whole number, got: often" ]]
  tool --temp-width wide status weather
  [[ "${output}" == "weather-revamped: --temp-width must be a whole number, got: wide" ]]
  tool --umbrella-threshold likely status weather
  [[ "${output}" == "weather-revamped: --umbrella-threshold must be a whole number, got: likely" ]]

  # Act
  tool --pressure-delta big status weather

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: --pressure-delta must be a whole number, got: big" ]]
}

@test "commands - a bad number is reported alone, since the reader of the environment reads it to the end" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  cat >"${BATS_TEST_TMPDIR}/stubs/env" <<'STUB'
#!/bin/sh
{ set +x; } 2>/dev/null
trap '' PIPE
printf 'WEATHER_REVAMPED_INTERVAL=soon\n'
count=0
while [ "${count}" -lt 4000 ]; do
  printf 'FILLER_%s=%0100d\n' "${count}" 0 || exit 1
  count=$((count + 1))
done
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/env"

  # Act
  tool status weather

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: --interval must be a whole number, got: soon" ]]
}

@test "commands - a fetch interval of zero is refused before anything runs" {
  # Arrange
  reading auto 1000000

  # Act
  tool --fetch-minutes 0 status weather

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: --fetch-minutes must be a whole number of at least 1, got: 0" ]]
}

@test "commands - a width given as nothing is no width" {
  # Arrange
  reading auto 1000000
  now 1000001

  # Act
  tool --temp-width '' status temp

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'18\xc2\xb0C' ]]
}

@test "commands - each switch and each choice is checked before anything runs" {
  # Arrange
  tool --hide-units maybe status weather
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: --hide-units must be on or off, got: maybe" ]]
  tool --alerts sometimes status weather
  [[ "${output}" == "weather-revamped: --alerts must be on or off, got: sometimes" ]]
  tool --show-condition-icon never status weather
  [[ "${output}" == "weather-revamped: --show-condition-icon must be on or off, got: never" ]]
  tool --fixed-width wide status weather
  [[ "${output}" == "weather-revamped: --fixed-width must be on or off, got: wide" ]]
  tool --units kelvin status weather
  [[ "${output}" == "weather-revamped: --units must be m, u, f, fahrenheit or imperial, got: kelvin" ]]
  tool --notify on status weather
  [[ "${output}" == "weather-revamped: --notify must be 0 or 1, got: on" ]]

  # Act
  tool --render fast status weather

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "weather-revamped: --render must be jobs or options, got: fast" ]]
}

@test "commands - doctor names curl with its version, the age of the reading and the notifier" {
  # Arrange
  curl_version
  notifier notify-send
  reading auto 1000000
  now 1000600

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  has_line "curl               ok       ${BATS_TEST_TMPDIR}/stubs/curl, 8.7.1"
  has_line "reading            ok       the current location, answered 10 minutes ago"
  has_line "settings           ok       every option holds a value it knows"
  has_line "notifier           ok       notify-send"
  has_line "keys               ok       every key it binds is free or its own"
}

@test "commands - a tmux option that still says fahrenheit shows Fahrenheit" {
  # Arrange
  reading auto 1000000
  now 1000001
  option units fahrenheit

  # Act
  tool status temp

  # Assert
  [[ "${output}" == $'64\xc2\xb0F' ]]
}

@test "commands - the command takes the older spellings of the units and of on" {
  # Arrange
  reading auto 1000000
  now 1000001

  # Act
  tool --units imperial --hide-units yes status temp

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'64\xc2\xb0' ]]
}

@test "commands - doctor names each tmux option whose value it does not know" {
  # Arrange
  curl_version
  option units celsius
  option alerts maybe
  option fetch_minutes soon

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  has_line "settings           warn     unknown values, so their defaults apply: units=celsius alerts=maybe fetch_minutes=soon"
}

@test "commands - doctor fails without curl, and says there is no reading and no notifier" {
  # Arrange
  option location Lisbon

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  has_line "curl               missing  it fetches the weather: brew install curl, or apt install curl"
  has_line "reading            warn     none yet for Lisbon: run weather-revamped refresh"
  has_line "notifier           warn     no osascript or notify-send, so notifications stay in the status line"
}

@test "commands - doctor names a default key someone else holds" {
  # Arrange
  curl_version
  printf 'bind-key    -T prefix M-w     display-message mine\n' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  has_line "keys               warn     already bound and left alone: M-w"
}

@test "commands - version prints the version and the tmux it runs on" {
  # Arrange
  local version
  version=$(sed -n 's/^readonly WEATHER_REVAMPED_VERSION="\(.*\)"$/\1/p' "${REVAMPED_TESTS_DIR}/../lib/core.sh")

  # Act
  tool version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "weather-revamped ${version}" ]]
  [[ "${lines[1]}" == "tmux: 3.6" ]]
}
