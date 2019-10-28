# ipfilter
IP Filter Updater &amp; Generator
## Requirements
Bash >= 4.0, wget, gunzip, unzip, sed, grep, notify-send (only if using option '--notify')
## Download
```
# git clone https://github.com/fonic/ipfilter.git
```
## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust it to your liking. Refer to embedded comments for details.
## Usage
```
# ./ipfilter.sh
```
As simple as that. For running via cron, you might want to add `--notify`. Run `./ipfilter.sh --help` to display usage information.
