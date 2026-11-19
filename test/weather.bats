#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/weather_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/weather_helpers.bash"

RECALLED='weather_revamped_load; weather_revamped_now; weather_revamped_limit; weather_revamped_choose ""; weather_revamped_recall; weather_revamped_read; '

each() {
  lib_run weather "${RECALLED}"'for name in '"$1"'; do weather_revamped_value "${name}"; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; done'
}

shown() {
  lib_run weather "${RECALLED}"'weather_revamped_show '"$1"
}

@test "weather - each plain placeholder prints its field of the stored reading" {
  # Arrange
  reading

  # Act
  each "feels_like humidity pressure precip rain_chance uv dew_point moon sunrise sunset forecast today_high today_low tomorrow_high tomorrow_low"

  # Assert
  [[ "${output}" == "[16][65][1013][0.2][90][5][18][Waning Gibbous][06:00 AM][06:45 PM][15-27][25][14][27][15]" ]]
}

@test "weather - the line is the condition, a plus and the temperature with its unit" {
  # Arrange
  reading

  # Act
  shown weather

  # Assert
  [[ "${output}" == $'Partly cloudy +18\xc2\xb0C' ]]
}

@test "weather - a temperature below zero carries its own sign and no plus" {
  # Arrange
  with temp_C=-3

  # Act
  shown weather

  # Assert
  [[ "${output}" == $'Partly cloudy -3\xc2\xb0C' ]]
}

@test "weather - a reading with no condition prints the temperature alone" {
  # Arrange
  with value=

  # Act
  shown weather

  # Assert
  [[ "${output}" == $'+18\xc2\xb0C' ]]
}

@test "weather - a hash in the condition is doubled, so tmux draws it as text" {
  # Arrange
  with 'value=Rain #S'

  # Act
  shown weather

  # Assert
  [[ "${output}" == $'Rain ##S +18\xc2\xb0C' ]]
}

@test "weather - with units u every temperature is Fahrenheit and the wind is in miles" {
  # Arrange
  reading
  option units u

  # Act
  each "weather temp feels_like wind forecast dew_point today_high today_low"

  # Assert
  [[ "${output}" == $'[Partly cloudy +64\xc2\xb0F][64\xc2\xb0F][61][7mph NW][59-81][65][77][57]' ]]
}

@test "weather - the wind is the speed, its unit and the direction when there is one" {
  # Arrange
  reading
  local script="${RECALLED}"'weather_revamped_value wind; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_R_wind_dir=""; weather_revamped_value wind; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_R_wind_speed=""; weather_revamped_value wind; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[11km/h NW][11km/h][]" ]]
}

@test "weather - the temperature drops its unit, and is padded to five characters or to its own width" {
  # Arrange
  reading
  local script="${RECALLED}"'weather_revamped_value temp; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_S_hide_units=on; weather_revamped_value temp; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_S_hide_units=off WEATHER_REVAMPED_S_fixed_width=on; weather_revamped_value temp; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_S_temp_width=7; weather_revamped_value temp; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_S_temp_width=2; weather_revamped_value temp; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == $'[18\xc2\xb0C][18\xc2\xb0][ 18\xc2\xb0C][   18\xc2\xb0C][18\xc2\xb0C]' ]]
}

@test "weather - a width written with a leading zero is read as a decimal number" {
  # Arrange
  reading
  local script="${RECALLED}"'WEATHER_REVAMPED_S_temp_width=07; weather_revamped_value temp; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == $'[   18\xc2\xb0C]' ]]
}

@test "weather - the colour follows the Celsius band, with its edges at 0, 9, 17, 23 and 31" {
  # Arrange
  local script='weather_revamped_load; for degrees in -1 0 9 10 17 18 23 24 31 32; do WEATHER_REVAMPED_R_temp_c="${degrees}"; weather_revamped_value color; printf "%s " "${WEATHER_REVAMPED_OUT}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "#[fg=blue] #[fg=cyan] #[fg=cyan] #[fg=green] #[fg=green] #[fg=green] #[fg=green] #[fg=yellow] #[fg=yellow] #[fg=red] " ]]
}

