<div align="center">

# tmux-weather-revamped

<strong>在 tmux 狀態列顯示來自 wttr.in 的天氣，在背景取得，狀態列從不等待。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-weather-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-weather-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-weather-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-weather-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-weather-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-weather-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-weather-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="weather-revamped 在狀態列顯示天氣、開啟預報彈出視窗、切換至華氏度、按重新整理鍵取得並切換至 options 繪製模式" width="800">
</p>

```console
$ weather-revamped refresh
Refreshed. wttr.in says Partly cloudy +18°C for Lisbon.
$ weather-revamped status weather
Partly cloudy +18°C
```

每個地點 **1** 次請求提供 **28** 個佔位符，**2** 種繪製模式，支援 macOS 和 Linux，需要 tmux **3.2** 或以上版本。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或以上 | 家族的最低版本，彈出視窗亦需要它 |
| curl | 任何版本 | 每次取得，限時 10 秒 |
| gum | 可選 | `weather-revamped` 的選單、表格及顏色；沒有它，所有命令都輸出純文字 |

需要能夠連線至 [wttr.in](https://wttr.in)，可在 Linux 和 macOS 上執行，支援 BSD、GNU 和 uutils coreutils。

### 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，將插件和一個佔位符加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-weather-revamped'
set -g status-right '#{weather} '
```

手動安裝時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-weather-revamped ~/.tmux/plugins/tmux-weather-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-weather-revamped/weather-revamped.tmux
```

請在插件載入之前設定 `status-left` 或 `status-right`。插件只在載入時替換一次其中的佔位符。[`examples/status-right.tmux.conf`](examples/status-right.tmux.conf) 內有一行可以直接複製。

在複製的目錄中執行 `make install`，亦會把 `weather-revamped` 放入 `~/.local/bin`，並把它的 man 手冊和自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-weather-revamped/bin/weather-revamped doctor
```

## 用法

設定一個地點，或者留空，讓 wttr.in 按 IP 定位。所有佔位符都來自同一份已儲存的回應，所以顯示更多內容不會增加請求。冷啟動後第一次繪製為空，等待第一次取得完成；取得失敗時，畫面上保留上一次的讀數。

```tmux
set -g @weather_revamped_location 'Lisbon'
set -g status-right '#{weather_color}#{weather_condition_icon} #{weather_temp}#[default] #{weather_wind} '
```

| 佔位符 | 輸出 |
|:------------|:-------|
| `#{weather}` | 天氣狀況和溫度，例如 `Partly cloudy +18°C` |
| `#{weather_temp}` | 不帶加號的溫度，例如 `18°C` |
| `#{weather_feels_like}` | 體感溫度，例如 `16` |
| `#{weather_wind}` | 風速和風向，例如 `11km/h NW` |
| `#{weather_humidity}` | 相對濕度，百分比 |
| `#{weather_pressure}` | 氣壓，單位 hPa |
| `#{weather_pressure_trend}` | 與上一次取得相比的 `^`、`v` 或 `=` |
| `#{weather_precip}` | 降水量，單位毫米 |
| `#{weather_rain_chance}` | 今天首八個預報時段中最高的降雨機會 |
| `#{weather_umbrella}` | 降雨機會達到門檻後顯示的雨傘文字 |
| `#{weather_uv}` | 紫外線指數 |
| `#{weather_uv_color}` | 對應紫外線級別的 tmux 樣式 |
| `#{weather_dew_point}` | 今天首八個預報時段的平均露點 |
| `#{weather_dew_comfort}` | `dry`、`comfortable`、`humid` 或 `oppressive` |
| `#{weather_moon}` | 月相，例如 `Waning Gibbous` |
| `#{weather_sunrise}` | 日出，例如 `06:00 AM` |
| `#{weather_sunset}` | 日落，例如 `06:45 PM` |
| `#{weather_forecast}` | 明天的最低和最高溫度，例如 `15-27` |
| `#{weather_today_high}` | 今天的最高溫度 |
| `#{weather_today_low}` | 今天的最低溫度 |
| `#{weather_tomorrow_high}` | 明天的最高溫度 |
| `#{weather_tomorrow_low}` | 明天的最低溫度 |
| `#{weather_condition_icon}` | 表示天空狀況的 Nerd Font 字形 |
| `#{weather_condition_tint}` | 對應天空狀況的 tmux 樣式 |
| `#{weather_color}` | 對應溫度區間的 tmux 樣式，例如 `#[fg=green]` |
| `#{weather_icon}` | 你為溫度區間設定的圖示，未設定時為空 |
| `#{weather_stale_color}` | 最後一次回應超過三個取得間隔後為 `#[dim]` |
| `#{weather_alert}` | 來自你自行指定地址的警報行，未開啟警報時為空 |

### 多個地點

`@weather_revamped_locations` 接受以 `;` 分隔的多個地點。第一個地點用於佔位符。其他地點可以在狀態列或腳本中手動讀取，每個地點儲存自己的讀數：

```tmux
set -g @weather_revamped_locations 'Lisbon;Oslo'
```

```bash
weather-revamped status weather Oslo
weather-revamped card Oslo
```

### 警報

wttr.in 不提供警報，所以警報行來自你自行指定的地址。將 `@weather_revamped_alerts` 設為 `on` 後，`@weather_revamped_alert_url` 傳回的第一行非空內容就是 `#{weather_alert}`；將 `@weather_revamped_notify` 設為 `1`，新的警報亦會發出桌面通知。

### 繪製模式

在預設的 `jobs` 模式下，每個佔位符是一個狀態工作，即時輸出已儲存的讀數。將 `@weather_revamped_render` 設為 `options` 後，由一個背景程序負責取得，並在每個週期將所有佔位符寫入 tmux 選項，狀態列更新時不再啟動任何程序。

### 命令

| 命令 | 作用 |
|:--------|:-------------|
| `weather-revamped status NAME [PLACE]` | 輸出一個佔位符，名稱不帶 `weather_`；第一個是 `weather` |
| `weather-revamped refresh [PLACE]` | 即時取得，並說明 wttr.in 的回應 |
| `weather-revamped card [PLACE]` | 以表格輸出全部讀數 |
| `weather-revamped popup [PLACE]` | 在 tmux 彈出視窗中開啟這張表 |
| `weather-revamped list` | 輸出 `apply` 將傳送給 tmux 的內容；`--json` 把它輸出為一個物件 |
| `weather-revamped apply` | 綁定按鍵並替換佔位符，與入口腳本相同 |
| `weather-revamped doctor` | 檢查這部機器 |

每個 tmux 選項亦可寫成命令選項，例如 `--units u`，或環境變數，例如 `WEATHER_REVAMPED_UNITS`；命令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示使用預設值。on 和 off 的選項亦把 `1`、`yes` 和 `true` 讀作 on，把 `0`、`no` 和 `false` 讀作 off；tmux 選項是其他值時使用預設值，`doctor` 會指出是哪一個選項。

## 設定

### 讀數

| 選項 | 預設值 | 作用 |
|:-------|:--------|:-------------|
| `@weather_revamped_location` | 無 | 城市或地點。留空時由 wttr.in 按 IP 定位 |
| `@weather_revamped_locations` | 無 | 以 `;` 分隔的地點。第一個用於佔位符，並優先於單一地點的設定 |
| `@weather_revamped_units` | `m` | `m` 表示攝氏度和 km/h，`u` 表示華氏度和 mph；`f`、`fahrenheit` 和 `imperial` 按 `u` 處理 |
| `@weather_revamped_fetch_minutes` | `15` | 讀數在下一次取得之前保持有效的分鐘數，最少為 1 |
| `@weather_revamped_alerts` | `off` | `on` 表示每次取得讀數後再取得警報地址 |
| `@weather_revamped_alert_url` | 無 | 警報地址，其中的 `{loc}` 會替換為地點。第一行非空內容就是警報 |
| `@weather_revamped_alert_prefix` | 無 | `#{weather_alert}` 之前的文字 |
| `@weather_revamped_notify` | `0` | `1` 表示有新警報時發出桌面通知 |

### 顯示

| 選項 | 預設值 | 作用 |
|:-------|:--------|:-------------|
| `@weather_revamped_hide_units` | `off` | `on` 表示移除 `#{weather_temp}` 中的 `C` 或 `F` |
| `@weather_revamped_fixed_width` | `off` | `on` 表示把溫度補齊至五個字元 |
| `@weather_revamped_temp_width` | 無 | 溫度的闊度，優先於固定闊度 |
| `@weather_revamped_show_condition_icon` | `on` | `off` 表示清空 `#{weather_condition_icon}` |
| `@weather_revamped_<sky>_condition_icon` | 一個 Nerd Font 字形 | 某種天空狀況的圖示：`clear`、`clouds`、`rain`、`snow`、`storm` 或 `fog` |
| `@weather_revamped_<sky>_tint` | yellow, brightblack, blue, white, magenta, brightblack | 某種天空狀況的樣式，次序同上 |
| `@weather_revamped_<band>_color` | blue, cyan, green, green, yellow, red | 某個溫度區間的樣式，按攝氏度：`freezing` 低於 0，`cold` 至 9，`cool` 至 17，`comfortable` 至 23，`hot` 至 31，`very_hot` 更高 |
| `@weather_revamped_<band>_icon` | 無 | 某個溫度區間的圖示 |
| `@weather_revamped_uv_<level>_color` | green, yellow, colour208, red, magenta | 某個紫外線級別的樣式：`low` 至 2，`moderate` 至 5，`high` 至 7，`very_high` 至 10，`extreme` 更高 |
| `@weather_revamped_stale_color` | `#[dim]` | 讀數過期時的樣式 |
| `@weather_revamped_umbrella_text` | 無 | `#{weather_umbrella}` 的文字，其中的 `{chance}` 會替換為降雨機會 |
| `@weather_revamped_umbrella_threshold` | `50` | 顯示雨傘文字的降雨機會下限，百分比 |
| `@weather_revamped_pressure_delta` | `1` | 氣壓變化超過多少 hPa 才算上升或下降 |
| `@weather_revamped_pressure_rising` | `^` | 上升標記 |
| `@weather_revamped_pressure_falling` | `v` | 下降標記 |
| `@weather_revamped_pressure_steady` | `=` | 持平標記 |

### 繪製

| 選項 | 預設值 | 作用 |
|:-------|:--------|:-------------|
| `@weather_revamped_render` | `jobs` | `options` 表示每個佔位符讀取由背景程序寫入的 tmux 選項 |
| `@weather_revamped_interval` | `60` | 該程序兩個週期之間的秒數 |

### 內部狀態

插件把狀態儲存在 tmux 選項內，不使用暫存檔。它們都不是設定項目。

| 選項 | 內容 |
|:-------|:------|
| `@weather_revamped_value_<place>` | 一個地點已儲存的讀數，`_ts`、`_lock` 和 `_lock_ts` 記錄最後一次嘗試和正在進行的取得 |
| `@weather_revamped_<place>_ok_ts` | 最後一次回應的時間，由 `#{weather_stale_color}` 讀取 |
| `@weather_revamped_<place>_pressure_prev` | 上一次取得的氣壓，由趨勢讀取 |
| `@weather_revamped_alert_<place>` | 一個地點已儲存的警報行 |
| `@weather_revamped_published` | 狀態列用到的佔位符，在載入時記錄 |
| `@weather_revamped_out_<name>` | `options` 模式下每個已繪製的值 |
| `@weather_revamped_ticker_pid` | 負責 `options` 模式的程序 |

## 按鍵綁定

| 按鍵 | 動作 | 預設值 |
|:----|:-------|:--------|
| `prefix + M-w` | 顯示全部讀數的預報彈出視窗；按 Enter 關閉 | 已綁定 |
| `@weather_revamped_refresh_key` | 即時在背景取得 | 未綁定 |

`@weather_revamped_popup_key` 可以指定其他按鍵，設為 `off` 則不綁定。預設按鍵已被佔用時不會改動它，`weather-revamped doctor` 會說明這一點。

<a id="運作原理"></a>

## 運作原理

[`weather-revamped.tmux`](weather-revamped.tmux) 在 tmux 載入插件時執行一次。它把 `status-left` 和 `status-right` 用到的佔位符記錄在 `@weather_revamped_published` 內，然後把每個佔位符替換為對 [`bin/weather-revamped`](bin/weather-revamped) 的呼叫；在 `options` 模式下則替換為讀取選項，並啟動背景程序。

在預設模式下，每次 `#()` 呼叫都即時輸出已儲存的讀數。最後一次嘗試早於取得間隔時，這次呼叫會在背景啟動一次取得並加鎖，所以同一時間只有一次取得在執行。取得時以 `curl` 向 wttr.in 請求 `j1` 回應，只保留插件讀取的 22 個欄位，並連同時間在一次 tmux 呼叫中寫入。說明地點未知的回應會被捨棄，保留上一次的讀數。

天氣狀況、風向、月相、日出日落時間和警報在進入狀態列之前，每個 `#` 都會寫成兩個，所以像 `#(cmd)` 這樣的文字只會顯示為文字，不會被執行。

取得、解析和每個佔位符的程式碼在 [`lib/weather.sh`](lib/weather.sh) 內，設定表在 [`lib/state.sh`](lib/state.sh) 內。

<a id="畫面"></a>

## 畫面

<details>
<summary>所有畫面，在真實的 tmux 中以 <code>make screens</code> 錄製，每個按鍵顯示在狀態列上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/weather.png" alt="weather-revamped: weather"><br><sub>狀態列中的天氣狀況、溫度、風和濕度，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="weather-revamped: popup"><br><sub><code>prefix M-w</code> 開啟預報彈出視窗，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fahrenheit.png" alt="weather-revamped: fahrenheit"><br><sub>將 <code>@weather_revamped_units</code> 設為 <code>u</code> 後切換至華氏度和英里，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh-key.png" alt="weather-revamped: refresh-key"><br><sub>重新整理鍵 <code>prefix R</code> 即時取得，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="weather-revamped: options"><br><sub>在 <code>options</code> 繪製模式下，每個佔位符讀取一個 tmux 選項，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="weather-revamped: list"><br><sub><code>list</code> 輸出 <code>apply</code> 將傳送給 tmux 的內容，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="weather-revamped: status"><br><sub><code>status</code> 輸出一個佔位符，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/place.png" alt="weather-revamped: place"><br><sub>為手動指定的地點執行 <code>status</code>，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="weather-revamped: card"><br><sub><code>card</code> 輸出全部讀數，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="weather-revamped: refresh"><br><sub><code>refresh</code> 即時取得並說明 wttr.in 的回應，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="weather-revamped: version"><br><sub><code>version</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="weather-revamped: doctor"><br><sub><code>doctor</code> 列出 curl、讀數和通知工具，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="weather-revamped: error"><br><sub>無效的值會在執行任何操作之前讓工具停下，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="weather-revamped: accent"><br><sub>換了強調色的選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="weather-revamped: plain-menu"><br><sub>沒有 gum 時選單帶編號，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="weather-revamped: plain-doctor"><br><sub>沒有 gum 時 <code>doctor</code> 輸出純文字行，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/details.png" alt="weather-revamped: details"><br><sub>溫度、體感溫度、風、濕度、氣壓及其趨勢和降水量，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/forecast.png" alt="weather-revamped: forecast"><br><sub>明天、今天、降雨機會和雨傘文字，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sky.png" alt="weather-revamped: sky"><br><sub>紫外線及其顏色、露點和舒適度、月亮和太陽，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/alert.png" alt="weather-revamped: alert"><br><sub>帶前綴的警報行，來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="weather-revamped: temp"><br><sub>天空狀況的色調和圖示、溫度區間的顏色和圖示、隱藏單位和固定闊度，來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="weather-revamped: help"><br><sub><code>help</code>，來自 <code>help.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="weather-revamped: themes"><br><sub>八個主題，來自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

錄製時執行的是真實的插件和 tmux。`curl` 由一個小腳本代替，所以畫面上的天氣來自這個腳本。

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

在 macOS 上，執行 `brew bundle` 會根據 [`Brewfile`](Brewfile) 安裝這些目標用到的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | **本插件**，在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
