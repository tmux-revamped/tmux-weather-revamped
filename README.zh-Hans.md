<div align="center">

# tmux-weather-revamped

<strong>在 tmux 状态栏显示来自 wttr.in 的天气，在后台获取，状态栏从不等待。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-weather-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-weather-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-weather-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-weather-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-weather-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-weather-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-weather-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="weather-revamped 在状态栏显示天气、打开预报弹窗、切换到华氏度、按刷新键获取并切换到 options 渲染模式" width="800">
</p>

```console
$ weather-revamped refresh
Refreshed. wttr.in says Partly cloudy +18°C for Lisbon.
$ weather-revamped status weather
Partly cloudy +18°C
```

每个地点 **1** 次请求提供 **28** 个占位符，**2** 种渲染模式，支持 macOS 和 Linux，需要 tmux **3.2** 及以上版本。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本，弹窗也需要它 |
| curl | 任意版本 | 每次获取，限时 10 秒 |
| gum | 可选 | `weather-revamped` 的菜单、表格和颜色；没有它，所有命令都输出纯文本 |

需要能够访问 [wttr.in](https://wttr.in)，可在 Linux 和 macOS 上运行，支持 BSD、GNU 和 uutils coreutils。

### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件和一个占位符加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-weather-revamped'
set -g status-right '#{weather} '
```

手动安装时，克隆仓库，并在 `~/.tmux.conf` 中运行入口脚本：

```bash
git clone https://github.com/tmux-revamped/tmux-weather-revamped ~/.tmux/plugins/tmux-weather-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-weather-revamped/weather-revamped.tmux
```

请在插件加载之前设置 `status-left` 或 `status-right`。插件只在加载时替换一次其中的占位符。[`examples/status-right.tmux.conf`](examples/status-right.tmux.conf) 里有一行可以直接复制。

在克隆的目录中运行 `make install`，还会把 `weather-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-weather-revamped/bin/weather-revamped doctor
```

## 用法

设置一个地点，或者留空，让 wttr.in 按 IP 定位。所有占位符都来自同一份已保存的应答，所以显示更多内容不会增加请求。冷启动后第一次渲染为空，等待第一次获取完成；获取失败时，屏幕上保留上一次的读数。

```tmux
set -g @weather_revamped_location 'Lisbon'
set -g status-right '#{weather_color}#{weather_condition_icon} #{weather_temp}#[default] #{weather_wind} '
```

| 占位符 | 输出 |
|:------------|:-------|
| `#{weather}` | 天气状况和温度，例如 `Partly cloudy +18°C` |
| `#{weather_temp}` | 不带加号的温度，例如 `18°C` |
| `#{weather_feels_like}` | 体感温度，例如 `16` |
| `#{weather_wind}` | 风速和风向，例如 `11km/h NW` |
| `#{weather_humidity}` | 相对湿度，百分比 |
| `#{weather_pressure}` | 气压，单位 hPa |
| `#{weather_pressure_trend}` | 与上一次获取相比的 `^`、`v` 或 `=` |
| `#{weather_precip}` | 降水量，单位毫米 |
| `#{weather_rain_chance}` | 今天前八个预报时段中最高的降雨概率 |
| `#{weather_umbrella}` | 降雨概率达到阈值后显示的雨伞文字 |
| `#{weather_uv}` | 紫外线指数 |
| `#{weather_uv_color}` | 对应紫外线等级的 tmux 样式 |
| `#{weather_dew_point}` | 今天前八个预报时段的平均露点 |
| `#{weather_dew_comfort}` | `dry`、`comfortable`、`humid` 或 `oppressive` |
| `#{weather_moon}` | 月相，例如 `Waning Gibbous` |
| `#{weather_sunrise}` | 日出，例如 `06:00 AM` |
| `#{weather_sunset}` | 日落，例如 `06:45 PM` |
| `#{weather_forecast}` | 明天的最低和最高温度，例如 `15-27` |
| `#{weather_today_high}` | 今天的最高温度 |
| `#{weather_today_low}` | 今天的最低温度 |
| `#{weather_tomorrow_high}` | 明天的最高温度 |
| `#{weather_tomorrow_low}` | 明天的最低温度 |
| `#{weather_condition_icon}` | 表示天空状况的 Nerd Font 字形 |
| `#{weather_condition_tint}` | 对应天空状况的 tmux 样式 |
| `#{weather_color}` | 对应温度区间的 tmux 样式，例如 `#[fg=green]` |
| `#{weather_icon}` | 你为温度区间设置的图标，未设置时为空 |
| `#{weather_stale_color}` | 最后一次应答超过三个获取间隔后为 `#[dim]` |
| `#{weather_alert}` | 来自你自己指定地址的警报行，未开启警报时为空 |

### 多个地点

`@weather_revamped_locations` 接受用 `;` 分隔的多个地点。第一个地点用于占位符。其他地点可以在状态栏或脚本中手动读取，每个地点保存自己的读数：

```tmux
set -g @weather_revamped_locations 'Lisbon;Oslo'
```

```bash
weather-revamped status weather Oslo
weather-revamped card Oslo
```

### 警报

wttr.in 不提供警报，所以警报行来自你自己指定的地址。把 `@weather_revamped_alerts` 设为 `on` 后，`@weather_revamped_alert_url` 返回的第一行非空内容就是 `#{weather_alert}`；把 `@weather_revamped_notify` 设为 `1`，新的警报还会发出桌面通知。

### 渲染模式

在默认的 `jobs` 模式下，每个占位符是一个状态任务，立即输出已保存的读数。把 `@weather_revamped_render` 设为 `options` 后，由一个后台进程负责获取，并在每个周期把所有占位符写入 tmux 选项，状态栏刷新时不再启动任何进程。

### 命令

| 命令 | 作用 |
|:--------|:-------------|
| `weather-revamped status NAME [PLACE]` | 输出一个占位符，名称不带 `weather_`；第一个是 `weather` |
| `weather-revamped refresh [PLACE]` | 立即获取，并说明 wttr.in 的应答 |
| `weather-revamped card [PLACE]` | 以表格输出全部读数 |
| `weather-revamped popup [PLACE]` | 在 tmux 弹窗中打开这张表 |
| `weather-revamped list` | 输出 `apply` 将发送给 tmux 的内容；`--json` 把它输出为一个对象 |
| `weather-revamped apply` | 绑定按键并替换占位符，与入口脚本相同 |
| `weather-revamped doctor` | 检查这台机器 |

每个 tmux 选项也可以写成命令选项，例如 `--units u`，或环境变量，例如 `WEATHER_REVAMPED_UNITS`；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。on 和 off 的选项也把 `1`、`yes` 和 `true` 读作 on，把 `0`、`no` 和 `false` 读作 off；tmux 选项是其他值时使用默认值，`doctor` 会指出是哪一个选项。

## 配置

### 读数

| 选项 | 默认值 | 作用 |
|:-------|:--------|:-------------|
| `@weather_revamped_location` | 无 | 城市或地点。留空时由 wttr.in 按 IP 定位 |
| `@weather_revamped_locations` | 无 | 用 `;` 分隔的地点。第一个用于占位符，并优先于单个地点的设置 |
| `@weather_revamped_units` | `m` | `m` 表示摄氏度和 km/h，`u` 表示华氏度和 mph；`f`、`fahrenheit` 和 `imperial` 按 `u` 处理 |
| `@weather_revamped_fetch_minutes` | `15` | 读数在下一次获取之前保持有效的分钟数，至少为 1 |
| `@weather_revamped_alerts` | `off` | `on` 表示每次获取读数后再获取警报地址 |
| `@weather_revamped_alert_url` | 无 | 警报地址，其中的 `{loc}` 会替换为地点。第一行非空内容就是警报 |
| `@weather_revamped_alert_prefix` | 无 | `#{weather_alert}` 之前的文字 |
| `@weather_revamped_notify` | `0` | `1` 表示有新警报时发送桌面通知 |

### 显示

| 选项 | 默认值 | 作用 |
|:-------|:--------|:-------------|
| `@weather_revamped_hide_units` | `off` | `on` 表示去掉 `#{weather_temp}` 中的 `C` 或 `F` |
| `@weather_revamped_fixed_width` | `off` | `on` 表示把温度补齐到五个字符 |
| `@weather_revamped_temp_width` | 无 | 温度的宽度，优先于固定宽度 |
| `@weather_revamped_show_condition_icon` | `on` | `off` 表示清空 `#{weather_condition_icon}` |
| `@weather_revamped_<sky>_condition_icon` | 一个 Nerd Font 字形 | 某种天空状况的图标：`clear`、`clouds`、`rain`、`snow`、`storm` 或 `fog` |
| `@weather_revamped_<sky>_tint` | yellow, brightblack, blue, white, magenta, brightblack | 某种天空状况的样式，顺序同上 |
| `@weather_revamped_<band>_color` | blue, cyan, green, green, yellow, red | 某个温度区间的样式，按摄氏度：`freezing` 低于 0，`cold` 到 9，`cool` 到 17，`comfortable` 到 23，`hot` 到 31，`very_hot` 更高 |
| `@weather_revamped_<band>_icon` | 无 | 某个温度区间的图标 |
| `@weather_revamped_uv_<level>_color` | green, yellow, colour208, red, magenta | 某个紫外线等级的样式：`low` 到 2，`moderate` 到 5，`high` 到 7，`very_high` 到 10，`extreme` 更高 |
| `@weather_revamped_stale_color` | `#[dim]` | 读数过期时的样式 |
| `@weather_revamped_umbrella_text` | 无 | `#{weather_umbrella}` 的文字，其中的 `{chance}` 会替换为降雨概率 |
| `@weather_revamped_umbrella_threshold` | `50` | 显示雨伞文字的降雨概率下限，百分比 |
| `@weather_revamped_pressure_delta` | `1` | 气压变化超过多少 hPa 才算上升或下降 |
| `@weather_revamped_pressure_rising` | `^` | 上升标记 |
| `@weather_revamped_pressure_falling` | `v` | 下降标记 |
| `@weather_revamped_pressure_steady` | `=` | 持平标记 |

### 渲染

| 选项 | 默认值 | 作用 |
|:-------|:--------|:-------------|
| `@weather_revamped_render` | `jobs` | `options` 表示每个占位符读取由后台进程写入的 tmux 选项 |
| `@weather_revamped_interval` | `60` | 该进程两个周期之间的秒数 |

### 内部状态

插件把状态保存在 tmux 选项里，不使用临时文件。它们都不是设置项。

| 选项 | 内容 |
|:-------|:------|
| `@weather_revamped_value_<place>` | 一个地点已保存的读数，`_ts`、`_lock` 和 `_lock_ts` 记录最后一次尝试和正在进行的获取 |
| `@weather_revamped_<place>_ok_ts` | 最后一次应答的时间，由 `#{weather_stale_color}` 读取 |
| `@weather_revamped_<place>_pressure_prev` | 上一次获取的气压，由趋势读取 |
| `@weather_revamped_alert_<place>` | 一个地点已保存的警报行 |
| `@weather_revamped_published` | 状态栏用到的占位符，在加载时记录 |
| `@weather_revamped_out_<name>` | `options` 模式下每个已渲染的值 |
| `@weather_revamped_ticker_pid` | 负责 `options` 模式的进程 |

## 按键绑定

| 按键 | 动作 | 默认值 |
|:----|:-------|:--------|
| `prefix + M-w` | 显示全部读数的预报弹窗；按 Enter 关闭 | 已绑定 |
| `@weather_revamped_refresh_key` | 立即在后台获取 | 未绑定 |

`@weather_revamped_popup_key` 可以指定其他按键，设为 `off` 则不绑定。默认按键已被占用时不会改动它，`weather-revamped doctor` 会说明这一点。

<a id="工作原理"></a>

## 工作原理

[`weather-revamped.tmux`](weather-revamped.tmux) 在 tmux 加载插件时运行一次。它把 `status-left` 和 `status-right` 用到的占位符记录在 `@weather_revamped_published` 中，然后把每个占位符替换为对 [`bin/weather-revamped`](bin/weather-revamped) 的调用；在 `options` 模式下则替换为读取选项，并启动后台进程。

在默认模式下，每次 `#()` 调用都立即输出已保存的读数。最后一次尝试早于获取间隔时，这次调用会在后台启动一次获取并加锁，所以同一时间只有一次获取在运行。获取时用 `curl` 向 wttr.in 请求 `j1` 应答，只保留插件读取的 22 个字段，并连同时间在一次 tmux 调用中写入。说明地点未知的应答会被丢弃，保留上一次的读数。

天气状况、风向、月相、日出日落时间和警报在进入状态栏之前，每个 `#` 都会写成两个，所以像 `#(cmd)` 这样的文字只会显示为文本，不会被执行。

获取、解析和每个占位符的代码在 [`lib/weather.sh`](lib/weather.sh) 中，设置表在 [`lib/state.sh`](lib/state.sh) 中。

<a id="界面"></a>

## 界面

<details>
<summary>所有界面，在真实的 tmux 中用 <code>make screens</code> 录制，每个按键显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/weather.png" alt="weather-revamped: weather"><br><sub>状态栏中的天气状况、温度、风和湿度，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="weather-revamped: popup"><br><sub><code>prefix M-w</code> 打开预报弹窗，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fahrenheit.png" alt="weather-revamped: fahrenheit"><br><sub>把 <code>@weather_revamped_units</code> 设为 <code>u</code> 后切换到华氏度和英里，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh-key.png" alt="weather-revamped: refresh-key"><br><sub>刷新键 <code>prefix R</code> 立即获取，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="weather-revamped: options"><br><sub>在 <code>options</code> 渲染模式下，每个占位符读取一个 tmux 选项，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="weather-revamped: list"><br><sub><code>list</code> 输出 <code>apply</code> 将发送给 tmux 的内容，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="weather-revamped: status"><br><sub><code>status</code> 输出一个占位符，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/place.png" alt="weather-revamped: place"><br><sub>为手动指定的地点运行 <code>status</code>，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/card.png" alt="weather-revamped: card"><br><sub><code>card</code> 输出全部读数，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="weather-revamped: refresh"><br><sub><code>refresh</code> 立即获取并说明 wttr.in 的应答，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="weather-revamped: version"><br><sub><code>version</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="weather-revamped: doctor"><br><sub><code>doctor</code> 列出 curl、读数和通知工具，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="weather-revamped: error"><br><sub>无效的值会在执行任何操作之前让工具停下，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="weather-revamped: accent"><br><sub>换了强调色的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="weather-revamped: plain-menu"><br><sub>没有 gum 时菜单带编号，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="weather-revamped: plain-doctor"><br><sub>没有 gum 时 <code>doctor</code> 输出纯文本行，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/details.png" alt="weather-revamped: details"><br><sub>温度、体感温度、风、湿度、气压及其趋势和降水量，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/forecast.png" alt="weather-revamped: forecast"><br><sub>明天、今天、降雨概率和雨伞文字，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/sky.png" alt="weather-revamped: sky"><br><sub>紫外线及其颜色、露点和舒适度、月亮和太阳，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/alert.png" alt="weather-revamped: alert"><br><sub>带前缀的警报行，来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="weather-revamped: temp"><br><sub>天空状况的色调和图标、温度区间的颜色和图标、隐藏单位和固定宽度，来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="weather-revamped: help"><br><sub><code>help</code>，来自 <code>help.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="weather-revamped: themes"><br><sub>八个主题，来自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"></td>
</tr>
</table>

录制时运行的是真实的插件和 tmux。`curl` 由一个小脚本代替，所以画面上的天气来自这个脚本。

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | **本插件**，在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