@test "weather - in Fahrenheit the band still comes from the Celsius temperature" {
  # Arrange
  reading
  option units u
  option comfortable_icon mild
  option very_hot_icon scorching

  # Act
  each "color icon"

  # Assert
  [[ "${output}" == "[#[fg=green]][mild]" ]]
}

@test "weather - each band prints its own icon, and nothing until one is set" {
  # Arrange
  option freezing_icon F
  option cold_icon C
  option cool_icon c
  option hot_icon H
  option very_hot_icon V
  local script='weather_revamped_load; for degrees in -5 5 15 20 28 40; do WEATHER_REVAMPED_R_temp_c="${degrees}"; weather_revamped_value icon; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[F][C][c][][H][V]" ]]
}

@test "weather - the sky is read from the condition, whatever its case, and picks the tint" {
  # Arrange
  local script='weather_revamped_load; WEATHER_REVAMPED_R_temp=18; for sky in "Thundery outbreaks" "Light snow" "Ice pellets" "Patchy rain nearby" "HEAVY RAIN" "Light drizzle" "Mist" "Haze" "Overcast" "Partly cloudy" "Sunny"; do WEATHER_REVAMPED_R_condition="${sky}"; weather_revamped_value condition_tint; printf "%s " "${WEATHER_REVAMPED_OUT#??fg=}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "magenta] white] white] blue] blue] blue] brightblack] brightblack] brightblack] brightblack] yellow] " ]]
}

@test "weather - the condition icon is the glyph of the sky, the one set for it, or nothing when switched off" {
  # Arrange
  reading
  local script="${RECALLED}"'weather_revamped_value condition_icon; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_S_clouds_condition_icon=cloudy; weather_revamped_value condition_icon; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_S_show_condition_icon=off; weather_revamped_value condition_icon; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == $'[\xf3\xb0\x96\x90][cloudy][]' ]]
}

@test "weather - every sky has its own default glyph" {
  # Arrange
  local script='weather_revamped_load; WEATHER_REVAMPED_R_temp=18; for sky in Thunder Snow Rain Fog Cloudy Sunny; do WEATHER_REVAMPED_R_condition="${sky}"; weather_revamped_value condition_icon; printf "%s" "${WEATHER_REVAMPED_OUT}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == $'\xf3\xb0\x96\x93\xf3\xb0\x96\x98\xf3\xb0\x96\x97\xf3\xb0\x96\x91\xf3\xb0\x96\x90\xf3\xb0\x96\x99' ]]
}

@test "weather - the UV colour changes at 3, 6, 8 and 11" {
  # Arrange
  local script='weather_revamped_load; for index in 2 3 5 6 7 8 10 11; do WEATHER_REVAMPED_R_uv="${index}"; weather_revamped_value uv_color; printf "%s " "${WEATHER_REVAMPED_OUT#??fg=}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "green] yellow] yellow] colour208] colour208] red] red] magenta] " ]]
}

@test "weather - the dew comfort comes from the Celsius dew point, with its edges at 13, 15 and 18" {
  # Arrange
  local script='weather_revamped_load; for dew in 12 13 15 16 18 19; do WEATHER_REVAMPED_R_dew_c="${dew}"; weather_revamped_value dew_comfort; printf "%s " "${WEATHER_REVAMPED_OUT}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "dry comfortable comfortable humid humid oppressive " ]]
}

@test "weather - the umbrella text shows from the threshold up, with the chance written in" {
  # Arrange
  reading
  option umbrella_text 'take it, {chance}% then {chance}'
  local script="${RECALLED}"'for limit in 50 90 91 junk; do WEATHER_REVAMPED_S_umbrella_threshold="${limit}"; weather_revamped_value umbrella; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[take it, 90% then 90][take it, 90% then 90][][take it, 90% then 90]" ]]
}

