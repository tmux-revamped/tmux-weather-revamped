export PS1='$ '
export PATH="/Users/Shared/demo/bin:/Users/Shared/demo/tmux-weather-revamped/bin:${PATH}"
unset KODOUGU_THEME KODOUGU_ACCENT WEATHER_REVAMPED_THEME WEATHER_REVAMPED_ACCENT NO_COLOR
export HOME=/Users/Shared/demo/home
cd /Users/Shared/demo || return 1
printf '\033]2;demo\033\134'
clear
