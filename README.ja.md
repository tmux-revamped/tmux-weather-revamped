<div align="center">

# tmux-weather-revamped

<strong>wttr.in の天気を tmux のステータスバーに表示します。取得はバックグラウンドで行うので、ステータスラインは待たされません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-weather-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-weather-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-weather-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-weather-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-weather-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-weather-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-weather-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="weather-revamped がステータスラインに天気を表示し、予報ポップアップを開き、華氏に切り替え、更新キーで取得し、options 描画モードに切り替える様子" width="800">
</p>

```console
$ weather-revamped refresh
Refreshed. wttr.in says Partly cloudy +18°C for Lisbon.
$ weather-revamped status weather
Partly cloudy +18°C
```

場所ごとに **1** 回のリクエストで **28** 個のプレースホルダー、**2** つの描画モード、macOS と Linux、tmux **3.2** 以降に対応します。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン。ポップアップにも必要です |
| curl | 任意のバージョン | すべての取得。10 秒で打ち切ります |
| gum | 任意 | `weather-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

[wttr.in](https://wttr.in) へのネットワーク接続が必要です。Linux と macOS で、BSD、GNU、uutils のどの coreutils でも動きます。

### インストール

[TPM](https://github.com/tmux-plugins/tpm) を使う場合は、`~/.tmux.conf` にプラグインとプレースホルダーを追加して `prefix + I` を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-weather-revamped'
set -g status-right '#{weather} '
```

手動でインストールする場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-weather-revamped ~/.tmux/plugins/tmux-weather-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-weather-revamped/weather-revamped.tmux
```

`status-left` または `status-right` はプラグインを読み込む前に設定してください。プラグインは読み込み時に 1 回だけ、そこにあるプレースホルダーを置き換えます。[`examples/status-right.tmux.conf`](examples/status-right.tmux.conf) にコピーして使える 1 行があります。

クローンで `make install` を実行すると、`weather-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-weather-revamped/bin/weather-revamped doctor
```

## 使い方

場所を設定します。空のままにすると wttr.in が IP から現在地を判断します。すべてのプレースホルダーは保存した同じ応答から作るので、項目を増やしてもリクエストは増えません。起動直後は最初の取得が終わるまで空で、取得に失敗しても直前の値を表示し続けます。

```tmux
set -g @weather_revamped_location 'Lisbon'
set -g status-right '#{weather_color}#{weather_condition_icon} #{weather_temp}#[default] #{weather_wind} '
```

| プレースホルダー | 出力 |
|:------------|:-------|
| `#{weather}` | 天気と気温。例 `Partly cloudy +18°C` |
| `#{weather_temp}` | プラス記号なしの気温。例 `18°C` |
| `#{weather_feels_like}` | 体感温度。例 `16` |
| `#{weather_wind}` | 風速と風向。例 `11km/h NW` |
| `#{weather_humidity}` | 相対湿度（パーセント） |
| `#{weather_pressure}` | 気圧（hPa） |
| `#{weather_pressure_trend}` | 前回の取得と比べた `^`、`v`、`=` |
| `#{weather_precip}` | 降水量（ミリメートル） |
| `#{weather_rain_chance}` | 今日の予報の最初の 8 区間で最も高い降水確率 |
| `#{weather_umbrella}` | 降水確率がしきい値に達したときに出す、傘のテキスト |
| `#{weather_uv}` | UV 指数 |
| `#{weather_uv_color}` | UV の段階に応じた tmux のスタイル |
| `#{weather_dew_point}` | 今日の予報の最初の 8 区間の露点の平均 |
| `#{weather_dew_comfort}` | `dry`、`comfortable`、`humid`、`oppressive` のいずれか |
| `#{weather_moon}` | 月相。例 `Waning Gibbous` |
| `#{weather_sunrise}` | 日の出。例 `06:00 AM` |
| `#{weather_sunset}` | 日の入り。例 `06:45 PM` |
| `#{weather_forecast}` | 明日の最低気温と最高気温。例 `15-27` |
| `#{weather_today_high}` | 今日の最高気温 |
| `#{weather_today_low}` | 今日の最低気温 |
| `#{weather_tomorrow_high}` | 明日の最高気温 |
| `#{weather_tomorrow_low}` | 明日の最低気温 |
| `#{weather_condition_icon}` | 空模様を表す Nerd Font のグリフ |
| `#{weather_condition_tint}` | 空模様に応じた tmux のスタイル |
| `#{weather_color}` | 気温帯に応じた tmux のスタイル。例 `#[fg=green]` |
| `#{weather_icon}` | 気温帯ごとに設定するアイコン。設定するまで空です |
| `#{weather_stale_color}` | 最後の応答が取得間隔の 3 倍より古くなると `#[dim]` |
| `#{weather_alert}` | 自分で指定したアドレスから取る警報の行。警報が有効でなければ空です |

