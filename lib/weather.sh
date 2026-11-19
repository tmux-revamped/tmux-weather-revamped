#!/bin/sh

[ -n "${WEATHER_REVAMPED_WEATHER_LOADED:-}" ] && return 0
WEATHER_REVAMPED_WEATHER_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB}/cache.sh"
# shellcheck source=SCRIPTDIR/publish.sh
. "${REVAMPED_LIB}/publish.sh"
# shellcheck source=SCRIPTDIR/ticker.sh
. "${REVAMPED_LIB}/ticker.sh"
# shellcheck source=SCRIPTDIR/notify.sh
. "${REVAMPED_LIB}/notify.sh"

weather_revamped_format() {
  printf '%s\n' "${WEATHER_REVAMPED_SETTINGS}" | awk -F '\t' -v live="${WEATHER_REVAMPED_LIVE}" '{ printf "%s#{@weather_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { count = split(live, name, " "); for (i = 1; i <= count; i++) { printf "\t#{@weather_revamped_%s}", name[i] } }'
}

weather_revamped_resolve() {
  env | WEATHER_REVAMPED_ROWS="${WEATHER_REVAMPED_SETTINGS}" WEATHER_REVAMPED_VALUES="$1" awk -v live="${WEATHER_REVAMPED_LIVE}" '
    BEGIN {
      count = split(ENVIRON["WEATHER_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["WEATHER_REVAMPED_VALUES"], given, "\t")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at == 0) { at = length(rows[i]) + 1 }
        name[i] = substr(rows[i], 1, at - 1)
        value[i] = (given[i] != "") ? given[i] : substr(rows[i], at + 1)
        want["WEATHER_REVAMPED_" toupper(name[i])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) {
        value[want[key]] = substr($0, at + 1)
      }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      extra = split(live, state, " ")
      for (i = 1; i <= extra; i++) { print state[i] "\t" given[count + i] }
    }
  '
}

weather_revamped_load() {
  weather_revamped_load_format=$(weather_revamped_format)
  weather_revamped_load_live=$(tmux display-message -p "${weather_revamped_load_format}" 2>/dev/null) || weather_revamped_load_live=""
  weather_revamped_load_values=$(weather_revamped_resolve "${weather_revamped_load_live}")
  while IFS='	' read -r weather_revamped_load_name weather_revamped_load_value; do
    IFS= read -r "WEATHER_REVAMPED_S_${weather_revamped_load_name}" <<EOF
${weather_revamped_load_value}
EOF
  done <<EOF
${weather_revamped_load_values}
EOF
  weather_revamped_settle
}

weather_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

weather_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  weather_revamped_version_ge_have="${1%%.*}"
  weather_revamped_version_ge_want="${2%%.*}"
  [ "${weather_revamped_version_ge_have}" -gt "${weather_revamped_version_ge_want}" ] && return 0
  [ "${weather_revamped_version_ge_have}" -eq "${weather_revamped_version_ge_want}" ] || return 1
  weather_revamped_version_ge_have="${1#*.}"
  weather_revamped_version_ge_want="${2#*.}"
  [ "${weather_revamped_version_ge_have%%.*}" -ge "${weather_revamped_version_ge_want%%.*}" ]
}

weather_revamped_emit() {
  for weather_revamped_emit_arg in "$@"; do
    case "${weather_revamped_emit_arg}" in
    *\;) weather_revamped_emit_arg="${weather_revamped_emit_arg%;}\\;" ;;
    *) ;;
    esac
    WEATHER_REVAMPED_PLAN="${WEATHER_REVAMPED_PLAN}${weather_revamped_emit_arg:-${WEATHER_REVAMPED_EMPTY}}
"
  done
  WEATHER_REVAMPED_PLAN="${WEATHER_REVAMPED_PLAN}
"
}

weather_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

weather_revamped_send() {
  set --
  weather_revamped_send_sep=""
  while IFS= read -r weather_revamped_send_line; do
    if [ -z "${weather_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || weather_revamped_send_sep=";"
      continue
    fi
    [ -z "${weather_revamped_send_sep}" ] || set -- "$@" "${weather_revamped_send_sep}"
    weather_revamped_send_sep=""
    [ "${weather_revamped_send_line}" != "${WEATHER_REVAMPED_EMPTY}" ] || weather_revamped_send_line=""
    set -- "$@" "${weather_revamped_send_line}"
  done <<PLAN
${WEATHER_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

weather_revamped_send_each() {
  weather_revamped_send_each_status=0
  set --
  while IFS= read -r weather_revamped_send_each_line; do
    if [ -n "${weather_revamped_send_each_line}" ]; then
      [ "${weather_revamped_send_each_line}" != "${WEATHER_REVAMPED_EMPTY}" ] || weather_revamped_send_each_line=""
      set -- "$@" "${weather_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || weather_revamped_send_each_status=1
    set --
  done <<PLAN
${WEATHER_REVAMPED_PLAN}
PLAN
  return "${weather_revamped_send_each_status}"
}

weather_revamped_deliver() {
  ! weather_revamped_send || return 0
  weather_revamped_send_each
}

weather_revamped_lines() {
  printf '%s' "${WEATHER_REVAMPED_PLAN}" | awk -v empty="${WEATHER_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

weather_revamped_json() {
  printf '%s' "${WEATHER_REVAMPED_PLAN}" | awk -v empty="${WEATHER_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

weather_revamped_bindings() {
  printf '%s' "${WEATHER_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

weather_revamped_setting_name() {
  weather_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${WEATHER_REVAMPED_NAMES} " in
  *" ${weather_revamped_setting_name_raw} "*) printf '%s\n' "${weather_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

weather_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  weather_revamped_bind_key="$1" weather_revamped_bind_note="$2"
  shift 2
  set -- "${weather_revamped_bind_key}" "$@"
  [ "${WEATHER_REVAMPED_NOTES}" != 1 ] || set -- -N "${weather_revamped_bind_note}" "$@"
  weather_revamped_emit bind-key "$@"
}

weather_revamped_job_quote() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e 's/%/%%/g' -e "1s/^/'/" -e "\$s/\$/'/"
}

weather_revamped_carried() {
  weather_revamped_carried_set=$(env | sed -n 's/^WEATHER_REVAMPED_\([A-Z_]*\)=\(.*\)$/\1 \2/p')
  [ -n "${weather_revamped_carried_set}" ] || return 0
  printf '%s\n' "${weather_revamped_carried_set}" | WEATHER_REVAMPED_WANTED="${WEATHER_REVAMPED_CARRIED}" awk '
    BEGIN { count = split(ENVIRON["WEATHER_REVAMPED_WANTED"], name, " "); for (i = 1; i <= count; i++) { wanted[toupper(name[i])] = i } }
    {
      key = $1
      if (!(key in wanted)) { next }
      given[wanted[key]] = 1
      value[wanted[key]] = substr($0, length(key) + 2)
    }
    END {
      for (i = 1; i <= count; i++) {
        if (!given[i]) { continue }
        flag = name[i]
        gsub(/_/, "-", flag)
        print flag "\t" value[i]
      }
    }
  '
}

weather_revamped_tools() {
  weather_revamped_tools_path="${REVAMPED_LIB%/lib}/bin/weather-revamped"
  WEATHER_REVAMPED_TOOL=$(weather_revamped_literal "${weather_revamped_tools_path}")
  WEATHER_REVAMPED_JOB=$(weather_revamped_job_quote "${weather_revamped_tools_path}")
  weather_revamped_tools_rows=$(weather_revamped_carried)
  while IFS='	' read -r weather_revamped_tools_flag weather_revamped_tools_value; do
    [ -n "${weather_revamped_tools_flag}" ] || continue
    WEATHER_REVAMPED_TOOL="${WEATHER_REVAMPED_TOOL} --${weather_revamped_tools_flag} $(weather_revamped_literal "${weather_revamped_tools_value}")"
    WEATHER_REVAMPED_JOB="${WEATHER_REVAMPED_JOB} --${weather_revamped_tools_flag} $(weather_revamped_job_quote "${weather_revamped_tools_value}")"
  done <<EOF
${weather_revamped_tools_rows}
EOF
}

weather_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "weather-revamped") == 0) { printf "%s ", key }
    }
  '
}

