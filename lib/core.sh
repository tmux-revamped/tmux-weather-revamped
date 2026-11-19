#!/bin/sh
# shellcheck disable=SC2034

[ -n "${WEATHER_REVAMPED_CORE_LOADED:-}" ] && return 0
WEATHER_REVAMPED_CORE_LOADED=1

readonly WEATHER_REVAMPED_VERSION="3.0.0"
