# IP Filter Updater &amp; Generator
Creates PeerGuardian (`.p2p`) blocklist from [I-Blocklist](https://www.iblocklist.com/) blocklists and [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) country blocks.

## Requirements
Operating System:<br/>
_Linux_, _FreeBSD_, _macOS_ or _Windows_.

Tools & Utilities:<br/>
_Bash >= 4.0_, _awk_, _grep_, _gunzip_, _sed_, _unzip_, _wget_ -or- _curl_, _notify-send_<sup>[(1)](#footnote1)</sup>, _osascript_<sup>[(2)](#footnote2)</sup>, _powershell_<sup>[(3)](#footnote3)</sup>.

<sup><a name="footnote1">(1)</a></sup> optional, required for option `-n/--notify` on _Linux_ / _FreeBSD_<br/>
<sup><a name="footnote2">(2)</a></sup> optional, required for option `-n/--notify` on _macOS_<br/>
<sup><a name="footnote3">(3)</a></sup> optional, required for option `-n/--notify` on _Windows_<br/>

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.

Windows users might want to use [Git for Windows](https://git-scm.com/download/win) as a runtime environment, as it is reasonably lightweight and meets all requirements out of the box.

## Download
Either use this [download link](https://github.com/fonic/ipfilter/archive/master.zip) or one of the following commands:
```
# git clone https://github.com/fonic/ipfilter.git ipfilter
# wget https://github.com/fonic/ipfilter/archive/master.zip -O ipfilter.zip
# curl -L https://github.com/fonic/ipfilter/archive/master.zip -o ipfilter.zip
```

## Installation
There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust the settings to your liking.

Refer to embedded comments for details.

## Subscriptions
Subscriptions are not necessarily required to use the I-Blocklist functionality, as most of the lists provided by *I-Blocklist* are free to download. There are some additional lists that are only available to subscribers, though.

Using the *GeoLite2* functionality requires a subscription, which is free of charge.

## Usage
Open a terminal/console running Bash and use the following command to run:
```
# ./ipfilter.sh
```
For running non-interactively (e.g. via cron), you might want to add option `-n/--notify` to send desktop notifications.

Use option `-h/--help` to display usage information.