weather_revamped_doubled() {
  weather_revamped_doubled_rest="$1" weather_revamped_doubled_hash='#' WEATHER_REVAMPED_DOUBLED=""
  while [ "${weather_revamped_doubled_rest}" != "${weather_revamped_doubled_rest#*"${weather_revamped_doubled_hash}"}" ]; do
    WEATHER_REVAMPED_DOUBLED="${WEATHER_REVAMPED_DOUBLED}${weather_revamped_doubled_rest%%"${weather_revamped_doubled_hash}"*}${weather_revamped_doubled_hash}${weather_revamped_doubled_hash}"
    weather_revamped_doubled_rest="${weather_revamped_doubled_rest#*"${weather_revamped_doubled_hash}"}"
  done
  WEATHER_REVAMPED_DOUBLED="${WEATHER_REVAMPED_DOUBLED}${weather_revamped_doubled_rest}"
}

weather_revamped_say() {
  weather_revamped_doubled "$1"
  tmux display-message "weather-revamped: ${WEATHER_REVAMPED_DOUBLED}" 2>/dev/null || :
}

weather_revamped_now() {
  WEATHER_REVAMPED_NOW=$(date +%s 2>/dev/null) || WEATHER_REVAMPED_NOW=0
}

weather_revamped_version() {
  weather_revamped_version_raw=$(tmux -V 2>/dev/null) || weather_revamped_version_raw=""
  WEATHER_REVAMPED_TMUX=$(weather_revamped_parse_version "${weather_revamped_version_raw}")
}

weather_revamped_number() {
  WEATHER_REVAMPED_NUMBER="$1"
  revamped_cache_is_number "$1" || WEATHER_REVAMPED_NUMBER="$2"
  while [ "${#WEATHER_REVAMPED_NUMBER}" -gt 1 ] && [ "${WEATHER_REVAMPED_NUMBER#0}" != "${WEATHER_REVAMPED_NUMBER}" ]; do
    WEATHER_REVAMPED_NUMBER="${WEATHER_REVAMPED_NUMBER#0}"
  done
}

weather_revamped_odd() {
  WEATHER_REVAMPED_ODD="${WEATHER_REVAMPED_ODD}${WEATHER_REVAMPED_ODD:+ }$1=$2"
}

weather_revamped_switch() {
  case "$2" in
  on | 1 | yes | true) WEATHER_REVAMPED_SWITCH=on ;;
  off | 0 | no | false) WEATHER_REVAMPED_SWITCH=off ;;
  *)
    weather_revamped_odd "$1" "$2"
    WEATHER_REVAMPED_SWITCH="$3"
    ;;
  esac
}

weather_revamped_whole() {
  case "$2" in
  *[!0-9]*) weather_revamped_odd "$1" "$2" ;;
  *) ;;
  esac
}

