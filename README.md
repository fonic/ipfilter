# ipfilter
IP Filter Updater &amp; Generator
## Requirements
Bash >= 4.0, wget, gunzip, unzip, sed, grep. In other words: nothing fancy.
## Download
```
# git clone https://github.com/fonic/ipfilter.git
```
## Configuration
Open `ipfilter.sh` in your favorite text editor and modify variables `IBL_LISTS`, `GL2_COUNTRIES` and `INSTALL_TO` to your liking. Don't touch anything else.
## Usage
```
# ./ipfilter.sh
```
As simple as that. For running via cron, you might want to add `--notify`. See `--help` for usage information.
