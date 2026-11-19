#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/weather_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/weather_helpers.bash"

RECALLED='weather_revamped_load; weather_revamped_now; weather_revamped_limit; weather_revamped_choose ""; weather_revamped_recall; '

fetched() {
  lib_run weather "${RECALLED}"'weather_revamped_fetch'
}

status_of() {
  lib_run weather 'weather_revamped_status '"$1"' "'"${2:-}"'"'
}

pairs() {
  local value
  value=$(held "$1")
  awk -F '","' '{ print NF }' <<<"${value}"
}

@test "readers - an answer is cut down to the fields the plugin reads, on one line" {
  # Arrange
  export BODY='{"current_condition":[{"FeelsLikeC": "16", "cloudcover":"50",
"temp_C" : "18", "weatherDesc":[{"value":"Sunny"}], "weatherCode":"113"}]}'

  # Act
  lib_run weather 'printf "%s\n" "${BODY}" | weather_revamped_compact'

  # Assert
  [[ "${output}" == '"FeelsLikeC":"16","temp_C":"18","value":"Sunny"' ]]
}

@test "readers - a fetch asks wttr.in for the place with its spaces as plus signs, in the unit set" {
  # Arrange
  london
  option location "New York"
  option units u

  # Act
  fetched

  # Assert
  run asked
  [[ "${output}" == "curl -s --max-time 10 https://wttr.in/New+York?format=j1&u" ]]
}

@test "readers - with no place wttr.in is asked to locate by address, in metric" {
  # Arrange
  london

  # Act
  fetched

  # Assert
  run asked
  [[ "${output}" == "curl -s --max-time 10 https://wttr.in/?format=j1&m" ]]
}

@test "readers - a fetch stores the reading and both of its times in one tmux call" {
  # Arrange
  london
  now 1000900

  # Act
  fetched

  # Assert
  run sent '^set-option'
  [[ "${output}" == "1" ]]
  run pairs value_auto
  [[ "${output}" == "55" ]]
  holds value_auto_ts 1000900
  holds auto_ok_ts 1000900
  holds auto_pressure_prev ""
}

@test "readers - a fetch over an older reading keeps that one's pressure for the trend" {
  # Arrange
  london
  with pressure=1002

  # Act
  fetched

  # Assert
  holds auto_pressure_prev 1002
  run pairs value_auto
  [[ "${output}" == "55" ]]
}

@test "readers - an answer that says the location is unknown is dropped, and only the time of the try moves" {
  # Arrange
  reading auto 1000000
  answers_with "Unknown location; please try ~51.5,-0.1"
  now 1000900

  # Act
  fetched

  # Assert
  holds value_auto "${READING}"
  holds value_auto_ts 1000900
  holds auto_ok_ts 1000000
}

@test "readers - an answer holding ERROR is dropped" {
  # Arrange
  reading auto 1000000
  answers_with '{"temp_C":"99"} ERROR: upstream'

  # Act
  fetched

  # Assert
  holds value_auto "${READING}"
}

@test "readers - an answer that starts with Sorry is dropped" {
  # Arrange
  reading auto 1000000
  answers_with 'Sorry, we are running out of queries. "temp_C":"99"'

  # Act
  fetched

  # Assert
  holds value_auto "${READING}"
}

@test "readers - no answer at all leaves the reading alone" {
  # Arrange
  reading auto 1000000
  answers_with ""

  # Act
  fetched

  # Assert
  holds value_auto "${READING}"
}

@test "readers - with alerts on, the first line of the alert address is stored, the place written into it" {
  # Arrange
  london $'\n  \nFlood warning until 18:00\nSecond line'
  option location "New York"
  option alerts on
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  holds alert_New_York "Flood warning until 18:00"
  run asked
  [[ "${lines[1]}" == "curl -s --max-time 10 https://github.com/tmux-revamped/tmux-weather-revamped/New+York" ]]
}

@test "readers - with alerts off nothing but the weather is fetched" {
  # Arrange
  london "Flood warning"
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  run asked
  [[ "${#lines[@]}" -eq 1 ]]
  holds alert_auto ""
}

@test "readers - alerts with no address store an empty alert and fetch nothing more" {
  # Arrange
  london "Flood warning"
  option alerts on
  option alert_auto "Old warning"

  # Act
  fetched

  # Assert
  run asked
  [[ "${#lines[@]}" -eq 1 ]]
  holds alert_auto ""
}