### 複数の場所

`@weather_revamped_locations` には `;` で区切った場所を指定します。最初の場所がプレースホルダーに使われます。ほかの場所はステータスラインやスクリプトから直接読み出せ、場所ごとに値を保存します。

```tmux
set -g @weather_revamped_locations 'Lisbon;Oslo'
```

```bash
weather-revamped status weather Oslo
weather-revamped card Oslo
```

### 警報

wttr.in は警報を返さないため、警報の行は自分で指定したアドレスから取ります。`@weather_revamped_alerts` を `on` にすると、`@weather_revamped_alert_url` の最初の空でない行が `#{weather_alert}` になります。`@weather_revamped_notify` を `1` にすると、新しい警報をデスクトップ通知でも知らせます。

### 描画モード

既定の `jobs` モードでは、各プレースホルダーが保存した値をすぐに出力するステータスジョブになります。`@weather_revamped_render` を `options` にすると、1 つのバックグラウンドプロセスが取得を行い、ティックごとにすべてのプレースホルダーを tmux オプションへ書き込むので、ステータスの更新でプロセスは起動しません。

### コマンド

| コマンド | 内容 |
|:--------|:-------------|
| `weather-revamped status NAME [PLACE]` | プレースホルダーを 1 つ出力します。名前は `weather_` を除いたもので、最初の 1 つは `weather` です |
| `weather-revamped refresh [PLACE]` | 今すぐ取得し、wttr.in の応答を表示します |
| `weather-revamped card [PLACE]` | すべての値を表で出力します |
| `weather-revamped popup [PLACE]` | その表を tmux のポップアップで開きます |
| `weather-revamped list` | `apply` が tmux に送る内容を出力します。`--json` で 1 つのオブジェクトとして出力します |
| `weather-revamped apply` | エントリポイントと同じく、キーを割り当ててプレースホルダーを置き換えます |
| `weather-revamped doctor` | このマシンを確認します |

どの tmux オプションも、コマンドのオプション（例 `--units u`）と環境変数（例 `WEATHER_REVAMPED_UNITS`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。on と off のオプションは `1`、`yes`、`true` を on、`0`、`no`、`false` を off として読みます。それ以外の値を持つ tmux オプションは既定値になり、`doctor` がその名前を表示します。

## 設定

### 取得

| オプション | 既定値 | 内容 |
|:-------|:--------|:-------------|
| `@weather_revamped_location` | なし | 都市や場所。空にすると wttr.in が IP から判断します |
| `@weather_revamped_locations` | なし | `;` で区切った場所。最初の場所がプレースホルダーに使われ、単一の場所の設定より優先されます |
| `@weather_revamped_units` | `m` | `m` は摂氏と km/h、`u` は華氏と mph。`f`、`fahrenheit`、`imperial` は `u` として扱います |
| `@weather_revamped_fetch_minutes` | `15` | 次に取得するまで値を使い続ける分数。1 以上 |
| `@weather_revamped_alerts` | `off` | `on` にすると、値を取得するたびに警報のアドレスも取得します |
| `@weather_revamped_alert_url` | なし | 警報のアドレス。`{loc}` は場所に置き換わります。最初の空でない行が警報になります |
| `@weather_revamped_alert_prefix` | なし | `#{weather_alert}` の前に付けるテキスト |
| `@weather_revamped_notify` | `0` | `1` にすると、新しい警報をデスクトップ通知で知らせます |

### 表示

