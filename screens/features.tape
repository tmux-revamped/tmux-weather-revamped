Source common.tape
Output scratch.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 800ms
Hide
Ctrl+]
Type@5ms "weather-revamped refresh"
Enter
Show
Sleep 800ms
Type "weather-revamped refresh"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2s
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g status-right #{weather_temp} feels #{weather_feels_like} #{weather_wind} #{weather_humidity} #{weather_pressure}hPa #{weather_pressure_trend} #{weather_precip}mm"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{weather_temp} feels #{weather_feels_like} #{weather_wind} #{weather_humidity} #{weather_pressure}hPa #{weather_pressure_trend} #{weather_precip}mm '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 800ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "weather-revamped apply"
Enter
Show
Sleep 800ms
Type "weather-revamped apply"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot details.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_umbrella_text umbrella, {chance} in 100"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_umbrella_text 'umbrella, {chance} in 100'"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g status-right #{weather_forecast} today #{weather_today_low}-#{weather_today_high} tomorrow #{weather_tomorrow_low}-#{weather_tomorrow_high} rain #{weather_rain_chance} #{weather_umbrella}"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{weather_forecast} today #{weather_today_low}-#{weather_today_high} tomorrow #{weather_tomorrow_low}-#{weather_tomorrow_high} rain #{weather_rain_chance} #{weather_umbrella} '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 800ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "weather-revamped apply"
Enter
Show
Sleep 800ms
Type "weather-revamped apply"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot forecast.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g status-right UV #{weather_uv_color}#{weather_uv}#[default] dew #{weather_dew_point} #{weather_dew_comfort} #{weather_moon} #{weather_sunrise} #{weather_sunset}"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right 'UV #{weather_uv_color}#{weather_uv}#[default] dew #{weather_dew_point} #{weather_dew_comfort} #{weather_moon} #{weather_sunrise} #{weather_sunset} '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 800ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "weather-revamped apply"
Enter
Show
Sleep 800ms
Type "weather-revamped apply"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot sky.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_alerts on"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_alerts 'on'"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_alert_prefix ! "
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_alert_prefix '! '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_alert_url https://github.com/tmux-revamped/tmux-weather-revamped/{loc}"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_alert_url 'https://github.com/tmux-revamped/tmux-weather-revamped/{loc}'"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "weather-revamped refresh"
Enter
Show
Sleep 800ms
Type "weather-revamped refresh"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2s
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g status-right #{weather_alert} #{weather_stale_color}#{weather}#[default]"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{weather_alert} #{weather_stale_color}#{weather}#[default] '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 800ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "weather-revamped apply"
Enter
Show
Sleep 800ms
Type "weather-revamped apply"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot alert.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_hide_units on"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_hide_units 'on'"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_fixed_width on"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_fixed_width 'on'"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_comfortable_icon mild "
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_comfortable_icon 'mild '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 600ms
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g status-right #{weather_condition_tint}#{weather_condition_icon}#[default] #{weather_color}#{weather_icon}#{weather_temp}#[default]"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{weather_condition_tint}#{weather_condition_icon}#[default] #{weather_color}#{weather_icon}#{weather_temp}#[default] '"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 800ms
Sleep 1s
Hide
Ctrl+]
Type@5ms "weather-revamped apply"
Enter
Show
Sleep 800ms
Type "weather-revamped apply"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot temp.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