@test "readers - a new alert is sent as a desktop notification on Linux when notify is 1" {
  # Arrange
  london "Flood warning"
  notifier notify-send
  option alerts on
  option notify 1
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  run notified
  [[ "${output}" == "-- Weather alert Flood warning" ]]
}

@test "readers - on macOS the notification carries the title and the alert as arguments" {
  # Arrange
  london "Flood warning"
  macos
  notifier osascript
  option alerts on
  option notify 1
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  run notified
  [[ "${output}" == *"end run Weather alert Flood warning" ]]
}

@test "readers - an alert already stored is not notified again" {
  # Arrange
  london "Flood warning"
  notifier notify-send
  option alerts on
  option notify 1
  option alert_auto "Flood warning"
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  run notified
  [[ -z "${output}" ]]
}

@test "readers - notifications are off until notify is 1" {
  # Arrange
  london "Flood warning"
  notifier notify-send
  option alerts on
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  run notified
  [[ -z "${output}" ]]
  holds alert_auto "Flood warning"
}

@test "readers - an alert tmux did not store is not notified, and the last one stays" {
  # Arrange
  london "Flood warning"
  notifier notify-send
  option alerts on
  option notify 1
  option alert_auto "Old warning"
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'
  printf 'set-option -gq @weather_revamped_alert_auto Flood warning\n' >"${FAKE}/refused"

  # Act
  fetched

  # Assert
  run notified
  [[ -z "${output}" ]]
  holds alert_auto "Old warning"
}

@test "readers - the alert is written in a tmux call of its own, after the reading" {
  # Arrange
  london "Flood warning"
  option alerts on
  option alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'

  # Act
  fetched

  # Assert
  run grep -c '^set-option' "${FAKE}/log"
  [[ "${output}" == "2" ]]
  run grep '^set-option' "${FAKE}/log"
  [[ "${lines[0]}" == "set-option -gq @weather_revamped_value_auto "*" ; set-option -gq @weather_revamped_auto_ok_ts 1000000 ; set-option -gq @weather_revamped_value_auto_ts 1000000" ]]
  [[ "${lines[1]}" == "set-option -gq @weather_revamped_alert_auto Flood warning" ]]
}

@test "readers - an answer of the size wttr.in sends is read by every placeholder" {
  # Arrange
  full_answer

  # Act
  lib_run weather "${RECALLED}"'weather_revamped_fetch; weather_revamped_read; for name in weather feels_like humidity pressure precip rain_chance uv dew_point moon sunrise sunset forecast today_high today_low tomorrow_high tomorrow_low; do weather_revamped_value "${name}"; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; done'

  # Assert
  [[ "${output}" == $'[Clear +10\xc2\xb0C][9][87][986][0.0][41][0][7][Waxing Gibbous][07:24 AM][04:07 PM][7-10][12][9][10][7]' ]]
}

@test "readers - status prints a fresh reading at once and fetches nothing" {
  # Arrange
  london
  reading auto 1000000
  now 1000900

  # Act
  status_of weather

  # Assert
  [[ "${output}" == $'Partly cloudy +18\xc2\xb0C' ]]
  run asked
  [[ -z "${output}" ]]
}

@test "readers - status prints a stale reading at once and starts one fetch in the background" {
  # Arrange
  london
  with temp_C=5
  now 1000901

  # Act
  status_of temp

  # Assert
  [[ "${output}" == $'5\xc2\xb0C' ]]
  eventually holds value_auto_ts 1000901
  eventually holds value_auto_lock 0
  run pairs value_auto
  [[ "${output}" == "55" ]]
}

@test "readers - status with no reading yet prints nothing and starts the first fetch" {
  # Arrange
  london
  now 1000000

  # Act
  status_of weather

  # Assert
  [[ -z "${output}" ]]
  eventually holds auto_ok_ts 1000000
  eventually holds value_auto_lock 0
}

@test "readers - status starts no fetch while one from the last half minute is under way" {
  # Arrange
  london
  reading auto 1000000
  option value_auto_lock 1
  option value_auto_lock_ts 1000880
  now 1000905

  # Act
  status_of weather

  # Assert
  [[ "${output}" == $'Partly cloudy +18\xc2\xb0C' ]]
  run asked
  [[ -z "${output}" ]]
}