weather_revamped_settle() {
  WEATHER_REVAMPED_ODD=""
  case "${WEATHER_REVAMPED_S_units}" in
  m) : ;;
  u | f | F | fahrenheit | Fahrenheit | imperial) WEATHER_REVAMPED_S_units=u ;;
  *)
    weather_revamped_odd units "${WEATHER_REVAMPED_S_units}"
    WEATHER_REVAMPED_S_units=m
    ;;
  esac
  weather_revamped_switch hide_units "${WEATHER_REVAMPED_S_hide_units}" off
  WEATHER_REVAMPED_S_hide_units="${WEATHER_REVAMPED_SWITCH}"
  weather_revamped_switch alerts "${WEATHER_REVAMPED_S_alerts}" off
  WEATHER_REVAMPED_S_alerts="${WEATHER_REVAMPED_SWITCH}"
  weather_revamped_switch show_condition_icon "${WEATHER_REVAMPED_S_show_condition_icon}" on
  WEATHER_REVAMPED_S_show_condition_icon="${WEATHER_REVAMPED_SWITCH}"
  weather_revamped_switch fixed_width "${WEATHER_REVAMPED_S_fixed_width}" off
  WEATHER_REVAMPED_S_fixed_width="${WEATHER_REVAMPED_SWITCH}"
  case "${WEATHER_REVAMPED_S_render}" in
  jobs | options) : ;;
  *)
    weather_revamped_odd render "${WEATHER_REVAMPED_S_render}"
    WEATHER_REVAMPED_S_render="jobs"
    ;;
  esac
  case "${WEATHER_REVAMPED_S_notify}" in
  0 | 1) : ;;
  *)
    weather_revamped_odd notify "${WEATHER_REVAMPED_S_notify}"
    WEATHER_REVAMPED_S_notify=0
    ;;
  esac
  weather_revamped_whole fetch_minutes "${WEATHER_REVAMPED_S_fetch_minutes}"
  case "${WEATHER_REVAMPED_S_fetch_minutes}" in
  '' | *[!0]*) : ;;
  *) weather_revamped_odd fetch_minutes "${WEATHER_REVAMPED_S_fetch_minutes}" ;;
  esac
  weather_revamped_whole interval "${WEATHER_REVAMPED_S_interval}"
  weather_revamped_whole umbrella_threshold "${WEATHER_REVAMPED_S_umbrella_threshold}"
  weather_revamped_whole pressure_delta "${WEATHER_REVAMPED_S_pressure_delta}"
  weather_revamped_whole temp_width "${WEATHER_REVAMPED_S_temp_width}"
}

weather_revamped_suffix() {
  case "${WEATHER_REVAMPED_S_units}" in
  u) WEATHER_REVAMPED_SUFFIX=F ;;
  *) WEATHER_REVAMPED_SUFFIX=C ;;
  esac
}

weather_revamped_place() {
  WEATHER_REVAMPED_PLACE="$1" WEATHER_REVAMPED_SLUG="$1"
  case "$1" in
  '') WEATHER_REVAMPED_SLUG=auto ;;
  *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_]*) WEATHER_REVAMPED_SLUG=$(printf '%s' "$1" | LC_ALL=C tr -c 'A-Za-z0-9_' '_') ;;
  *) ;;
  esac
}

weather_revamped_places() {
  WEATHER_REVAMPED_PLACES="${WEATHER_REVAMPED_S_locations}"
  [ -n "${WEATHER_REVAMPED_PLACES}" ] || WEATHER_REVAMPED_PLACES="${WEATHER_REVAMPED_S_location}"
}

weather_revamped_choose() {
  if [ -n "$1" ]; then
    weather_revamped_place "$1"
    return 0
  fi
  weather_revamped_places
  weather_revamped_place "${WEATHER_REVAMPED_PLACES%%;*}"
}

weather_revamped_recall_split() {
  IFS= read -r WEATHER_REVAMPED_VALUE_TS || :
  IFS= read -r WEATHER_REVAMPED_LOCK || :
  IFS= read -r WEATHER_REVAMPED_LOCK_TS || :
  IFS= read -r WEATHER_REVAMPED_OK_TS || :
  IFS= read -r WEATHER_REVAMPED_PREVIOUS || :
  IFS= read -r WEATHER_REVAMPED_ALERT || :
  IFS= read -r WEATHER_REVAMPED_VALUE || :
  while IFS= read -r weather_revamped_recall_split_more; do
    WEATHER_REVAMPED_VALUE="${WEATHER_REVAMPED_VALUE},${weather_revamped_recall_split_more}"
  done
}

weather_revamped_recall() {
  weather_revamped_recall_key="@weather_revamped_value_${WEATHER_REVAMPED_SLUG}"
  weather_revamped_recall_format="#{${weather_revamped_recall_key}_ts}
#{${weather_revamped_recall_key}_lock}
#{${weather_revamped_recall_key}_lock_ts}
#{@weather_revamped_${WEATHER_REVAMPED_SLUG}_ok_ts}
#{@weather_revamped_${WEATHER_REVAMPED_SLUG}_pressure_prev}
#{@weather_revamped_alert_${WEATHER_REVAMPED_SLUG}}
#{${weather_revamped_recall_key}}"
  weather_revamped_recall_raw=$(tmux display-message -p "${weather_revamped_recall_format}" 2>/dev/null) || weather_revamped_recall_raw=""
  weather_revamped_recall_split <<EOF
${weather_revamped_recall_raw}
EOF
}

