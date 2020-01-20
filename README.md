# ipfilter
IP Filter Updater &amp; Generator

Updates/generates `.p2p` blocklist from I-Blocklist blocklists and GeoLite2 country blocks.
## Requirements
Bash >= 4.0, awk, grep, gunzip, sed, unzip, wget,<br/>
notify-send _(optional, required for option `-n/--notify` on Linux)_,<br/>
osascript _(optional, required for option `-n/--notify` on macOS)_.

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.
## Download
Either use the download button or one of the following commands:
```
# git clone https://github.com/fonic/ipfilter.git ipfilter
# wget https://github.com/fonic/ipfilter/archive/master.zip -O ipfilter.zip
# curl -L https://github.com/fonic/ipfilter/archive/master.zip -o ipfilter.zip
```
## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust it to your liking.

Refer to embedded comments for details.
## Usage
```
# ./ipfilter.sh
```
For running via cron, you might want to add option `-n/--notify`.

Use option `-h/--help` to display usage information.