@test "weather - the pressure trend compares with the pressure of the fetch before" {
  # Arrange
  reading
  local script="${RECALLED}"'for before in 1010 1016 1013 1012 "" junk; do WEATHER_REVAMPED_PREVIOUS="${before}"; weather_revamped_value pressure_trend; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; done; WEATHER_REVAMPED_PREVIOUS=1010 WEATHER_REVAMPED_S_pressure_delta=5; weather_revamped_value pressure_trend; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[^][v][=][=][][][=]" ]]
}

@test "weather - the stored previous pressure is the one the trend reads" {
  # Arrange
  reading
  option auto_pressure_prev 1002
  option pressure_rising up

  # Act
  shown pressure_trend

  # Assert
  [[ "${output}" == "up" ]]
}

@test "weather - the stale colour shows once the last answer is older than three intervals" {
  # Arrange
  reading auto 1000000
  local script='weather_revamped_load; weather_revamped_limit; weather_revamped_choose ""; weather_revamped_recall; for clock in 1002700 1002701; do WEATHER_REVAMPED_NOW="${clock}"; weather_revamped_value stale_color; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; done; WEATHER_REVAMPED_OK_TS=""; weather_revamped_value stale_color; printf "[%s]" "${WEATHER_REVAMPED_OUT}"; WEATHER_REVAMPED_VALUE=""; weather_revamped_value stale_color; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[][#[dim]][#[dim]][]" ]]
}

@test "weather - the alert is printed behind its prefix with every hash doubled" {
  # Arrange
  reading
  option alert_auto 'Flood warning #1'
  option alert_prefix '! '

  # Act
  shown alert

  # Assert
  [[ "${output}" == "! Flood warning ##1" ]]
}

@test "weather - with no reading every placeholder prints nothing" {
  # Arrange
  now 1000000

  # Act
  each "weather temp feels_like wind humidity pressure pressure_trend precip rain_chance umbrella uv uv_color dew_point dew_comfort moon sunrise sunset forecast today_high today_low tomorrow_high tomorrow_low condition_icon condition_tint color icon stale_color alert"

  # Assert
  [[ "${output}" == "[][][][][][][][][][][][][][][][][][][][][][][][][][][][]" ]]
}

@test "weather - a tmux option set to nothing means its default, and an empty environment value is used" {
  # Arrange
  reading auto 1
  option stale_color ""
  local script="${RECALLED}"'weather_revamped_value stale_color; printf "[%s]" "${WEATHER_REVAMPED_OUT}"'

  # Act
  lib_run weather "${script}; export WEATHER_REVAMPED_STALE_COLOR=; ${script}"

  # Assert
  [[ "${output}" == "[#[dim]][]" ]]
}

@test "weather - every older spelling of Fahrenheit is read as u, and an unknown unit is metric and noted" {
  # Arrange
  local script='weather_revamped_load; for value in u f F fahrenheit Fahrenheit imperial m celsius; do WEATHER_REVAMPED_S_units="${value}"; weather_revamped_settle; printf "[%s%s]" "${WEATHER_REVAMPED_S_units}" "${WEATHER_REVAMPED_ODD:+ ${WEATHER_REVAMPED_ODD}}"; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[u][u][u][u][u][u][m][m units=celsius]" ]]
}

@test "weather - an on or off setting reads 1, yes and true as on, and an unknown value takes its default and is noted" {
  # Arrange
  local script='weather_revamped_load; for value in on 1 yes true off 0 no false maybe; do WEATHER_REVAMPED_S_alerts="${value}"; weather_revamped_settle; printf "[%s%s]" "${WEATHER_REVAMPED_S_alerts}" "${WEATHER_REVAMPED_ODD:+ ${WEATHER_REVAMPED_ODD}}"; done; WEATHER_REVAMPED_S_alerts=off WEATHER_REVAMPED_S_show_condition_icon=perhaps; weather_revamped_settle; printf "[%s %s]" "${WEATHER_REVAMPED_S_show_condition_icon}" "${WEATHER_REVAMPED_ODD}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[on][on][on][on][off][off][off][off][off alerts=maybe][on show_condition_icon=perhaps]" ]]
}