weather_revamped_parse() {
  printf '%s\n' "${WEATHER_REVAMPED_VALUE}" | LC_ALL=C awk -v unit="${WEATHER_REVAMPED_SUFFIX}" '
    function whole(text) {
      gsub(/[^0-9-]/, "", text)
      if (text ~ /^-?[0-9]+$/) { return text + 0 }
      return ""
    }
    {
      rest = $0
      while (match(rest, /"[A-Za-z_0-9]+"[ \t]*:[ \t]*"[^"]*"/)) {
        pair = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        key = pair
        sub(/^"/, "", key)
        sub(/".*/, "", key)
        text = pair
        sub(/^"[^"]*"[ \t]*:[ \t]*"/, "", text)
        sub(/"$/, "", text)
        seen[key]++
        if (seen[key] == 1) { first[key] = text }
        if (seen[key] == 2) { second[key] = text }
        if (key == ("DewPoint" unit) && dews < 8) {
          number = whole(text)
          if (number != "") { dew += number; dews++ }
        }
        if (key == "DewPointC" && metric < 8) {
          number = whole(text)
          if (number != "") { celsius += number; metric++ }
        }
        if (key == "chanceofrain" && rains < 8) {
          number = text
          gsub(/[^0-9]/, "", number)
          if (number ~ /^[0-9]+$/ && number + 0 > wet) { wet = number + 0 }
          rains++
        }
      }
    }
    END {
      print whole(first["temp_" unit])
      print whole(first["temp_C"])
      print whole(first["FeelsLike" unit])
      print whole(first["humidity"])
      print whole(first["pressure"])
      print first["precipMM"]
      print whole(first["uvIndex"])
      print whole(first[(unit == "F") ? "windspeedMiles" : "windspeedKmph"])
      print first["winddir16Point"]
      print first["value"]
      print first["moon_phase"]
      print first["sunrise"]
      print first["sunset"]
      print whole(first["maxtemp" unit])
      print whole(first["mintemp" unit])
      print whole(second["maxtemp" unit])
      print whole(second["mintemp" unit])
      if (dews > 0) { printf "%d\n", dew / dews } else { print "" }
      if (metric > 0) { printf "%d\n", celsius / metric } else { print "" }
      if (rains > 0) { print wet + 0 } else { print "" }
    }
  '
}

weather_revamped_read_split() {
  for weather_revamped_read_split_name in temp temp_c feels humidity pressure precip uv wind_speed wind_dir condition moon sunrise sunset today_high today_low tomorrow_high tomorrow_low dew dew_c rain; do
    IFS= read -r "WEATHER_REVAMPED_R_${weather_revamped_read_split_name}" || :
  done
}

weather_revamped_read() {
  weather_revamped_suffix
  weather_revamped_read_rows=""
  if [ -n "${WEATHER_REVAMPED_VALUE}" ]; then
    weather_revamped_read_rows=$(weather_revamped_parse) || weather_revamped_read_rows=""
  fi
  weather_revamped_read_split <<EOF
${weather_revamped_read_rows}
EOF
}

weather_revamped_degree() {
  [ -z "${WEATHER_REVAMPED_DEGREE}" ] || return 0
  WEATHER_REVAMPED_DEGREE=$(printf '%b' '\0302\0260')
}

weather_revamped_line() {
  WEATHER_REVAMPED_LINE=""
  [ -n "${WEATHER_REVAMPED_R_temp}" ] || return 0
  weather_revamped_degree
  weather_revamped_line_sign="+"
  case "${WEATHER_REVAMPED_R_temp}" in
  -*) weather_revamped_line_sign="" ;;
  *) ;;
  esac
  WEATHER_REVAMPED_LINE="${WEATHER_REVAMPED_R_condition:+${WEATHER_REVAMPED_R_condition} }${weather_revamped_line_sign}${WEATHER_REVAMPED_R_temp}${WEATHER_REVAMPED_DEGREE}${WEATHER_REVAMPED_SUFFIX}"
}

weather_revamped_band() {
  WEATHER_REVAMPED_BAND=""
  [ -n "${WEATHER_REVAMPED_R_temp_c}" ] || return 0
  if [ "${WEATHER_REVAMPED_R_temp_c}" -lt 0 ]; then
    WEATHER_REVAMPED_BAND=freezing
  elif [ "${WEATHER_REVAMPED_R_temp_c}" -le 9 ]; then
    WEATHER_REVAMPED_BAND=cold
  elif [ "${WEATHER_REVAMPED_R_temp_c}" -le 17 ]; then
    WEATHER_REVAMPED_BAND=cool
  elif [ "${WEATHER_REVAMPED_R_temp_c}" -le 23 ]; then
    WEATHER_REVAMPED_BAND=comfortable
  elif [ "${WEATHER_REVAMPED_R_temp_c}" -le 31 ]; then
    WEATHER_REVAMPED_BAND=hot
  else
    WEATHER_REVAMPED_BAND=very_hot
  fi
}

weather_revamped_sky() {
  WEATHER_REVAMPED_SKY=""
  [ -n "${WEATHER_REVAMPED_R_temp}" ] || return 0
  weather_revamped_sky_text=$(printf '%s\n' "${WEATHER_REVAMPED_R_condition}" | tr '[:upper:]' '[:lower:]')
  case "${weather_revamped_sky_text}" in
  *thunder* | *storm*) WEATHER_REVAMPED_SKY=storm ;;
  *snow* | *sleet* | *blizzard* | *ice*) WEATHER_REVAMPED_SKY=snow ;;
  *rain* | *drizzle* | *shower*) WEATHER_REVAMPED_SKY=rain ;;
  *fog* | *mist* | *haze*) WEATHER_REVAMPED_SKY=fog ;;
  *overcast* | *cloud*) WEATHER_REVAMPED_SKY=clouds ;;
  *) WEATHER_REVAMPED_SKY=clear ;;
  esac
}

weather_revamped_value_color() {
  weather_revamped_band
  case "${WEATHER_REVAMPED_BAND}" in
  freezing) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_freezing_color}" ;;
  cold) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_cold_color}" ;;
  cool) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_cool_color}" ;;
  comfortable) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_comfortable_color}" ;;
  hot) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_hot_color}" ;;
  very_hot) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_very_hot_color}" ;;
  *) WEATHER_REVAMPED_OUT="" ;;
  esac
}

weather_revamped_value_icon() {
  weather_revamped_band
  case "${WEATHER_REVAMPED_BAND}" in
  freezing) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_freezing_icon}" ;;
  cold) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_cold_icon}" ;;
  cool) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_cool_icon}" ;;
  comfortable) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_comfortable_icon}" ;;
  hot) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_hot_icon}" ;;
  very_hot) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_very_hot_icon}" ;;
  *) WEATHER_REVAMPED_OUT="" ;;
  esac
}

weather_revamped_glyph() {
  [ -z "$1" ] || return 0
  WEATHER_REVAMPED_OUT=$(printf '%b' "$2")
}

