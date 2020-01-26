# IP Filter Updater &amp; Generator
Creates PeerGuardian (`.p2p`) blocklist from I-Blocklist blocklists and GeoLite2 country blocks.

## Requirements
Operating System:<br/>
_Linux_, _FreeBSD_ or _macOS_.

Tools & Utilities:<br/>
_Bash >= 4.0_, _awk_, _grep_, _gunzip_, _sed_, _unzip_, _wget_, _notify-send_<sup>[(1)](#footnote1)</sup>, _osascript_<sup>[(2)](#footnote2)</sup>.

<sup><a name="footnote1">(1)</a></sup> optional, required for option `-n/--notify` on _Linux_ / _FreeBSD_<br/>
<sup><a name="footnote2">(2)</a></sup> optional, required for option `-n/--notify` on _macOS_<br/>

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.

## Download
Either use this [download link](https://github.com/fonic/ipfilter/archive/master.zip) or one of the following commands:
```
# git clone https://github.com/fonic/ipfilter.git ipfilter
# wget https://github.com/fonic/ipfilter/archive/master.zip -O ipfilter.zip
# curl -L https://github.com/fonic/ipfilter/archive/master.zip -o ipfilter.zip
```

## Installation
There is no installation required. Simply extract the downloaded archive to a folder of your choice, e.g. `/opt/ipfilter` or `/home/<user>/ipfilter`.

## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust the settings to your liking.

Refer to embedded comments for details.

## Usage
```
# ./ipfilter.sh
```
For running via cron, you might want to add option `-n/--notify`.

Use option `-h/--help` to display usage information.
