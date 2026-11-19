Source common.tape
Output hero.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 3500ms
Screenshot weather.png
Sleep 4s
Hide
Ctrl+]
Type@5ms "prefix M-w, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "w"
Sleep 5s
Screenshot popup.png
Sleep 1s
Enter
Sleep 1500ms
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_units u"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_units u"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot fahrenheit.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @weather_revamped_units m"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_units m"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1500ms
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "touch /Users/Shared/demo/answers/turned"
Enter
Show
Sleep 800ms
Type "touch /Users/Shared/demo/answers/turned"
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
Type@5ms "prefix R"
Enter
Show
Ctrl+B
Type "R"
Sleep 4s
Screenshot refresh-key.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 300ms
Show
Hide
Ctrl+]
Type@5ms "tmux set -g status-right #{weather} #{weather_wind}"
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{weather} #{weather_wind} '"
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
Type@5ms "tmux set -g @weather_revamped_render options"
Enter
Show
Sleep 800ms
Type "tmux set -g @weather_revamped_render options"
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
Sleep 3s
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux show -gv status-right | cut -c1-90"
Enter
Show
Sleep 800ms
Type "tmux show -gv status-right | cut -c1-90"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3s
Screenshot options.png
Sleep 1s
Sleep 1500ms
