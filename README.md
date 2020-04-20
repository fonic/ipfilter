# IP Filter Updater &amp; Generator
Creates PeerGuardian (`.p2p`) blocklist from [I-Blocklist](https://www.iblocklist.com/) blocklists and [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) country blocks.

## Requirements
Operating System:<br/>
_Linux_, _FreeBSD_, _macOS_ or _Windows_.

Tools & Utilities:<br/>
_Bash >= 4.0_, _awk_, _grep_, _gunzip_, _sed_, _unzip_, _curl_ / _wget_, _gzip_ / _bzip2_ / _zip_<sup>[(1)](#footnote1)</sup>, _notify-send_ / _osascript_ / _powershell_<sup>[(2)](#footnote2)</sup>.

<sup><a name="footnote1">(1)</a></sup> optional, required for _gzip_ / _bzip2_ / _zip_ compression of output file if enabled<br/>
<sup><a name="footnote2">(2)</a></sup> optional, required for option `-n/--notify` on _Linux_/_FreeBSD_ / _macOS_ / _Windows_<br/>

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.

Windows users might want to use [Git for Windows](https://git-scm.com/download/win) as a runtime environment. It is reasonably lightweight, features up-to-date GNU utitilies and meets all requirements out of the box. A portable version is available, too.

## Download
Refer to the [releases](https://github.com/fonic/ipfilter/releases) section for downloads links.

## Installation
There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust the settings to your liking. Before changing settings, you might want to run the script with default settings to make sure it works as expected.

Refer to embedded comments for details.

## Subscriptions
Subscriptions are not required to use the *I-Blocklist* functionality, as most of the lists provided by *I-Blocklist* are free to download. There are some additional lists that are only available to subscribers, though.

Using the *GeoLite2* functionality requires a subscription due to [recent changes](https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/), which is free of charge.

## Usage
Open a terminal/console running Bash and use the following command to run:
```
# ./ipfilter.sh
```
For running non-interactively (e.g. via cron), you might want to add option `-n/--notify` to send desktop notifications.

Use option `-h/--help` to display usage information.