@test "readers - status takes over a fetch that has held its lock for half a minute" {
  # Arrange
  london
  reading auto 1000000
  option value_auto_lock 1
  option value_auto_lock_ts 1000870
  now 1000905

  # Act
  status_of weather

  # Assert
  eventually holds value_auto_ts 1000905
  eventually holds value_auto_lock 0
}

@test "readers - status for a place given by hand reads that place's own reading" {
  # Arrange
  london
  reading auto 1000000
  reading Oslo 1000000 '"temp_C":"-4","value":"Light snow"'
  now 1000001

  # Act
  status_of weather Oslo

  # Assert
  [[ "${output}" == $'Light snow -4\xc2\xb0C' ]]
}

@test "readers - a junk fetch interval means fifteen minutes" {
  # Arrange
  option fetch_minutes soon

  # Act
  lib_run weather 'weather_revamped_load; weather_revamped_limit; printf "%s" "${WEATHER_REVAMPED_LIMIT}"'

  # Assert
  [[ "${output}" == "900" ]]
}

@test "readers - the fetch interval is read in minutes, and zero, a leading zero and nothing do not break it" {
  # Arrange
  local script='weather_revamped_load; for value in 30 0 08 ""; do WEATHER_REVAMPED_S_fetch_minutes="${value}"; weather_revamped_limit; printf "[%s]" "${WEATHER_REVAMPED_LIMIT}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[1800][900][480][900]" ]]
}

@test "readers - a fetch interval of zero is noted as unknown" {
  # Arrange
  local script='weather_revamped_load; for value in 0 00 15; do WEATHER_REVAMPED_S_fetch_minutes="${value}"; weather_revamped_settle; printf "[%s]" "${WEATHER_REVAMPED_ODD}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[fetch_minutes=0][fetch_minutes=00][]" ]]
}

@test "readers - an interval of 15 carried over from the old option still means fifteen minutes" {
  # Arrange
  london
  reading auto 1000000
  option fetch_minutes 15
  now 1000600

  # Act
  status_of weather

  # Assert
  [[ "${output}" == $'Partly cloudy +18\xc2\xb0C' ]]
  run asked
  [[ -z "${output}" ]]
}

@test "readers - a tick fetches every stale place of the list and publishes the first one" {
  # Arrange
  london
  option locations "Lisbon;Oslo"
  option published "weather temp"
  now 1000000

  # Act
  lib_run weather 'weather_revamped_tick'

  # Assert
  run asked
  [[ "${lines[0]}" == "curl -s --max-time 10 https://wttr.in/Lisbon?format=j1&m" ]]
  [[ "${lines[1]}" == "curl -s --max-time 10 https://wttr.in/Oslo?format=j1&m" ]]
  holds out_weather $'Partly cloudy +18\xc2\xb0C'
  holds out_temp $'18\xc2\xb0C'
  holds Oslo_ok_ts 1000000
}

@test "readers - a tick publishes an alert of more than a thousand characters in a tmux call of its own" {
  # Arrange
  local long
  long=$(awk 'BEGIN { for (i = 0; i < 1001; i++) { printf "a" } }')
  reading
  option alert_auto "${long}"
  option published "weather alert temp"

  # Act
  lib_run weather 'weather_revamped_tick'

  # Assert
  run grep '^set-option -gq @weather_revamped_out_' "${FAKE}/log"
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "set-option -gq @weather_revamped_out_weather "*" ; set-option -gq @weather_revamped_out_temp "* ]]
  [[ "${lines[0]}" != *"out_alert"* ]]
  [[ "${lines[1]}" == "set-option -gq @weather_revamped_out_alert ${long}"* ]]
}

@test "readers - a tick publishes an alert of a thousand characters with the other names, in one call" {
  # Arrange
  local short
  short=$(awk 'BEGIN { for (i = 0; i < 1000; i++) { printf "a" } }')
  reading
  option alert_auto "${short}"
  option published "weather alert temp"

  # Act
  lib_run weather 'weather_revamped_tick'

  # Assert
  run grep '^set-option -gq @weather_revamped_out_' "${FAKE}/log"
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${lines[0]}" == *"set-option -gq @weather_revamped_out_alert ${short} ; set-option -gq @weather_revamped_out_temp "* ]]
}

@test "readers - a tick over fresh readings fetches nothing and still publishes" {
  # Arrange
  london
  reading auto 1000000
  option published "humidity"
  now 1000100

  # Act
  lib_run weather 'weather_revamped_tick'

  # Assert
  run asked
  [[ -z "${output}" ]]
  holds out_humidity 65
}
