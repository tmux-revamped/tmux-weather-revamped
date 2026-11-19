#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin" "${demo}/answers" "${demo}/tmux-weather-revamped"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/weather-revamped.tmux" "${demo}/tmux-weather-revamped/"
tmux_path=$(command -v tmux)
ln -sfn "${tmux_path}" "${demo}/bin/tmux"

cp -f "${SCREENS_REPO}/test/fixtures/wttr-london.j1.json" "${demo}/answers/lisbon.json"
sed -e 's/"value": "Partly cloudy"/"value": "Light snow"/' -e 's/"temp_C": "18"/"temp_C": "-4"/' -e 's/"temp_F": "64"/"temp_F": "25"/' "${demo}/answers/lisbon.json" >"${demo}/answers/oslo.json"
sed -e 's/"value": "Partly cloudy"/"value": "Sunny"/' -e 's/"temp_C": "18"/"temp_C": "26"/' -e 's/"temp_F": "64"/"temp_F": "79"/' "${demo}/answers/lisbon.json" >"${demo}/answers/later.json"

cat >"${demo}/bin/curl" <<'FETCH'
#!/bin/sh
folder=/Users/Shared/demo/answers
case "$*" in
*--version*) printf 'curl 8.7.1 (stand-in)\n' ;;
*github.com*) printf 'Wind advisory until 18:00\n' ;;
*Oslo*) cat "${folder}/oslo.json" ;;
*)
  if [ -f "${folder}/turned" ]; then
    cat "${folder}/later.json"
  else
    cat "${folder}/lisbon.json"
  fi
  ;;
esac
FETCH
chmod +x "${demo}/bin/curl"
