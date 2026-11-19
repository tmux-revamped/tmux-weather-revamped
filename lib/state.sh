#!/bin/sh
# shellcheck disable=SC2034

[ -n "${WEATHER_REVAMPED_STATE_LOADED:-}" ] && return 0
WEATHER_REVAMPED_STATE_LOADED=1

WEATHER_REVAMPED_SETTINGS='popup_key	M-w
refresh_key
location
locations
units	m
fetch_minutes	15
hide_units	off
alerts	off
alert_url
alert_prefix
notify	0
umbrella_text
umbrella_threshold	50
stale_color	#[dim]
pressure_delta	1
pressure_rising	^
pressure_falling	v
pressure_steady	=
uv_low_color	#[fg=green]
uv_moderate_color	#[fg=yellow]
uv_high_color	#[fg=colour208]
uv_very_high_color	#[fg=red]
uv_extreme_color	#[fg=magenta]
freezing_color	#[fg=blue]
cold_color	#[fg=cyan]
cool_color	#[fg=green]
comfortable_color	#[fg=green]
hot_color	#[fg=yellow]
very_hot_color	#[fg=red]
freezing_icon
cold_icon
cool_icon
comfortable_icon
hot_icon
very_hot_icon
show_condition_icon	on
clear_condition_icon
clouds_condition_icon
rain_condition_icon
snow_condition_icon
storm_condition_icon
fog_condition_icon
clear_tint	#[fg=yellow]
clouds_tint	#[fg=brightblack]
rain_tint	#[fg=blue]
snow_tint	#[fg=white]
storm_tint	#[fg=magenta]
fog_tint	#[fg=brightblack]
render	jobs
interval	60
fixed_width	off
temp_width'
WEATHER_REVAMPED_NAMES='popup_key refresh_key location locations units fetch_minutes hide_units alerts alert_url alert_prefix notify umbrella_text umbrella_threshold stale_color pressure_delta pressure_rising pressure_falling pressure_steady uv_low_color uv_moderate_color uv_high_color uv_very_high_color uv_extreme_color freezing_color cold_color cool_color comfortable_color hot_color very_hot_color freezing_icon cold_icon cool_icon comfortable_icon hot_icon very_hot_icon show_condition_icon clear_condition_icon clouds_condition_icon rain_condition_icon snow_condition_icon storm_condition_icon fog_condition_icon clear_tint clouds_tint rain_tint snow_tint storm_tint fog_tint render interval fixed_width temp_width'
WEATHER_REVAMPED_CARRIED='location locations units fetch_minutes hide_units alerts alert_url alert_prefix notify umbrella_text umbrella_threshold stale_color pressure_delta pressure_rising pressure_falling pressure_steady uv_low_color uv_moderate_color uv_high_color uv_very_high_color uv_extreme_color freezing_color cold_color cool_color comfortable_color hot_color very_hot_color freezing_icon cold_icon cool_icon comfortable_icon hot_icon very_hot_icon show_condition_icon clear_condition_icon clouds_condition_icon rain_condition_icon snow_condition_icon storm_condition_icon fog_condition_icon clear_tint clouds_tint rain_tint snow_tint storm_tint fog_tint render interval fixed_width temp_width'
WEATHER_REVAMPED_LIVE='published'
WEATHER_REVAMPED_S_popup_key='M-w'
WEATHER_REVAMPED_S_refresh_key=''
WEATHER_REVAMPED_S_location=''
WEATHER_REVAMPED_S_locations=''
WEATHER_REVAMPED_S_units='m'
WEATHER_REVAMPED_S_fetch_minutes='15'
WEATHER_REVAMPED_S_hide_units='off'
WEATHER_REVAMPED_S_alerts='off'
WEATHER_REVAMPED_S_alert_url=''
WEATHER_REVAMPED_S_alert_prefix=''
WEATHER_REVAMPED_S_notify='0'
WEATHER_REVAMPED_S_umbrella_text=''
WEATHER_REVAMPED_S_umbrella_threshold='50'
WEATHER_REVAMPED_S_stale_color='#[dim]'
WEATHER_REVAMPED_S_pressure_delta='1'
WEATHER_REVAMPED_S_pressure_rising='^'
WEATHER_REVAMPED_S_pressure_falling='v'
WEATHER_REVAMPED_S_pressure_steady='='
WEATHER_REVAMPED_S_uv_low_color='#[fg=green]'
WEATHER_REVAMPED_S_uv_moderate_color='#[fg=yellow]'
WEATHER_REVAMPED_S_uv_high_color='#[fg=colour208]'
WEATHER_REVAMPED_S_uv_very_high_color='#[fg=red]'
WEATHER_REVAMPED_S_uv_extreme_color='#[fg=magenta]'
WEATHER_REVAMPED_S_freezing_color='#[fg=blue]'
WEATHER_REVAMPED_S_cold_color='#[fg=cyan]'
WEATHER_REVAMPED_S_cool_color='#[fg=green]'
WEATHER_REVAMPED_S_comfortable_color='#[fg=green]'
WEATHER_REVAMPED_S_hot_color='#[fg=yellow]'
WEATHER_REVAMPED_S_very_hot_color='#[fg=red]'
WEATHER_REVAMPED_S_freezing_icon=''
WEATHER_REVAMPED_S_cold_icon=''
WEATHER_REVAMPED_S_cool_icon=''
WEATHER_REVAMPED_S_comfortable_icon=''
WEATHER_REVAMPED_S_hot_icon=''
WEATHER_REVAMPED_S_very_hot_icon=''
WEATHER_REVAMPED_S_show_condition_icon='on'
WEATHER_REVAMPED_S_clear_condition_icon=''
WEATHER_REVAMPED_S_clouds_condition_icon=''
WEATHER_REVAMPED_S_rain_condition_icon=''
WEATHER_REVAMPED_S_snow_condition_icon=''
WEATHER_REVAMPED_S_storm_condition_icon=''
WEATHER_REVAMPED_S_fog_condition_icon=''
WEATHER_REVAMPED_S_clear_tint='#[fg=yellow]'
WEATHER_REVAMPED_S_clouds_tint='#[fg=brightblack]'
WEATHER_REVAMPED_S_rain_tint='#[fg=blue]'
WEATHER_REVAMPED_S_snow_tint='#[fg=white]'
WEATHER_REVAMPED_S_storm_tint='#[fg=magenta]'
WEATHER_REVAMPED_S_fog_tint='#[fg=brightblack]'
WEATHER_REVAMPED_S_render='jobs'
WEATHER_REVAMPED_S_interval='60'
WEATHER_REVAMPED_S_fixed_width='off'
WEATHER_REVAMPED_S_temp_width=''
WEATHER_REVAMPED_S_published=''
WEATHER_REVAMPED_R_temp=''
WEATHER_REVAMPED_R_temp_c=''
WEATHER_REVAMPED_R_feels=''
WEATHER_REVAMPED_R_humidity=''
WEATHER_REVAMPED_R_pressure=''
WEATHER_REVAMPED_R_precip=''
WEATHER_REVAMPED_R_uv=''
WEATHER_REVAMPED_R_wind_speed=''
WEATHER_REVAMPED_R_wind_dir=''
WEATHER_REVAMPED_R_condition=''
WEATHER_REVAMPED_R_moon=''
WEATHER_REVAMPED_R_sunrise=''
WEATHER_REVAMPED_R_sunset=''
WEATHER_REVAMPED_R_today_high=''
WEATHER_REVAMPED_R_today_low=''
WEATHER_REVAMPED_R_tomorrow_high=''
WEATHER_REVAMPED_R_tomorrow_low=''
WEATHER_REVAMPED_R_dew=''
WEATHER_REVAMPED_R_dew_c=''
WEATHER_REVAMPED_R_rain=''
WEATHER_REVAMPED_TOKENS='feels_like wind humidity pressure_trend pressure precip rain_chance umbrella uv_color uv dew_point dew_comfort moon sunrise sunset forecast today_high today_low tomorrow_high tomorrow_low condition_icon condition_tint stale_color alert color icon temp weather'
WEATHER_REVAMPED_KEPT='temp_C temp_F FeelsLikeC FeelsLikeF humidity pressure precipMM uvIndex windspeedKmph windspeedMiles winddir16Point value moon_phase sunrise sunset maxtempC maxtempF mintempC mintempF DewPointC DewPointF chanceofrain'
WEATHER_REVAMPED_DEFAULT_POPUP_KEY='M-w'
WEATHER_REVAMPED_DEFAULT_FETCH=15
WEATHER_REVAMPED_DEFAULT_TICK=60
WEATHER_REVAMPED_DEFAULT_UMBRELLA=50
WEATHER_REVAMPED_DEFAULT_DELTA=1
WEATHER_REVAMPED_STALE_AFTER=3
WEATHER_REVAMPED_TEMP_NATURAL=5
WEATHER_REVAMPED_TIMEOUT=10
WEATHER_REVAMPED_SERVICE='https://wttr.in'
WEATHER_REVAMPED_NEVER=999999999
WEATHER_REVAMPED_POPUP_WIDTH='70%'
WEATHER_REVAMPED_POPUP_HEIGHT='80%'
WEATHER_REVAMPED_POPUP_SINCE=3.2
WEATHER_REVAMPED_NOTES_SINCE=3.1
WEATHER_REVAMPED_EMPTY='weather-revamped-empty-argument'
WEATHER_REVAMPED_TMUX=''
WEATHER_REVAMPED_NOTES=0
WEATHER_REVAMPED_TOOL=''
WEATHER_REVAMPED_JOB=''
WEATHER_REVAMPED_KEYS=''
WEATHER_REVAMPED_SKIPPED=''
WEATHER_REVAMPED_PLAN=''
WEATHER_REVAMPED_NOW=0
WEATHER_REVAMPED_LIMIT=900
WEATHER_REVAMPED_NUMBER=0
WEATHER_REVAMPED_DOUBLED=''
WEATHER_REVAMPED_PLACE=''
WEATHER_REVAMPED_PLACES=''
WEATHER_REVAMPED_MAX_PLACES=16
WEATHER_REVAMPED_ALERT_ALONE=1000
WEATHER_REVAMPED_ADDRESS=''
WEATHER_REVAMPED_DEGREE=''
WEATHER_REVAMPED_SLUG=''
WEATHER_REVAMPED_SUFFIX='C'
WEATHER_REVAMPED_VALUE=''
WEATHER_REVAMPED_VALUE_TS=''
WEATHER_REVAMPED_LOCK=''
WEATHER_REVAMPED_LOCK_TS=''
WEATHER_REVAMPED_OK_TS=''
WEATHER_REVAMPED_PREVIOUS=''
WEATHER_REVAMPED_ALERT=''
WEATHER_REVAMPED_FETCHED=''
WEATHER_REVAMPED_STORED=0
WEATHER_REVAMPED_BAND=''
WEATHER_REVAMPED_SKY=''
WEATHER_REVAMPED_LINE=''
WEATHER_REVAMPED_OUT=''
WEATHER_REVAMPED_CARD=''
WEATHER_REVAMPED_LABEL=''
WEATHER_REVAMPED_ODD=''
WEATHER_REVAMPED_SWITCH=''
WEATHER_REVAMPED_SINCE=''
REVAMPED_CACHE_PREFIX=weather_revamped
REVAMPED_CACHE_MAX_RUN=30
REVAMPED_LOG_NS=weather-revamped
