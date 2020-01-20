# ipfilter
IP Filter Updater &amp; Generator

Updates/generates .p2p blocklist from I-Blocklist blocklists and GeoLite2 country blocks.
## Requirements
Bash >= 4.0, wget, gunzip, unzip, sed, grep, awk,
notify-send (optional, required for option `-n/--notify` on Linux),
osascript (optional, required for option `-n/--notify` on macOS).

Shells other than Bash *might* work, but will most likely require some modifications.

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.
## Download
```
# git clone https://github.com/fonic/ipfilter.git
```
## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust it to your liking.

Refer to embedded comments for details.
## Usage
```
# ./ipfilter.sh
```
As simple as that.

For running via cron, you might want to add option `-n/--notify`.

Run `./ipfilter.sh --help` to display usage information.
