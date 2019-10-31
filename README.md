# ipfilter
IP Filter Updater &amp; Generator

Updates/generates .p2p blocklist from I-Blocklist blocklists and GeoLite2 country blocks.
## Requirements
Bash >= 4.0, wget, gunzip, unzip, sed, grep, notify-send (optional, required for option `--notify`).

Shells other than Bash *might* work, but will most likely require some modifications.
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

For running via cron, you might want to add option `--notify`.

Run `./ipfilter.sh --help` to display usage information.
