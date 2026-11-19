# shellcheck shell=bash
# shellcheck disable=SC2207

_weather_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  status)
    COMPREPLY=($(compgen -W "weather temp feels_like wind humidity pressure pressure_trend precip rain_chance umbrella uv uv_color dew_point dew_comfort moon sunrise sunset forecast today_high today_low tomorrow_high tomorrow_low condition_icon condition_tint color icon stale_color alert" -- "${cur}"))
    return
    ;;
  --units)
    COMPREPLY=($(compgen -W "m u" -- "${cur}"))
    return
    ;;
  --hide-units | --alerts | --show-condition-icon | --fixed-width)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --notify)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --render)
    COMPREPLY=($(compgen -W "jobs options" -- "${cur}"))
    return
    ;;
  --popup-key | --refresh-key | --location | --locations | --fetch-minutes | --alert-url | --alert-prefix | --umbrella-text | --umbrella-threshold | --stale-color | --pressure-delta | --pressure-rising | --pressure-falling | --pressure-steady | --uv-low-color | --uv-moderate-color | --uv-high-color | --uv-very-high-color | --uv-extreme-color | --freezing-color | --cold-color | --cool-color | --comfortable-color | --hot-color | --very-hot-color | --freezing-icon | --cold-icon | --cool-icon | --comfortable-icon | --hot-icon | --very-hot-icon | --clear-condition-icon | --clouds-condition-icon | --rain-condition-icon | --snow-condition-icon | --storm-condition-icon | --fog-condition-icon | --clear-tint | --clouds-tint | --rain-tint | --snow-tint | --storm-tint | --fog-tint | --interval | --temp-width)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list status refresh card popup daemon doctor version help --json --theme --popup-key --refresh-key --location --locations --units --fetch-minutes --hide-units --alerts --alert-url --alert-prefix --notify --umbrella-text --umbrella-threshold --stale-color --pressure-delta --pressure-rising --pressure-falling --pressure-steady --uv-low-color --uv-moderate-color --uv-high-color --uv-very-high-color --uv-extreme-color --freezing-color --cold-color --cool-color --comfortable-color --hot-color --very-hot-color --freezing-icon --cold-icon --cool-icon --comfortable-icon --hot-icon --very-hot-icon --show-condition-icon --clear-condition-icon --clouds-condition-icon --rain-condition-icon --snow-condition-icon --storm-condition-icon --fog-condition-icon --clear-tint --clouds-tint --rain-tint --snow-tint --storm-tint --fog-tint --render --interval --fixed-width --temp-width" -- "${cur}"))
}

complete -F _weather_revamped weather-revamped
