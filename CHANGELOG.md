## Changelog for v4.3 release

Changes:
- added `ipfilter.service` and `ipfilter.timer` for system service setup (Linux with systemd only)
- added instructions for system service setup to `README.md`
- overhauled `ipfilter.conf` (comments only, no changes to configuration items)
- split `SCREENSHOT.png` into `SCREENSHOT1.png` and `SCREENSHOT2.png` (GitHub only)
- renamed `Windows Runtime Environments.md` to `WINDOWS.md` (KISS)
- applied other minor changes to `README.md` (URLs, wording, formatting)

## Changelog for v4.2 release

Changes:
- applied minor changes to console and log file output
- added comment regarding GeoLite2 license to configuration
- added screenshot with sample output (GitHub only)
- updated and restructured `README.md`

## Changelog for v4.1 release

Changes:
- obfuscate GeoLite2 license key in console/log output (to prevent leaking sensitive information via logs)
- overhauled `ipfilter.conf`: enabled default settings, extended comments, various minor changes
- overhauled `README.md`: added default configuration, added usage information, merged sections *Download* and *Installation*, various minor changes
- updated instructions for Windows users in `Windows Runtime Environments.md`: simplified WSL installation, updated URLs, various minor changes
- added `CHANGELOG.md`

## Changelog for v4.0 release

Changes:
- added verbose output feature (optional, configurable)
- added logging feature (optional, configurable)
- improved and simplified OS/platform detection and handling
- improved configuration settings verification/normalization
- applied various minor changes and improvements
- refactored code and comments

GitHub-only changes (not part of release):
- added test suite script
- added I-Blocklist scraper script
- added hints document for Windows runtime environments
- updated `README.md`

## Changelog for v3.1 release

Changes:
- fixed bug regarding overwriting existing compressed output files (issue #6)
- added support for *xz* compression of output file

## Changelog for v3.0 release

Changes:
- added support for _Cygwin_, _MSYS2_ and _Linux on Windows Subsystem for Linux (WSL)_
- improved/reworked notifications
- uses `realpath` to determine actual folder and filename of script on all platforms except macOS; script now works as expected when being run via symlink
- informs user and aborts if configuration file could not be read/located (related to issue #5)
- implemented fix for issue #5; script now works as expected when being run from `/` on _Git for Windows_
- applied additional minor changes (comments, code improvements, code formatting, console prints, command line arguments)
- updated `README.md`

## Changelog for v2.1 release

Changes:
- changed some comments in script
- changed some comments in config
- updated `README.md`

## Changelog for v2.0 release

Changes:
- added support for compression of final output file (configuration item `COMP_TYPE`)
- changed download utility priority: use curl as default, use wget as fallback (curl seems to be more common)
- changed long options to short options whenever it helps cross-platform use (e.g. `awk -F` works on all platforms while `awk --field-separator` doesn't)
- fixed selective extraction of *.csv files of GeoLite2 archive on Windows
- applied additional minor changes (comments, code improvements, code formatting)

## Changelog for v1.0 release

Initial release

##

_Last updated: 08/25/23_