@test "weather - an unknown render mode, notify value or number in a tmux option takes its default and is noted" {
  # Arrange
  option render fast
  option notify on
  option interval x
  option umbrella_threshold y
  option pressure_delta z
  option temp_width w

  # Act
  lib_run weather 'weather_revamped_load; printf "[%s][%s][%s]" "${WEATHER_REVAMPED_S_render}" "${WEATHER_REVAMPED_S_notify}" "${WEATHER_REVAMPED_ODD}"'

  # Assert
  [[ "${output}" == "[jobs][0][render=fast notify=on interval=x umbrella_threshold=y pressure_delta=z temp_width=w]" ]]
}

@test "weather - the first place of the list is the one shown, and a place given by hand wins" {
  # Arrange
  local script='weather_revamped_load; weather_revamped_choose ""; printf "[%s:%s]" "${WEATHER_REVAMPED_PLACE}" "${WEATHER_REVAMPED_SLUG}"; WEATHER_REVAMPED_S_location="Sao Paulo, BR"; weather_revamped_choose ""; printf "[%s:%s]" "${WEATHER_REVAMPED_PLACE}" "${WEATHER_REVAMPED_SLUG}"; WEATHER_REVAMPED_S_locations="Lisbon;Oslo"; weather_revamped_choose ""; printf "[%s:%s]" "${WEATHER_REVAMPED_PLACE}" "${WEATHER_REVAMPED_SLUG}"; weather_revamped_choose Oslo; printf "[%s:%s]" "${WEATHER_REVAMPED_PLACE}" "${WEATHER_REVAMPED_SLUG}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[:auto][Sao Paulo, BR:Sao_Paulo__BR][Lisbon:Lisbon][Oslo:Oslo]" ]]
}

@test "weather - a place outside ASCII gets one underscore per byte in its option name" {
  # Arrange
  local place=$'Z\xc3\xbcrich'

  # Act
  lib_run weather 'weather_revamped_place "'"${place}"'"; printf "%s" "${WEATHER_REVAMPED_SLUG}"'

  # Assert
  [[ "${output}" == "Z__rich" ]]
}

@test "weather - a reading stored over several lines is joined and still read" {
  # Arrange
  local script='weather_revamped_recall_split <<EOF
1000000
0



Storm
"temp_C":"18"
"value":"Sunny"
EOF
printf "[%s][%s][%s]" "${WEATHER_REVAMPED_VALUE_TS}" "${WEATHER_REVAMPED_ALERT}" "${WEATHER_REVAMPED_VALUE}"'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == '[1000000][Storm]["temp_C":"18","value":"Sunny"]' ]]
}

@test "weather - the dew point is the mean of the first eight slots and the rain chance their highest" {
  # Arrange
  local slots="" count
  for count in 1 2 3 4 5 6 7 8; do
    slots="${slots},\"DewPointC\":\"1${count}\",\"chanceofrain\":\"${count}0\""
  done
  reading auto 1000000 "\"temp_C\":\"18\"${slots},\"DewPointC\":\"99\",\"chanceofrain\":\"100\""

  # Act
  each "dew_point rain_chance"

  # Assert
  [[ "${output}" == "[14][80]" ]]
}

@test "weather - a tmux version is read out of its banner and compared part by part" {
  # Arrange
  local script='for banner in "tmux 3.6a" "tmux next-3.7" "nonsense"; do printf "[%s]" "$(weather_revamped_parse_version "${banner}")"; done; for pair in "3.6 3.2" "3.2 3.2" "3.1 3.2" "4.0 3.2" "2.9 3.2" " 3.2" "x 3.2"; do if weather_revamped_version_ge ${pair}; then printf y; else printf n; fi; done'

  # Act
  lib_run weather "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][]yynynnn" ]]
}