weather_revamped_value_condition_icon() {
  WEATHER_REVAMPED_OUT=""
  [ "${WEATHER_REVAMPED_S_show_condition_icon}" != off ] || return 0
  weather_revamped_sky
  case "${WEATHER_REVAMPED_SKY}" in
  storm)
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_storm_condition_icon}"
    weather_revamped_glyph "${WEATHER_REVAMPED_OUT}" '\0363\0260\0226\0223'
    ;;
  snow)
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_snow_condition_icon}"
    weather_revamped_glyph "${WEATHER_REVAMPED_OUT}" '\0363\0260\0226\0230'
    ;;
  rain)
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_rain_condition_icon}"
    weather_revamped_glyph "${WEATHER_REVAMPED_OUT}" '\0363\0260\0226\0227'
    ;;
  fog)
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_fog_condition_icon}"
    weather_revamped_glyph "${WEATHER_REVAMPED_OUT}" '\0363\0260\0226\0221'
    ;;
  clouds)
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_clouds_condition_icon}"
    weather_revamped_glyph "${WEATHER_REVAMPED_OUT}" '\0363\0260\0226\0220'
    ;;
  clear)
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_clear_condition_icon}"
    weather_revamped_glyph "${WEATHER_REVAMPED_OUT}" '\0363\0260\0226\0231'
    ;;
  *) WEATHER_REVAMPED_OUT="" ;;
  esac
}

weather_revamped_value_condition_tint() {
  weather_revamped_sky
  case "${WEATHER_REVAMPED_SKY}" in
  storm) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_storm_tint}" ;;
  snow) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_snow_tint}" ;;
  rain) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_rain_tint}" ;;
  fog) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_fog_tint}" ;;
  clouds) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_clouds_tint}" ;;
  clear) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_clear_tint}" ;;
  *) WEATHER_REVAMPED_OUT="" ;;
  esac
}

weather_revamped_value_uv_color() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_uv}" ] || return 0
  if [ "${WEATHER_REVAMPED_R_uv}" -le 2 ]; then
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_uv_low_color}"
  elif [ "${WEATHER_REVAMPED_R_uv}" -le 5 ]; then
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_uv_moderate_color}"
  elif [ "${WEATHER_REVAMPED_R_uv}" -le 7 ]; then
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_uv_high_color}"
  elif [ "${WEATHER_REVAMPED_R_uv}" -le 10 ]; then
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_uv_very_high_color}"
  else
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_uv_extreme_color}"
  fi
}

weather_revamped_value_dew_comfort() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_dew_c}" ] || return 0
  if [ "${WEATHER_REVAMPED_R_dew_c}" -lt 13 ]; then
    WEATHER_REVAMPED_OUT=dry
  elif [ "${WEATHER_REVAMPED_R_dew_c}" -le 15 ]; then
    WEATHER_REVAMPED_OUT=comfortable
  elif [ "${WEATHER_REVAMPED_R_dew_c}" -le 18 ]; then
    WEATHER_REVAMPED_OUT=humid
  else
    WEATHER_REVAMPED_OUT=oppressive
  fi
}

weather_revamped_value_umbrella() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_rain}" ] || return 0
  weather_revamped_number "${WEATHER_REVAMPED_S_umbrella_threshold}" "${WEATHER_REVAMPED_DEFAULT_UMBRELLA}"
  [ "${WEATHER_REVAMPED_R_rain}" -ge "${WEATHER_REVAMPED_NUMBER}" ] || return 0
  revamped_publish_replace '{chance}' "${WEATHER_REVAMPED_R_rain}" "${WEATHER_REVAMPED_S_umbrella_text}"
  WEATHER_REVAMPED_OUT="${revamped_publish_replace_out}"
}

weather_revamped_value_trend() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_pressure}" ] || return 0
  case "${WEATHER_REVAMPED_PREVIOUS}" in
  '' | *[!0-9-]*) return 0 ;;
  *) ;;
  esac
  weather_revamped_number "${WEATHER_REVAMPED_S_pressure_delta}" "${WEATHER_REVAMPED_DEFAULT_DELTA}"
  if [ "$((WEATHER_REVAMPED_R_pressure - WEATHER_REVAMPED_PREVIOUS))" -gt "${WEATHER_REVAMPED_NUMBER}" ]; then
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_pressure_rising}"
  elif [ "$((WEATHER_REVAMPED_PREVIOUS - WEATHER_REVAMPED_R_pressure))" -gt "${WEATHER_REVAMPED_NUMBER}" ]; then
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_pressure_falling}"
  else
    WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_pressure_steady}"
  fi
}

weather_revamped_value_stale() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_VALUE}" ] || return 0
  weather_revamped_value_stale_age="${WEATHER_REVAMPED_NEVER}"
  ! revamped_cache_is_number "${WEATHER_REVAMPED_OK_TS}" || weather_revamped_value_stale_age=$((WEATHER_REVAMPED_NOW - WEATHER_REVAMPED_OK_TS))
  [ "${weather_revamped_value_stale_age}" -gt "$((WEATHER_REVAMPED_LIMIT * WEATHER_REVAMPED_STALE_AFTER))" ] || return 0
  WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_stale_color}"
}

weather_revamped_value_temp() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_temp}" ] || return 0
  weather_revamped_degree
  WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_temp}${WEATHER_REVAMPED_DEGREE}"
  [ "${WEATHER_REVAMPED_S_hide_units}" = on ] || WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_OUT}${WEATHER_REVAMPED_SUFFIX}"
  weather_revamped_number "${WEATHER_REVAMPED_S_temp_width}" ""
  weather_revamped_value_temp_width="${WEATHER_REVAMPED_NUMBER}"
  if [ -z "${weather_revamped_value_temp_width}" ]; then
    weather_revamped_value_temp_width=0
    [ "${WEATHER_REVAMPED_S_fixed_width}" != on ] || weather_revamped_value_temp_width="${WEATHER_REVAMPED_TEMP_NATURAL}"
  fi
  revamped_publish_count "${WEATHER_REVAMPED_OUT}"
  [ "${revamped_publish_count_out}" -lt "${weather_revamped_value_temp_width}" ] || return 0
  weather_revamped_value_temp_gap=$(printf "%$((weather_revamped_value_temp_width - revamped_publish_count_out))s" '')
  WEATHER_REVAMPED_OUT="${weather_revamped_value_temp_gap}${WEATHER_REVAMPED_OUT}"
}

weather_revamped_value_wind() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_wind_speed}" ] || return 0
  weather_revamped_value_wind_unit="km/h"
  [ "${WEATHER_REVAMPED_SUFFIX}" != F ] || weather_revamped_value_wind_unit="mph"
  weather_revamped_doubled "${WEATHER_REVAMPED_R_wind_dir}"
  WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_wind_speed}${weather_revamped_value_wind_unit}${WEATHER_REVAMPED_DOUBLED:+ ${WEATHER_REVAMPED_DOUBLED}}"
}