| オプション | 既定値 | 内容 |
|:-------|:--------|:-------------|
| `@weather_revamped_hide_units` | `off` | `on` にすると `#{weather_temp}` から `C` や `F` を外します |
| `@weather_revamped_fixed_width` | `off` | `on` にすると気温を 5 文字にそろえます |
| `@weather_revamped_temp_width` | なし | 気温の幅。固定幅より優先されます |
| `@weather_revamped_show_condition_icon` | `on` | `off` にすると `#{weather_condition_icon}` を空にします |
| `@weather_revamped_<sky>_condition_icon` | Nerd Font のグリフ | 空模様ごとのアイコン。`clear`、`clouds`、`rain`、`snow`、`storm`、`fog` |
| `@weather_revamped_<sky>_tint` | yellow, brightblack, blue, white, magenta, brightblack | 空模様ごとのスタイル。上の順です |
| `@weather_revamped_<band>_color` | blue, cyan, green, green, yellow, red | 気温帯ごとのスタイル。摂氏で `freezing` は 0 未満、`cold` は 9 まで、`cool` は 17 まで、`comfortable` は 23 まで、`hot` は 31 まで、`very_hot` はそれより上です |
| `@weather_revamped_<band>_icon` | なし | 気温帯ごとのアイコン |
| `@weather_revamped_uv_<level>_color` | green, yellow, colour208, red, magenta | UV の段階ごとのスタイル。`low` は 2 まで、`moderate` は 5 まで、`high` は 7 まで、`very_high` は 10 まで、`extreme` はそれより上です |
| `@weather_revamped_stale_color` | `#[dim]` | 古くなった値のスタイル |
| `@weather_revamped_umbrella_text` | なし | `#{weather_umbrella}` のテキスト。`{chance}` は降水確率に置き換わります |
| `@weather_revamped_umbrella_threshold` | `50` | 傘のテキストを出す降水確率（パーセント） |
| `@weather_revamped_pressure_delta` | `1` | 気圧の上昇や下降とみなす変化量（hPa） |
| `@weather_revamped_pressure_rising` | `^` | 上昇の記号 |
| `@weather_revamped_pressure_falling` | `v` | 下降の記号 |
| `@weather_revamped_pressure_steady` | `=` | 横ばいの記号 |

### 描画

| オプション | 既定値 | 内容 |
|:-------|:--------|:-------------|
| `@weather_revamped_render` | `jobs` | `options` にすると、各プレースホルダーはバックグラウンドプロセスが書き込む tmux オプションを読みます |
| `@weather_revamped_interval` | `60` | そのプロセスのティックの間隔（秒） |

### 内部状態

プラグインは状態を tmux オプションに保存し、一時ファイルは使いません。どれも設定ではありません。

| オプション | 内容 |
|:-------|:------|
| `@weather_revamped_value_<place>` | 1 つの場所の保存した値。`_ts`、`_lock`、`_lock_ts` は最後の試行と実行中の取得を表します |
| `@weather_revamped_<place>_ok_ts` | 最後に応答があった時刻。`#{weather_stale_color}` が読みます |
| `@weather_revamped_<place>_pressure_prev` | 前回取得した気圧。傾向の表示が読みます |
| `@weather_revamped_alert_<place>` | 1 つの場所の保存した警報の行 |
| `@weather_revamped_published` | ステータスラインが使うプレースホルダー。読み込み時に記録します |
| `@weather_revamped_out_<name>` | `options` モードで描画した各値 |
| `@weather_revamped_ticker_pid` | `options` モードを受け持つプロセス |

## キーバインド

| キー | 動作 | 既定値 |
|:----|:-------|:--------|
| `prefix + M-w` | すべての値を表示する予報ポップアップ。Enter で閉じます | 割り当て済み |
| `@weather_revamped_refresh_key` | バックグラウンドですぐに取得します | 未割り当て |

`@weather_revamped_popup_key` で別のキーを指定でき、`off` にすると割り当てません。既定のキーがすでに他で使われている場合は触れず、`weather-revamped doctor` がそれを表示します。

<a id="仕組み"></a>

## 仕組み

