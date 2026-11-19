#!/bin/sh

weather_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${weather_revamped_dir}/bin/weather-revamped" apply