weather_revamped_value_forecast() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_R_tomorrow_low}${WEATHER_REVAMPED_R_tomorrow_high}" ] || return 0
  WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_tomorrow_low}-${WEATHER_REVAMPED_R_tomorrow_high}"
}

weather_revamped_value_alert() {
  WEATHER_REVAMPED_OUT=""
  [ -n "${WEATHER_REVAMPED_ALERT}" ] || return 0
  weather_revamped_doubled "${WEATHER_REVAMPED_ALERT}"
  WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_S_alert_prefix}${WEATHER_REVAMPED_DOUBLED}"
}

weather_revamped_value_outside() {
  weather_revamped_doubled "$1"
  WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_DOUBLED}"
}

weather_revamped_value() {
  case "$1" in
  weather)
    weather_revamped_line
    weather_revamped_value_outside "${WEATHER_REVAMPED_LINE}"
    ;;
  temp) weather_revamped_value_temp ;;
  color) weather_revamped_value_color ;;
  icon) weather_revamped_value_icon ;;
  condition_icon) weather_revamped_value_condition_icon ;;
  condition_tint) weather_revamped_value_condition_tint ;;
  stale_color) weather_revamped_value_stale ;;
  feels_like) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_feels}" ;;
  wind) weather_revamped_value_wind ;;
  humidity) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_humidity}" ;;
  pressure) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_pressure}" ;;
  pressure_trend) weather_revamped_value_trend ;;
  precip) weather_revamped_value_outside "${WEATHER_REVAMPED_R_precip}" ;;
  rain_chance) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_rain}" ;;
  umbrella) weather_revamped_value_umbrella ;;
  uv) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_uv}" ;;
  uv_color) weather_revamped_value_uv_color ;;
  dew_point) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_dew}" ;;
  dew_comfort) weather_revamped_value_dew_comfort ;;
  moon) weather_revamped_value_outside "${WEATHER_REVAMPED_R_moon}" ;;
  sunrise) weather_revamped_value_outside "${WEATHER_REVAMPED_R_sunrise}" ;;
  sunset) weather_revamped_value_outside "${WEATHER_REVAMPED_R_sunset}" ;;
  forecast) weather_revamped_value_forecast ;;
  today_high) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_today_high}" ;;
  today_low) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_today_low}" ;;
  tomorrow_high) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_tomorrow_high}" ;;
  tomorrow_low) WEATHER_REVAMPED_OUT="${WEATHER_REVAMPED_R_tomorrow_low}" ;;
  *) weather_revamped_value_alert ;;
  esac
}

weather_revamped_show() {
  weather_revamped_value "$1"
  [ -z "${WEATHER_REVAMPED_OUT}" ] || printf '%s\n' "${WEATHER_REVAMPED_OUT}"
}

weather_revamped_address() {
  revamped_publish_replace ' ' '+' "${WEATHER_REVAMPED_PLACE}"
  weather_revamped_address_flag=m
  [ "${WEATHER_REVAMPED_S_units}" != u ] || weather_revamped_address_flag=u
  WEATHER_REVAMPED_ADDRESS="${WEATHER_REVAMPED_SERVICE}/${revamped_publish_replace_out}?format=j1&${weather_revamped_address_flag}"
}

weather_revamped_download() {
  curl -s --max-time "${WEATHER_REVAMPED_TIMEOUT}" "$1" 2>/dev/null | tr -d '\000'
}

weather_revamped_compact() {
  LC_ALL=C awk -v keep="${WEATHER_REVAMPED_KEPT}" '
    BEGIN {
      count = split(keep, list, " ")
      for (i = 1; i <= count; i++) { wanted[list[i]] = 1 }
    }
    {
      rest = $0
      while (match(rest, /"[A-Za-z_0-9]+"[ \t]*:[ \t]*"[^"]*"/)) {
        pair = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        key = pair
        sub(/^"/, "", key)
        sub(/".*/, "", key)
        if (key in wanted) {
          sub(/"[ \t]*:[ \t]*"/, "\":\"", pair)
          out = out (out == "" ? "" : ",") pair
        }
      }
    }
    END { print out }
  '
}

weather_revamped_first_line() {
  awk 'NF { print; exit }'
}

weather_revamped_fetch_keep() {
  weather_revamped_read
  if [ -n "${WEATHER_REVAMPED_R_pressure}" ]; then
    weather_revamped_emit set-option -gq "@weather_revamped_${WEATHER_REVAMPED_SLUG}_pressure_prev" "${WEATHER_REVAMPED_R_pressure}"
    WEATHER_REVAMPED_PREVIOUS="${WEATHER_REVAMPED_R_pressure}"
  fi
  weather_revamped_emit set-option -gq "@weather_revamped_value_${WEATHER_REVAMPED_SLUG}" "${WEATHER_REVAMPED_FETCHED}"
  weather_revamped_emit set-option -gq "@weather_revamped_${WEATHER_REVAMPED_SLUG}_ok_ts" "${WEATHER_REVAMPED_NOW}"
  WEATHER_REVAMPED_VALUE="${WEATHER_REVAMPED_FETCHED}" WEATHER_REVAMPED_OK_TS="${WEATHER_REVAMPED_NOW}"
}

weather_revamped_fetch_alert() {
  [ "${WEATHER_REVAMPED_S_alerts}" = on ] || return 0
  weather_revamped_fetch_alert_text=""
  if [ -n "${WEATHER_REVAMPED_S_alert_url}" ]; then
    revamped_publish_replace ' ' '+' "${WEATHER_REVAMPED_PLACE}"
    revamped_publish_replace '{loc}' "${revamped_publish_replace_out}" "${WEATHER_REVAMPED_S_alert_url}"
    weather_revamped_fetch_alert_text=$(weather_revamped_download "${revamped_publish_replace_out}" | weather_revamped_first_line) || weather_revamped_fetch_alert_text=""
  fi
  WEATHER_REVAMPED_PLAN=""
  weather_revamped_emit set-option -gq "@weather_revamped_alert_${WEATHER_REVAMPED_SLUG}" "${weather_revamped_fetch_alert_text}"
  weather_revamped_send || return 0
  if [ -n "${weather_revamped_fetch_alert_text}" ] && [ "${weather_revamped_fetch_alert_text}" != "${WEATHER_REVAMPED_ALERT}" ] && [ "${WEATHER_REVAMPED_S_notify}" = 1 ]; then
    revamped_notify_send "Weather alert" "${weather_revamped_fetch_alert_text}"
  fi
  WEATHER_REVAMPED_ALERT="${weather_revamped_fetch_alert_text}"
}

# shellcheck disable=SC2034
weather_revamped_fetch() {
  WEATHER_REVAMPED_PLAN=""
  weather_revamped_now
  weather_revamped_address
  weather_revamped_fetch_body=$(weather_revamped_download "${WEATHER_REVAMPED_ADDRESS}") || weather_revamped_fetch_body=""
  case "${weather_revamped_fetch_body}" in
  *"Unknown location"* | *ERROR* | *Sorry*) weather_revamped_fetch_body="" ;;
  *) ;;
  esac
  WEATHER_REVAMPED_FETCHED=$(printf '%s\n' "${weather_revamped_fetch_body}" | weather_revamped_compact) || WEATHER_REVAMPED_FETCHED=""
  [ -z "${WEATHER_REVAMPED_FETCHED}" ] || weather_revamped_fetch_keep
  weather_revamped_emit set-option -gq "@weather_revamped_value_${WEATHER_REVAMPED_SLUG}_ts" "${WEATHER_REVAMPED_NOW}"
  WEATHER_REVAMPED_VALUE_TS="${WEATHER_REVAMPED_NOW}"
  WEATHER_REVAMPED_STORED=1
  weather_revamped_send || WEATHER_REVAMPED_STORED=0
  weather_revamped_fetch_alert
}

