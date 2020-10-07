# IP Filter Updater &amp; Generator
Creates PeerGuardian (`.p2p`) blocklist from [I-Blocklist](https://www.iblocklist.com/) blocklists and [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) country blocks.

## Requirements
Operating System:<br/>
_Linux_, _FreeBSD_, _macOS_ or _Windows_.

Tools & Utilities:<br/>
_Bash >= 4.0_, _awk_, _grep_, _gunzip_, _sed_, _unzip_, _curl_ / _wget_, _gzip_ / _bzip2_ / _xz_ / _zip_<sup>[(1)](#footnote1)</sup>, _notify-send_ / _osascript_ / _powershell_<sup>[(2)](#footnote2)</sup>.

<sup><a name="footnote1">(1)</a></sup> optional, required for _gzip_ / _bzip2_ / _xz_ / _zip_ compression of output file if configured<br/>
<sup><a name="footnote2">(2)</a></sup> optional, required for option `-n/--notify` on _Linux_/_FreeBSD_ / _macOS_ / _Windows_<br/>

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.

Windows users need to setup a runtime environment. [Cygwin](https://www.cygwin.com/), [MSYS2](https://www.msys2.org/), [Git for Windows](https://git-scm.com/download/win) and [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) should all work fine. _Git for Windows_ might be a good choice to get started - it is reasonably lightweight, easy to set up, meets all requirements out of the box and is also available as a portable version.

## Download
Refer to the [releases](https://github.com/fonic/ipfilter/releases) section for downloads links.

## Installation
There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust the settings to your liking. Refer to embedded comments for details. Before changing any settings, you might want to run the script with default settings to make sure it works as expected.

## Subscriptions
Subscriptions are not required to use the _I-Blocklist_ functionality, as most of the lists provided by _I-Blocklist_ are free to download. There are some additional lists that are only available to subscribers, though.

Using the _GeoLite2_ functionality requires a subscription due to [recent changes](https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/), which is free of charge.

## Usage
Open a terminal/console running Bash and run the script using the following command(s):
```
$ <path-to-script>/ipfilter.sh
-or-
$ cd <path-to-script>
$ ./ipfilter.sh
```

Note that root privileges should not be required. Just make sure the configured `INSTALL_DST` points to a location writeable by the user running the script.

For running non-interactively (e.g. via cron), you might want to add option `-n/--notify` to send desktop notifications informing you about success/failure.

Use option `-h/--help` to display available command line options.