[`weather-revamped.tmux`](weather-revamped.tmux) は tmux がプラグインを読み込むときに 1 回だけ実行されます。`status-left` と `status-right` が使うプレースホルダーを `@weather_revamped_published` に記録し、それぞれを [`bin/weather-revamped`](bin/weather-revamped) の呼び出しに置き換えます。`options` モードではオプションの読み出しに置き換え、バックグラウンドプロセスを起動します。

既定のモードでは、各 `#()` 呼び出しが保存した値をすぐに出力します。最後の試行が取得間隔より古いと、呼び出しはバックグラウンドで取得を 1 つ始めてロックを取るので、同時に動く取得は 1 つだけです。取得では `curl` で wttr.in の `j1` 応答を受け取り、プラグインが読む 22 個のフィールドだけを残し、時刻とともに 1 回の tmux 呼び出しで書き込みます。場所が不明だという応答は捨て、直前の値を残します。

天気、風向、月相、日の出と日の入りの時刻、警報は、ステータスラインに渡す前にすべての `#` を二重にします。そのため `#(cmd)` のようなテキストは実行されず、文字として表示されます。

取得、読み取り、各プレースホルダーの処理は [`lib/weather.sh`](lib/weather.sh) に、設定の表は [`lib/state.sh`](lib/state.sh) にあります。

<a id="画面"></a>

## 画面

<details>
<summary>すべての画面。本物の tmux の中で <code>make screens</code> で録画し、押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/weather.png" alt="weather-revamped: weather"><br><sub>ステータスラインに天気、気温、風、湿度を表示。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="weather-revamped: popup"><br><sub><code>prefix M-w</code> で予報ポップアップを開く。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fahrenheit.png" alt="weather-revamped: fahrenheit"><br><sub><code>@weather_revamped_units</code> を <code>u</code> にすると華氏とマイルに切り替わる。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/refresh-key.png" alt="weather-revamped: refresh-key"><br><sub>更新キーの <code>prefix R</code> ですぐに取得する。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="weather-revamped: options"><br><sub><code>options</code> 描画モードでは各プレースホルダーが tmux オプションを読む。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="weather-revamped: list"><br><sub><code>list</code> は <code>apply</code> が tmux に送る内容を出力する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="weather-revamped: status"><br><sub><code>status</code> はプレースホルダーを 1 つ出力する。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/place.png" alt="weather-revamped: place"><br><sub>場所を指定した <code>status</code>。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="weather-revamped: card"><br><sub><code>card</code> はすべての値を出力する。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="weather-revamped: refresh"><br><sub><code>refresh</code> は今すぐ取得して wttr.in の応答を表示する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="weather-revamped: version"><br><sub><code>version</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="weather-revamped: doctor"><br><sub><code>doctor</code> は curl、保存した値、通知手段を表示する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="weather-revamped: error"><br><sub>不正な値は、何も実行する前にツールを止める。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="weather-revamped: accent"><br><sub>アクセント色を変えたメニュー。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="weather-revamped: plain-menu"><br><sub>gum がない場合、メニューは番号付きになる。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="weather-revamped: plain-doctor"><br><sub>gum がない場合、<code>doctor</code> はプレーンな行を出力する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/details.png" alt="weather-revamped: details"><br><sub>気温、体感温度、風、湿度、気圧とその傾向、降水量。<code>features.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/forecast.png" alt="weather-revamped: forecast"><br><sub>明日、今日、降水確率、傘のテキスト。<code>features.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sky.png" alt="weather-revamped: sky"><br><sub>UV とその色、露点と快適さ、月と太陽。<code>features.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/alert.png" alt="weather-revamped: alert"><br><sub>前置きのテキストを付けた警報の行。<code>features.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="weather-revamped: temp"><br><sub>空模様の色とアイコン、気温帯の色とアイコン、単位の非表示、固定幅。<code>features.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="weather-revamped: help"><br><sub><code>help</code>。<code>help.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="weather-revamped: themes"><br><sub>8 つのテーマ。<code>themes.tape</code>より</sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

録画では本物のプラグインと tmux を動かしています。`curl` の代わりに小さなスクリプトを使っているので、画面の天気はそのスクリプトのものです。

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | **このプラグイン**、wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