weather_revamped_limit() {
  weather_revamped_number "${WEATHER_REVAMPED_S_fetch_minutes}" "${WEATHER_REVAMPED_DEFAULT_FETCH}"
  [ "${WEATHER_REVAMPED_NUMBER}" -gt 0 ] || WEATHER_REVAMPED_NUMBER="${WEATHER_REVAMPED_DEFAULT_FETCH}"
  WEATHER_REVAMPED_LIMIT=$((WEATHER_REVAMPED_NUMBER * 60))
}

weather_revamped_stale() {
  revamped_cache_is_number "${WEATHER_REVAMPED_VALUE_TS}" || return 0
  [ "$((WEATHER_REVAMPED_NOW - WEATHER_REVAMPED_VALUE_TS))" -gt "${WEATHER_REVAMPED_LIMIT}" ]
}

weather_revamped_locked() {
  [ "${WEATHER_REVAMPED_LOCK}" = 1 ] || return 1
  revamped_cache_is_number "${WEATHER_REVAMPED_LOCK_TS}" || return 1
  [ "$((WEATHER_REVAMPED_NOW - WEATHER_REVAMPED_LOCK_TS))" -lt "${REVAMPED_CACHE_MAX_RUN}" ]
}

weather_revamped_fresh() {
  weather_revamped_stale || return 0
  weather_revamped_fetch
}

weather_revamped_status() {
  weather_revamped_load
  weather_revamped_now
  weather_revamped_limit
  weather_revamped_choose "$2"
  weather_revamped_recall
  if weather_revamped_stale && ! weather_revamped_locked; then
    revamped_cache_refresh_if_stale "value_${WEATHER_REVAMPED_SLUG}" "${WEATHER_REVAMPED_LIMIT}" weather_revamped_fetch || :
  fi
  weather_revamped_read
  weather_revamped_show "$1"
}

weather_revamped_renew() {
  weather_revamped_renew_rest="${WEATHER_REVAMPED_PLACES}" weather_revamped_renew_count=0
  while [ "${weather_revamped_renew_count}" -lt "${WEATHER_REVAMPED_MAX_PLACES}" ]; do
    weather_revamped_place "${weather_revamped_renew_rest%%;*}"
    weather_revamped_recall
    weather_revamped_fresh
    case "${weather_revamped_renew_rest}" in
    *\;*) weather_revamped_renew_rest="${weather_revamped_renew_rest#*;}" ;;
    *) return 0 ;;
    esac
    weather_revamped_renew_count=$((weather_revamped_renew_count + 1))
  done
}

weather_revamped_publish() {
  weather_revamped_choose ""
  weather_revamped_recall
  weather_revamped_read
  weather_revamped_publish_rest="${WEATHER_REVAMPED_S_published}" weather_revamped_publish_alone=""
  while [ -n "${weather_revamped_publish_rest}" ]; do
    weather_revamped_publish_name="${weather_revamped_publish_rest%% *}"
    weather_revamped_publish_rest="${weather_revamped_publish_rest#"${weather_revamped_publish_name}"}"
    weather_revamped_publish_rest="${weather_revamped_publish_rest# }"
    [ -n "${weather_revamped_publish_name}" ] || continue
    weather_revamped_value "${weather_revamped_publish_name}"
    if [ "${weather_revamped_publish_name}" = alert ] && [ "${#WEATHER_REVAMPED_OUT}" -gt "${WEATHER_REVAMPED_ALERT_ALONE}" ]; then
      weather_revamped_publish_alone="${WEATHER_REVAMPED_OUT}"
      continue
    fi
    revamped_publish_add "@weather_revamped_out_${weather_revamped_publish_name}" "${WEATHER_REVAMPED_OUT}"
  done
  revamped_publish_commit || :
  [ -n "${weather_revamped_publish_alone}" ] || return 0
  revamped_publish_add @weather_revamped_out_alert "${weather_revamped_publish_alone}"
  revamped_publish_commit || :
}

weather_revamped_tick() {
  weather_revamped_load
  weather_revamped_now
  weather_revamped_limit
  weather_revamped_places
  weather_revamped_renew
  weather_revamped_publish
}

