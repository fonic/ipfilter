# IP Filter Updater &amp; Generator
Generates PeerGuardian (`.p2p`) blocklist from [I-Blocklist](https://www.iblocklist.com/) blocklists and [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) country blocks.

## Donations
I'm striving to become a full-time developer of [Free and open-source software (FOSS)](https://en.wikipedia.org/wiki/Free_and_open-source_software). Donations help me achieve that goal and are highly appreciated.

<a href="https://www.buymeacoffee.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/buymeacoffee-button.png" alt="Buy Me A Coffee" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://paypal.me/fonicmaxxim"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/paypal-button.png" alt="Donate via PayPal" height="35"></a>

## Requirements
**Operating System:**<br/>
_Linux_, _FreeBSD_, _macOS_ or _Windows_.

**Tools & Utilities:**<br/>
_Bash (>=4.0)_, _awk_, _grep_, _gunzip_, _sed_, _unzip_, _curl_ -or- _wget_, _gzip_/_bzip2_/_xz_/_zip_<sup>[(1)](#footnote1)</sup>, _notify-send_/_osascript_/_powershell_<sup>[(2)](#footnote2)</sup>.

<sup><a name="footnote1">(1)</a></sup> optional, required for _gzip_/_bzip2_/_xz_/_zip_ compression of output file<br/>
<sup><a name="footnote2">(2)</a></sup> optional, required for desktop notifications on _Linux_+_FreeBSD_/_macOS_/_Windows_<br/>

macOS users might want to use [Homebrew](https://brew.sh/) to install missing dependencies.

Windows users need to setup a suitable runtime environment. [Cygwin](https://www.cygwin.com/), [MSYS2](https://www.msys2.org/), [Git for Windows](https://git-scm.com/download/win) and [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about) should all work fine. [Git for Windows](https://git-scm.com/download/win) might be the best choice to get started - it is reasonably lightweight, easy to set up, meets all requirements out of the box and is also available as a portable version. Refer to [Windows Runtime Environments](https://github.com/fonic/ipfilter/blob/master/Windows%20Runtime%20Environments.md) for additional information.

## Download & Installation
Refer to the [releases](https://github.com/fonic/ipfilter/releases) section for downloads links. There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Configuration
Open `ipfilter.conf` in your favorite text editor and adjust the settings to your liking. Refer to embedded comments for details. Note that before changing any settings, it is recommended to run the script with *default settings* first to make sure it works as expected.

Configuration options and current defaults:
```sh
# ipfilter.conf

# ------------------------------------------------------------------------------
#                                                                              -
#  IP Filter Updater & Generator                                               -
#                                                                              -
#  Created by Fonic (https://github.com/fonic)                                 -
#  Date: 04/15/19 - 07/22/23                                                   -
#                                                                              -
# ------------------------------------------------------------------------------

# Switch to toggle verbose output (for both console + log file)
# Format:  String
# Example: VERBOSE_OUTPUT="true" | VERBOSE_OUTPUT="false"
# Default: VERBOSE_OUTPUT="false"
VERBOSE_OUTPUT="false"

# Path of file to log output to (folder + filename)
# NOTE:    ${SCRIPT_DIR}: directory of 'ipfilter.sh' script, ${SCRIPT_NAME}: filename of 'ipfilter.sh' script without extension
# Format:  String
# Example: LOG_FILE="/var/log/ipfilter.log"
# Default: LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"

# Mode to use for logging and log file handling
# NOTE:    Set to 'disabled' to disable logging entirely
# Format:  String
# Example: LOG_MODE="disabled" | LOG_MODE="overwrite" | LOG_MODE="append"
# Default: LOG_MODE="append"
LOG_MODE="append"

# Switch to toggle colored output for log file
# Format:  String
# Example: LOG_COLORS="true" | LOG_COLORS="false"
# Default: LOG_COLORS="false"
LOG_COLORS="false"

# Options to pass to curl when downloading files
# NOTE:    To debug download issues, temporarily remove option '--fail' and check contents of downloaded files for server messages
# Format:  Bash array of strings
# Example: CURL_OPTS=("--fail" "--location" "--silent" "--show-error" "--retry" "8" "--connect-timeout" "120" "--proxy" "<protocol>://<host>:<port>")
# Default: CURL_OPTS=("--fail" "--location" "--silent" "--show-error" "--retry" "2" "--connect-timeout" "60")
CURL_OPTS=("--fail" "--location" "--silent" "--show-error" "--retry" "2" "--connect-timeout" "60")

# Options to pass to wget when downloading files
# NOTE:    wget is used only if curl is not available; do not add option '--quiet' here as this will also suppress error messages
# Format:  Bash array of strings
# Example: WGET_OPTS=("--no-verbose" "--tries=9" "--timeout=120" "--execute" "use_proxy=yes" "--execute" "http_proxy=<host>:<port>")
# Default: WGET_OPTS=("--no-verbose" "--tries=3" "--timeout=60")
WGET_OPTS=("--no-verbose" "--tries=3" "--timeout=60")

# List of blocklists to download from I-Blocklist (https://www.iblocklist.com/lists)
# NOTE:    For possible ids, inspect link targets on page 'https://www.iblocklist.com/lists', e.g.
#          'level1' -> 'https://www.iblocklist.com/list?list=ydxerpxkpcfqjaybcssw' -> id is 'ydxerpxkpcfqjaybcssw'
# Format:  Bash dictionary of name-id-pairs (string-string-pairs)
# Example: IBL_LISTS=(["badpeers"]="cwworuawihqvocglcoss" ["adservers"]="zhogegszwduurnvsyhdf")
# Default: IBL_LISTS=(["level1"]="ydxerpxkpcfqjaybcssw" ["level2"]="gyisgnzbhppbvsphucsw" ["level3"]="uwnukjqktoggdknzrhgh")
IBL_LISTS=(["level1"]="ydxerpxkpcfqjaybcssw" ["level2"]="gyisgnzbhppbvsphucsw" ["level3"]="uwnukjqktoggdknzrhgh")

# License key to use to download GeoLite2 country blocks database
# NOTE:    See 'https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/' for details
# Format:  String
# Example: GL2_LICENSE="1a2b3c4d5e6f7g8h"
# Default: GL2_LICENSE=""
GL2_LICENSE=""

# List of countries to block using GeoLite2 country blocks
# NOTE:    For a list of country names, download ZIP archive from URL below and inspect file 'geolite2-country-locations-en.csv':
#          'https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=<your-gl2-license-key>&suffix=zip'
# Format:  Bash array of strings
# Example: GL2_COUNTRIES=("Tomorrowland" "Middle-earth")
# Default: GL2_COUNTRIES=()
GL2_COUNTRIES=()

# IP protocol versions to process for GeoLite2 country blocks
# Format:  Bash array of strings
# Example: GL2_IPVERS=("IPv4") | GL2_IPVERS=("IPv6") | GL2_IPVERS=("IPv4" "IPv6")
# Default: GL2_IPVERS=("IPv4")
GL2_IPVERS=("IPv4")

# Path to install final output file to (folder + filename)
# NOTE:    ${SCRIPT_DIR}: directory of 'ipfilter.sh' script, ${SCRIPT_NAME}: filename of 'ipfilter.sh' script without extension
#          Correct file extension will be determined automatically, there is no need to modify this when changing COMP_TYPE
# Format:  String
# Example: INSTALL_DST="/tmp/blocklist.p2p"
# Default: INSTALL_DST="${SCRIPT_DIR}/${SCRIPT_NAME}.p2p"
INSTALL_DST="${SCRIPT_DIR}/${SCRIPT_NAME}.p2p"

# Type of compression to apply to final output file (in-place)
# NOTE:    Correct file extension will be determined automatically, there is no need to modify INSTALL_DST when changing this
# Format:  String
# Example: COMP_TYPE="none" | COMP_TYPE="gzip" | COMP_TYPE="bzip2" | COMP_TYPE="xz" | COMP_TYPE="zip"
# Default: COMP_TYPE="none"
COMP_TYPE="none"
```

## Subscriptions
Using the [I-Blocklist](https://www.iblocklist.com/) feature does not require a subscription, as most of the provided lists are free to download. There are a few lists that are only available to subscribers, though. Non-free lists are currently untested - please open an [Issue](https://github.com/fonic/ipfilter/issues) if you have a subscription and want to help improving support for these lists.

Using the [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) feature requires a license key which can be obtained *free of charge* after [signing up](https://www.maxmind.com/en/geolite2/signup) (refer to [this blog post](https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/) for details).

## Usage
As settings are configured via `ipfilter.conf`, the script intentionally features only few command line options:
```
--==[ IP Filter Updater & Generator ]==--

Usage: ipfilter.sh [OPTIONS]

Options:
  -n, --notify       Send desktop notification to inform user
                     about success/failure (useful for cron)
  -k, --keep-temp    Do not remove temporary folder on exit
                     (useful for debugging)
  -h, --help         Display this help message
```

In most cases it should be sufficient to run the script without supplying any options:
```
$ cd ipfilter-vX.Y
$ ./ipfilter.sh
```

When running _non-interactively_ (e.g. via cron), you might want to supply option `-n/--notify` to send desktop notifications informing you about success/failure.

Note that *root privileges* are generally **not** required. Just make sure the configured `INSTALL_DST` points to a location writeable by the user running the script. The same applies to `LOG_FILE` if logging is enabled.

##

_Last updated: 08/09/23_
