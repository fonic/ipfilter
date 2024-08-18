## Changelog for v4.5 release

Changes:
- Added support for downloading blocklists from I-BlockList as registered
  user (by supplying username and PIN via configuration items `IBL_USER`
  and `IBL_PIN`). Fixes https://github.com/fonic/ipfilter/issues/8
- Obfuscate I-BlockList username and PIN in console/log output (to prevent
  leaking sensitive information via logs and/or when posting script output
  on GitHub)

## Changelog for v4.4 release

Changes:
- Updated GeoLite2 database download handling to account for _breaking_ API
  change [MaxMind](https://www.maxmind.com) will start enforcing on 05/01/24
  (new download URL and basic authentication using account ID + license; see
  [this link](https://dev.maxmind.com/geoip/release-notes/2024) for details)
- Applied additional minor changes (script, `README.md`, `CHANGELOG.md`)

## Changelog for v4.3 release

Changes:
- Added `ipfilter.service` and `ipfilter.timer` for system service setup (Linux with systemd only)
- Added instructions for system service setup to `README.md`
- Overhauled `ipfilter.conf` (comments only, no changes to configuration items)
- Split `SCREENSHOT.png` into `SCREENSHOT1.png` and `SCREENSHOT2.png` (GitHub only)
- Renamed `Windows Runtime Environments.md` to `WINDOWS.md` (KISS)
- Applied other minor changes to `README.md` (URLs, wording, formatting)

## Changelog for v4.2 release

Changes:
- Applied minor changes to console and log file output
- Added comment regarding GeoLite2 license to configuration
- Added screenshot with sample output (GitHub only)
- Updated and restructured `README.md`

## Changelog for v4.1 release

Changes:
- Obfuscate GeoLite2 license key in console/log output (to prevent leaking sensitive information via logs)
- Overhauled `ipfilter.conf`: enabled default settings, extended comments, various minor changes
- Overhauled `README.md`: added default configuration, added usage information, merged sections *Download* and *Installation*, various minor changes
- Updated instructions for Windows users in `Windows Runtime Environments.md`: simplified WSL installation, updated URLs, various minor changes
- Added `CHANGELOG.md`

## Changelog for v4.0 release

Changes:
- Added verbose output feature (optional, configurable)
- Added logging feature (optional, configurable)
- Improved and simplified OS/platform detection and handling
- Improved configuration settings verification/normalization
- Applied various minor changes and improvements
- Refactored code and comments

GitHub-only changes (not part of release):
- Added test suite script
- Added I-BlockList scraper script
- Added hints document for Windows runtime environments
- Updated `README.md`

## Changelog for v3.1 release

Changes:
- Fixed bug regarding overwriting existing compressed output files (issue #6)
- Added support for _xz_ compression of output file

## Changelog for v3.0 release

Changes:
- Added support for _Cygwin_, _MSYS2_ and _Linux on Windows Subsystem for Linux (WSL)_
- Improved/reworked notifications
- Uses `realpath` to determine actual folder and filename of script on all platforms except macOS; script now works as expected when being run via symlink
- Informs user and aborts if configuration file could not be read/located (related to issue #5)
- Implemented fix for issue #5; script now works as expected when being run from `/` on _Git for Windows_
- Applied additional minor changes (comments, code improvements, code formatting, console prints, command line arguments)
- Updated `README.md`

## Changelog for v2.1 release

Changes:
- Changed some comments in script
- Changed some comments in config
- Updated `README.md`

## Changelog for v2.0 release

Changes:
- Added support for compression of final output file (configuration item `COMP_TYPE`)
- Changed download utility priority: use curl as default, use wget as fallback (curl seems to be more common)
- Changed long options to short options whenever it helps cross-platform use (e.g. `awk -F` works on all platforms while `awk --field-separator` doesn't)
- Fixed selective extraction of *.csv files of GeoLite2 archive on Windows
- Applied additional minor changes (comments, code improvements, code formatting)

## Changelog for v1.0 release

Initial release.

##

_Last updated: 08/18/24_