weather_revamped_daemon() {
  revamped_ticker_run weather_revamped weather_revamped_tick "$$" "${WEATHER_REVAMPED_DEFAULT_TICK}"
}

weather_revamped_popup() {
  weather_revamped_version
  if ! weather_revamped_version_ge "${WEATHER_REVAMPED_TMUX}" "${WEATHER_REVAMPED_POPUP_SINCE}"; then
    weather_revamped_say "the popup needs tmux ${WEATHER_REVAMPED_POPUP_SINCE} or later"
    return 0
  fi
  weather_revamped_tools
  weather_revamped_popup_card="${WEATHER_REVAMPED_TOOL} card"
  [ -z "$1" ] || weather_revamped_popup_card="${weather_revamped_popup_card} $(weather_revamped_literal "$1")"
  tmux display-popup -E -w "${WEATHER_REVAMPED_POPUP_WIDTH}" -h "${WEATHER_REVAMPED_POPUP_HEIGHT}" "${weather_revamped_popup_card}; printf '\\nPress Enter to close. '; read -r weather_revamped_wait" 2>/dev/null || :
}

weather_revamped_plan_keys() {
  case "${WEATHER_REVAMPED_S_popup_key}: ${WEATHER_REVAMPED_KEYS} " in
  "${WEATHER_REVAMPED_DEFAULT_POPUP_KEY}:"*" ${WEATHER_REVAMPED_DEFAULT_POPUP_KEY} "*) WEATHER_REVAMPED_SKIPPED="${WEATHER_REVAMPED_SKIPPED}${WEATHER_REVAMPED_SKIPPED:+ }${WEATHER_REVAMPED_DEFAULT_POPUP_KEY}" ;;
  *) weather_revamped_bind "${WEATHER_REVAMPED_S_popup_key}" "Weather forecast" run-shell "${WEATHER_REVAMPED_TOOL} popup" ;;
  esac
  weather_revamped_bind "${WEATHER_REVAMPED_S_refresh_key}" "Fetch the weather now" run-shell -b "${WEATHER_REVAMPED_TOOL} refresh >/dev/null 2>&1"
}

weather_revamped_replaced() {
  printf '%s\n' "$1" | WEATHER_REVAMPED_PUT="${WEATHER_REVAMPED_JOB}" awk -v mode="${WEATHER_REVAMPED_S_render}" -v kinds="${WEATHER_REVAMPED_TOKENS}" '
    BEGIN {
      command = ENVIRON["WEATHER_REVAMPED_PUT"]
      count = split(kinds, kind, " ")
    }
    {
      line = $0
      for (i = 1; i <= count; i++) {
        holder = (kind[i] == "weather") ? "#{weather}" : "#{weather_" kind[i] "}"
        target = (mode == "options") ? "#{E:@weather_revamped_out_" kind[i] "}" : "#(" command " status " kind[i] ")"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) target
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

weather_revamped_used() {
  printf '%s\n' "$1" | awk -v kinds="${WEATHER_REVAMPED_TOKENS}" '
    BEGIN { count = split(kinds, kind, " ") }
    { text = text $0 " " }
    END {
      out = ""
      for (i = 1; i <= count; i++) {
        holder = (kind[i] == "weather") ? "#{weather}" : "#{weather_" kind[i] "}"
        if (index(text, holder) > 0 || index(text, "@weather_revamped_out_" kind[i] "}") > 0 || index(text, " status " kind[i] ")") > 0) { out = out (out == "" ? "" : " ") kind[i] }
      }
      print out
    }
  '
}

weather_revamped_plan_status() {
  weather_revamped_plan_status_all=""
  for weather_revamped_plan_status_option in status-left status-right; do
    weather_revamped_plan_status_now=$(tmux show-option -gqv "${weather_revamped_plan_status_option}" 2>/dev/null) || weather_revamped_plan_status_now=""
    weather_revamped_plan_status_all="${weather_revamped_plan_status_all} ${weather_revamped_plan_status_now}"
    case "${weather_revamped_plan_status_now}" in
    *"#{weather"*"}"*) weather_revamped_plan_status_new=$(weather_revamped_replaced "${weather_revamped_plan_status_now}") ;;
    *) continue ;;
    esac
    [ "${weather_revamped_plan_status_new}" != "${weather_revamped_plan_status_now}" ] || continue
    weather_revamped_emit set-option -gq "${weather_revamped_plan_status_option}" "${weather_revamped_plan_status_new}"
  done
  weather_revamped_plan_status_used=$(weather_revamped_used "${weather_revamped_plan_status_all}")
  [ "${weather_revamped_plan_status_used}" = "${WEATHER_REVAMPED_S_published}" ] || weather_revamped_emit set-option -gq @weather_revamped_published "${weather_revamped_plan_status_used}"
  WEATHER_REVAMPED_S_published="${weather_revamped_plan_status_used}"
}

weather_revamped_plan() {
  weather_revamped_load
  weather_revamped_version
  WEATHER_REVAMPED_NOTES=0
  ! weather_revamped_version_ge "${WEATHER_REVAMPED_TMUX}" "${WEATHER_REVAMPED_NOTES_SINCE}" || WEATHER_REVAMPED_NOTES=1
  weather_revamped_tools
  WEATHER_REVAMPED_KEYS=$(weather_revamped_held)
  WEATHER_REVAMPED_PLAN="" WEATHER_REVAMPED_SKIPPED=""
  weather_revamped_plan_keys
  weather_revamped_plan_status
}

weather_revamped_apply() {
  weather_revamped_plan
  weather_revamped_apply_status=0
  weather_revamped_deliver || weather_revamped_apply_status=1
  if [ "${WEATHER_REVAMPED_S_render}" = options ]; then
    revamped_ticker_start "${REVAMPED_LIB%/lib}/bin/weather-revamped"
  else
    tmux set-option -gqu @weather_revamped_ticker_pid 2>/dev/null || :
  fi
  return "${weather_revamped_apply_status}"
}
