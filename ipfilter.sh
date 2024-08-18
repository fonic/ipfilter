#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#                                                                              -
#  IP Filter Updater & Generator (ipfilter)                                    -
#                                                                              -
#  Created by Fonic (https://github.com/fonic)                                 -
#  Date: 04/15/19 - 08/18/24                                                   -
#                                                                              -
# ------------------------------------------------------------------------------

# --------------------------------------
#                                      -
#  Early checks                        -
#                                      -
# --------------------------------------

# Check if running Bash and required version (NOTE: this check does not rely
# on any Bashism to make sure it's guaranteed to work on any POSIX shell)
if [ -z "${BASH_VERSION}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
	echo "This script requires Bash >= 4.0 to run."
	exit 1
fi


# --------------------------------------
#                                      -
#  Configuration                       -
#                                      -
# --------------------------------------

# Determine platform / OS type (NOTE: this info is used a lot throughout the
# script, thus it makes sense to preprocess/normalize it here to simplify ifs
# down the road; https://github.com/microsoft/WSL/issues/423)
case "${OSTYPE,,}" in
	"linux"*) uname="$(uname -r)"; [[ "${uname,,}" == *"microsoft"* ]] && PLATFORM="linux-wsl" || PLATFORM="linux"; ;;
	"darwin"*) PLATFORM="macos"; ;;
	"freebsd"*) PLATFORM="freebsd"; ;;
	"msys"*) PLATFORM="windows-msys"; ;;
	"cygwin"*) PLATFORM="windows-cygwin"; ;;
	*) PLATFORM="${OSTYPE,,}"
esac

# Script info (NOTE: handle special case for SCRIPT_DIR to fix issue #5;
# running the script from '/' results in SCRIPT_CONFIG='//ipfilter.conf',
# which is a valid path on all OSes / runtime environments except Git for
# Windows; same for INSTALL_DST below; macOS has no 'realpath' and there's
# no simple workaround for that, so just don't support/use it)
SCRIPT_TITLE="IP Filter Updater & Generator (ipfilter)"
SCRIPT_VERSION="4.5 (08/18/24)"
if [[ "${PLATFORM}" == "macos" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
	SCRIPT_DIR="$(dirname "$(realpath "$0")")"
fi
[[ "${SCRIPT_DIR}" == "/" ]] && SCRIPT_DIR=""
if [[ "${PLATFORM}" == "macos" ]]; then
	SCRIPT_FILE="$(basename "$0")"
else
	SCRIPT_FILE="$(basename "$(realpath "$0")")"
fi
SCRIPT_NAME="${SCRIPT_FILE%.*}"
SCRIPT_CONFIG="${SCRIPT_DIR}/${SCRIPT_NAME}.conf"

# Notification settings
NOTIFY_USER="false"

# Temporary directory (NOTE: TEMP_DIR needs to be global to be accessible
# for exit trap handler; value is set using mktemp during initialization)
TEMP_DIR=""
KEEP_TEMP="false"

# Verbose output
VERBOSE_OUTPUT="false"

# Logging settings
LOG_STARTED="$(date)"
LOG_TEMP="ipfilter.log"
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.log"
LOG_MODE="append"
LOG_COLORS="false"

# Curl / wget options (NOTE: 'curl --retry n-1' equals 'wget --tries=n')
CURL_OPTS=("--fail" "--location" "--silent" "--show-error" "--retry" "2" "--connect-timeout" "60")
WGET_OPTS=("--no-verbose" "--tries=3" "--timeout=60")

# I-BlockList settings (https://www.iblocklist.com/lists)
IBL_URL="https://list.iblocklist.com/?list=%s&fileformat=p2p&archiveformat=gz&username=%s&pin=%s"
IBL_FIN1="iblocklist-%s.p2p.gz"
IBL_FIN2="iblocklist-%s.p2p"
IBL_FOUT="iblocklist-merged.p2p"
IBL_USER=""
IBL_PIN=""
declare -A IBL_LISTS=(["level1"]="ydxerpxkpcfqjaybcssw" ["level2"]="gyisgnzbhppbvsphucsw" ["level3"]="uwnukjqktoggdknzrhgh")

# GeoLite2 settings (https://dev.maxmind.com/geoip/geoip2/geolite2)
GL2_URL="https://download.maxmind.com/geoip/databases/GeoLite2-Country-CSV/download?suffix=zip"
GL2_FIN1="geolite2-country-database.zip"
GL2_FIN2="geolite2-country-locations-en.csv"
GL2_FIN3="geolite2-country-blocks-%s.csv"
GL2_FOUT1="geolite2-%s.p2p"
GL2_FOUT2="geolite2-merged.p2p"
GL2_ID=""
GL2_LICENSE=""
GL2_COUNTRIES=()
GL2_IPVERS=("IPv4")

# Final file, install destination, compression type
FINAL_FILE="ipfilter.p2p"
INSTALL_DST="${SCRIPT_DIR}/${SCRIPT_NAME}.p2p"
COMP_TYPE="none"


# --------------------------------------
#                                      -
#  Functions                           -
#                                      -
# --------------------------------------

# Set window title [$*: title]
function set_window_title() {
	echo -en "\e]0;$*\a"
}

# Print normal message [$*: message]
function print_normal() {
	echo -e "$*"
}

# Print hilite message [$*: message]
function print_hilite() {
	echo -e "\e[1m$*\e[0m"
}

# Print good message [$*: message]
function print_good() {
	echo -e "\e[1;32m$*\e[0m"
}

# Print warn message [$*: message]
function print_warn() {
	echo -e "\e[1;33m$*\e[0m"
}

# Print error message [$*: message]
function print_error() {
	echo -e "\e[1;31m$*\e[0m"
}

# Check if item is element of array [$1: item, $2..$n: array elements]
function in_array() {
	local item="$1"; shift
	while [[ -n "${1+set}" ]]; do
		[[ "${1}" == "${item}" ]] && return 0
		shift
	done
	return 1
}

# Check if command is available [$1: command]
function is_cmd_avail() {
	command -v "$1" &>/dev/null
	return $?
}

# Download file [$1: URL, $2: destination path, $3: user (optional), $4: password
# (optional)]
function download_file() {
	if is_cmd_avail "curl"; then
		local curl_opts=("${CURL_OPTS[@]}")
		[[ -n "${3+set}" && -n "${4+set}" ]] && curl_opts+=("--user" "$3:$4")
		curl "${curl_opts[@]}" "$1" --output "$2"
		return $?
	elif is_cmd_avail "wget"; then
		local wget_opts=("${WGET_OPTS[@]}")
		[[ -n "${3+set}" && -n "${4+set}" ]] && wget_opts+=("--user=$3" "--password=$4")
		wget "${wget_opts[@]}" "$1" --output-document="$2"
		return $?
	else
		print_error "Unable to download '$1': no download command available"
		return 1
	fi
}

# Verbose print line count of file [$1: file] (NOTE: using wc + awk to suppress
# extra spaces printed by wc on some OSes)
function vprint_linecount() {
	[[ "${VERBOSE_OUTPUT}" == "false" ]] && return 0
	print_normal "${1##*/}: $(cat "${1}" | wc -l | awk '{ print $1 }') lines"
}

# Verbose print transfer of item from source(s) to destination [$1: destination,
# $2..n: source(s)] (NOTE: strip temporary directory from source(s)/destination
# for cleaner output)
function vprint_transfer() {
	[[ "${VERBOSE_OUTPUT}" == "false" ]] && return 0

	local dst="$1"
	[[ "${dst}" == "${TEMP_DIR}"* ]] && dst="${dst##*/}"
	shift

	local src="" arg
	for arg; do
		[[ "${arg}" == "${TEMP_DIR}"* ]] && arg="${arg##*/}"
		src+="${arg}, "
	done
	src="${src::-2}"

	print_normal "${src} -> ${dst}"
}

# Send desktop notification [$1: type ('normal'/'error'), $2: application
# name, $3: message summary, $4: message body (optional)] (NOTE: '${4:-}'/
# '${DISPLAY:-}' is required to not throw errors if 'treat unset variables
# as errors' (set -u) is enabled)
function notify() {

	# Linux/FreeBSD: use notify-send to send notification (NOTE: this only
	# applies to *native* Linux; Linux on WSL is handled below instead)
	if [[ "${PLATFORM}" == "linux" || "${PLATFORM}" == "freebsd" ]]; then
		if ! is_cmd_avail "notify-send"; then
			print_error "Unable to send notification: command 'notify-send' not available"
			return 1
		fi

		# Translate type to notify-send's urgency
		local urgency
		[[ "$1" == "error" ]] && urgency="critical" || urgency="normal"

		# If script is run as root, try to determine user running desktop environment
		# and try to send notification using su (https://stackoverflow.com/a/49533938)
		if (( ${EUID} == 0 )); then
			local display=":$(ls /tmp/.X11-unix/* | sed 's|/tmp/.X11-unix/X||' | head -n 1)"
			local user="$(who | grep "(${display})" | awk '{ print $1 }' | head -n 1)"
			su "${user}" -c "DISPLAY=\"${display}\" notify-send --urgency=\"${urgency}\" --app-name=\"$2\" \"$3\" \"${4:-}\""
			return $?
		fi

		# If DISPLAY variable is not set or empty, try to determine its value and try
		# to send notification to that display (probably only works for the same user)
		if [[ -z "${DISPLAY:-}" ]]; then
			local display=":$(ls /tmp/.X11-unix/* | sed 's|/tmp/.X11-unix/X||' | head -n 1)"
			DISPLAY="${display}" notify-send --urgency="${urgency}" --app-name="$2" "$3" "${4:-}"
			return $?
		fi

		# Send notification normally
		notify-send --urgency="${urgency}" --app-name="$2" "$3" "${4:-}"
		return $?
	fi

	# macOS: use osascript to send notification
	# (https://code-maven.com/display-notification-from-the-mac-command-line)
	if [[ "${PLATFORM}" == "macos" ]]; then
		if ! is_cmd_avail "osascript"; then
			print_error "Unable to send notification: command 'osascript' not available"
			return 1
		fi
		osascript -e "display notification \"${4:-}\" with title \"$2\" subtitle \"$3\""
		return $?
	fi

	# Windows and Linux on WSL: use powershell to send notification
	# (https://stackoverflow.com/a/45902432)
	if [[ "${PLATFORM}" == "windows"* || "${PLATFORM}" == "linux-wsl" ]]; then
		if ! is_cmd_avail "powershell.exe"; then
			print_error "Unable to send notification: command 'powershell.exe' not available"
			return 1
		fi
		local icon message timeout=10
		[[ "$1" == "error" ]] && icon="error" || icon="information"
		[[ -z "${4+set}" ]] && message="$3" || message="$3 $4"
		powershell.exe -c "[reflection.assembly]::loadwithpartialname('System.Windows.Forms'); [reflection.assembly]::loadwithpartialname('System.Drawing'); \$notify = new-object system.windows.forms.notifyicon; \$notify.icon = [System.Drawing.SystemIcons]::${icon}; \$notify.visible = \$true; \$notify.showballoontip(${timeout}, '$2', '${message}', [system.windows.forms.tooltipicon]::None)" &>/dev/null
		return $?
	fi

	# Platform / OS type not supported
	print_error "Unable to send notification: platform / OS type '${PLATFORM}' not supported"
	return 1

}

# Handler for error trap [no arguments] (NOTE: redirection to stderr is
# important for this to work inside of pipes / process substitution;
# sending TERM signal to ourselves to realiably exit even if trap occurs
# in subshell)
function error_trap() {
	print_error "An error occured while updating, aborting." >&2
	[[ "${NOTIFY_USER}" == "true" ]] && notify "error" "${SCRIPT_TITLE}" "An error occurred while updating." "Please check log/output for errors."
	kill -s TERM $$
	exit 1
}

# Handler for exit trap [no arguments] (NOTE: disabling exit on error /
# error trap to make sure entire handler is executed even if errors occur;
# restore of previously backed up stdout/stderr explicitely ends logging)
function exit_trap() {
	set +e; trap - ERR
	if [[ -n "${TEMP_DIR}" && -e "${TEMP_DIR}/${LOG_TEMP}" ]]; then
		exec 1>&3 3>&-; exec 2>&4 4>&-
		if [[ -n "${LOG_FILE}" && "${LOG_MODE}" != "disabled" ]]; then
			print_hilite "Saving log file..."
			[[ "${LOG_MODE}" == "overwrite" ]] && > "${LOG_FILE}"
			echo "--------------- Started: ${LOG_STARTED} ---------------" >> "${LOG_FILE}"
			if [[ "${LOG_COLORS}" == "true" ]]; then
				cat "${TEMP_DIR}/${LOG_TEMP}" >> "${LOG_FILE}"
			else
				cat "${TEMP_DIR}/${LOG_TEMP}" | sed 's/[[:cntrl:]]\[[^a-zA-Z]*[a-zA-Z]//g' >> "${LOG_FILE}"
			fi
			echo "--------------- Ended: $(date) ---------------" >> "${LOG_FILE}"
			#[[ "${LOG_MODE}" == "append" ]] && echo >> "${LOG_FILE}"
		fi
	fi
	if [[ -n "${TEMP_DIR}" && -e "${TEMP_DIR}" ]]; then
		if [[ "${KEEP_TEMP}" == "true" ]]; then
			print_hilite "Keeping temporary files in '${TEMP_DIR}'."
		else
			print_hilite "Removing temporary folder..."
			rm -rf "${TEMP_DIR}"
		fi
	fi
	print_normal
}

# Split string into array [$1: string, $2: separator (single character), $3: name of target array variable]
function split_string() {
	local _string="$1" _sepchr="$2"
	local -n _arrref="$3"; _arrref=()
	local _i _char="" _escape=0 _quote=0 _item=""
	for (( _i=0; _i < ${#_string}; _i++ )); do
		_char="${_string:_i:1}"
		if (( ${_escape} == 1 )); then
			_item+="${_char}"
			_escape=0
			continue
		fi
		if [[ "${_char}" == "\\" ]]; then
			_escape=1
			continue
		fi
		if [[ "${_char}" == "\"" ]]; then
			(( ${_quote} == 0 )) && _quote=1 || _quote=0
			continue
		fi
		if [[ "${_char}" == "${_sepchr}" ]] && (( ${_quote} == 0 )); then
			_arrref+=("${_item}")
			_item=""
			continue
		fi
		_item+="${_char}"
	done
	[[ "${_item}" != "" ]] && _arrref+=("${_item}")
}

# Convert CIDR to IP address range (IPv4) [$1: CIDR string, $2: target variable start IP string, $3: target variable end IP string]
function cidr_to_range_ipv4() {
	local _cidr="$1"
	local -n _sips="$2"
	local -n _eips="$3"
	local _nb _b1 _b2 _b3 _b4 _ip _sipd _eipd

	# Split CIDR into network bits + 4 bytes IP, calculate IP as 32 bit decimal
	_nb="${_cidr#*/}"; _cidr=${_cidr%/*}
	_b1="${_cidr%%.*}"; _cidr=${_cidr#*.}
	_b2="${_cidr%%.*}"; _cidr=${_cidr#*.}
	_b3="${_cidr%%.*}"; _cidr=${_cidr#*.}
	_b4="${_cidr}"
	_ip=$(((10#${_b1} << 24) + (10#${_b2} << 16) + (10#${_b3} << 8) + 10#${_b4}))

	# Calculate and return start/end IP decimal
	_sipd=$((_ip & (0xFFFFFFFF << (32 - 10#${_nb}))))
	_eipd=$((_ip | (0xFFFFFFFF >> 10#${_nb})))

	# Generate and return start/end IP string
	_sips="$((_sipd >> 24)).$(((_sipd >> 16) & 0xFF)).$(((_sipd >> 8) & 0xFF)).$((_sipd & 0xFF))"
	_eips="$((_eipd >> 24)).$(((_eipd >> 16) & 0xFF)).$(((_eipd >> 8) & 0xFF)).$((_eipd & 0xFF))"
}

# Convert CIDR to IP address range (IPv6) [$1: CIDR string, $2: target variable start IP string, $3: target variable end IP string]
function cidr_to_range_ipv6() {
	local _cidr="$1"
	local -n _sips="$2"; _sips=""
	local -n _eips="$3"; _eips=""
	local _ip _nb _exp _i _w _wb

	# Split CIDR into IP and network bits, convert network bits to decimal
	_ip="${_cidr%/*}"
	_nb=$((10#${_cidr#*/}))

	# Expand '::' in IP if present
	_exp=":::::::::"; _exp="${_exp/${_ip//[^:]}}"; _exp="${_exp//:/:0}"
	_ip="${_ip//::/${_exp}}"

	# Process eight 16 bit words of IP
	for ((_i=0; _i < 8; _i++)) {
		# Fetch current word, convert from hex to decimal, advance to next word
		_w=$((16#${_ip%%:*}))
		_ip="${_ip#*:}"

		# Determine number of network bits affecting current word, calculate remaining bits
		(( ${_nb} > 16 )) && { _wb=16; _nb=$((_nb-16)); } || { _wb=${_nb}; _nb=0; }

		# Calculate start word, add as lowercase padded hex to start IP string
		printf -v _sips "%s%04x:" "${_sips}" "$((_w & (0xFFFF << (16-_wb))))"

		# Calculate end word, add as lowercase padded hex to end IP string
		printf -v _eips "%s%04x:" "${_eips}" "$((_w | (0xFFFF >> _wb)))"
	}

	# Remove trailing ':' from start/end IP string
	_sips="${_sips:: -1}"; _eips="${_eips:: -1}"
}


# --------------------------------------
#                                      -
#  Initialization                      -
#                                      -
# --------------------------------------

# Set up error handling (NOTE: elaborate approach to reliably handle errors
# occurring in subshells / process substitutions; set: '-e' exit on error,
# '-u' treat unset variables as errors, '-E' subshells / process substitutions
# inherit error trap of parent, '-o pipefail' return value of pipeline is
# return value of last command; see https://stackoverflow.com/a/9894126)
set -euE -o pipefail
trap "exit 1" TERM; trap "error_trap" ERR

# Set up traps for interrupt and exit
trap "trap - ERR; echo -en \"\r\e[2K\"" INT
trap "exit_trap" EXIT

# Set window title, print title
set_window_title "${SCRIPT_TITLE}"
print_normal
print_hilite "--==[ ${SCRIPT_TITLE} v${SCRIPT_VERSION} ]==--"
print_normal

# Provide help if requested (NOTE: do this separately so that help shows up
# whenever -h/--help is present, even if there are further valid / invalid
# options present)
if in_array "-h" "$@" || in_array "--help" "$@"; then
	print_normal "Usage: ${SCRIPT_FILE} [OPTIONS]"
	print_normal
	print_normal "Options:"
	print_normal "  -n, --notify       Send desktop notification to inform user"
	print_normal "                     about success/failure (useful for cron)"
	print_normal "  -k, --keep-temp    Do not remove temporary folder on exit"
	print_normal "                     (useful for debugging)"
	print_normal "  -h, --help         Display this help message"
	exit 0
fi

# Parse command line
result=0
for arg in "$@"; do
	case "${arg}" in
		"-n"|"--notify") NOTIFY_USER="true"; ;;
		"-k"|"--keep-temp") KEEP_TEMP="true"; ;;
		*) print_error "Invalid option '${arg}'"; result=1; ;;
	esac
done
if (( ${result} != 0 )); then
	print_normal
	print_error "Invalid command line. Use '--help' to display usage information."
	exit 2
fi

# Check and source configuration file
if [[ ! -f "${SCRIPT_CONFIG}" ]]; then
	print_error "Configuration file '${SCRIPT_CONFIG}' does not exist, aborting."
	exit 1
fi
if ! source "${SCRIPT_CONFIG}"; then
	print_error "Failed to read configuration file '${SCRIPT_CONFIG}', aborting."
	exit 1
fi

# Check and normalize configuration settings
result=0
case "${VERBOSE_OUTPUT,,}" in
	"true"|"false") VERBOSE_OUTPUT="${VERBOSE_OUTPUT,,}"; ;;
	*) print_error "Invalid verbose output setting '${VERBOSE_OUTPUT}'"; result=1; ;;
esac
case "${LOG_MODE,,}" in
	"disabled"|"overwrite"|"append") LOG_MODE="${LOG_MODE,,}"; ;;
	*) print_error "Invalid log mode setting '${LOG_MODE}'"; result=1; ;;
esac
case "${LOG_COLORS,,}" in
	"true"|"false") LOG_COLORS="${LOG_COLORS,,}"; ;;
	*) print_error "Invalid log colors setting '${LOG_COLORS}'"; result=1; ;;
esac
for ((i=0; i < ${#GL2_IPVERS[@]}; i++)); do
	case "${GL2_IPVERS[i],,}" in
		"ipv4") GL2_IPVERS[i]="IPv4"; ;;
		"ipv6") GL2_IPVERS[i]="IPv6"; ;;
		*) print_error "Invalid Geolite2 IP version setting '${GL2_IPVERS[i]}'"; result=1; ;;
	esac
done
case "${COMP_TYPE,,}" in
	"none"|"gzip"|"bzip2"|"xz"|"zip") COMP_TYPE="${COMP_TYPE,,}"; ;;
	*) print_error "Invalid compression type setting '${COMP_TYPE}'"; result=1; ;;
esac
if (( ${result} != 0 )); then
	print_normal
	print_error "One or more configuration settings are invalid, please check configuration."
	exit 1
fi

# Check command availability (NOTE: do not check for coreutils like cat,
# sort, ..., only check for commands that usually have their own package)
result=0
commands=("awk" "grep" "gunzip" "sed" "unzip")
if [[ "${NOTIFY_USER}" == "true" ]]; then
	case "${PLATFORM}" in
		"linux") commands+=("notify-send"); ;;
		"macos") commands+=("osascript"); ;;
		"freebsd") commands+=("notify-send"); ;;
		# Although 'powershell' works fine on Cygwin/MSYS2/PortableGit, for Linux on
		# WSL 'powershell.exe' is required and more fitting for Windows environments
		# anyway
		"windows"*|"linux-wsl") commands+=("powershell.exe"); ;;
		*) print_error "Option '-n/--notify' is not supported on platform / OS type '${PLATFORM}'"; result=1; ;;
	esac
fi
case "${COMP_TYPE}" in
	"gzip") commands+=("gzip"); ;;
	"bzip2") commands+=("bzip2"); ;;
	"xz") commands+=("xz"); ;;
	"zip") commands+=("zip"); ;;
esac
for cmd in "${commands[@]}"; do
	if ! is_cmd_avail "${cmd}"; then
		print_error "Command '${cmd}' is not available"
		result=1
	fi
done
if ! is_cmd_avail "curl" && ! is_cmd_avail "wget"; then
	print_error "Neither command 'curl' nor 'wget' is available"
	result=1
fi
if (( ${result} != 0 )); then
	print_normal
	print_error "One or more required commands are unavailable, please check dependencies."
	exit 1
fi

# Create temporary folder (NOTE: mktemp call simplified for multi-platform
# use; cleanup is handled by exit_trap)
print_hilite "Creating temporary folder..."
TEMP_DIR="$(mktemp -d "/tmp/${SCRIPT_NAME}.XXXXXXXXXX")"
[[ "${KEEP_TEMP}" == "true" ]] && print_normal "Temporary folder: ${TEMP_DIR}"

# Set up logging (NOTE: log is written to temporary dir/file first and then
# processed/finalized on exit by exit_trap; backups of stdout/stderr allow
# for explicitely ending logging by restoring)
if [[ "${LOG_MODE}" != "disabled" ]]; then
	print_hilite "Setting up logging..."
	exec 3>&1 4>&2
	exec > >(tee -i "${TEMP_DIR}/${LOG_TEMP}") 2>&1
fi


# --------------------------------------
#                                      -
#  I-BlockList                         -
#                                      -
# --------------------------------------

> "${TEMP_DIR}/${IBL_FOUT}"
if (( ${#IBL_LISTS[@]} > 0 )) && [[ "${IBL_USER}" != "" && "${IBL_PIN}" != "" ]]; then

	# Download blocklists (NOTE: using 'src2' to obfuscate username and PIN
	# in console/log output)
	print_hilite "Downloading I-BlockList blocklists..."
	for list in "${!IBL_LISTS[@]}"; do
		print_normal "Downloading blocklist '${list}'..."
		printf -v src "${IBL_URL}" "${IBL_LISTS["${list}"]}" "${IBL_USER}" "${IBL_PIN}"
		printf -v src2 "${IBL_URL}" "${IBL_LISTS["${list}"]}" "xxx" "xxx"
		printf -v dst "${TEMP_DIR}/${IBL_FIN1}" "${list}"
		vprint_transfer "${dst}" "${src2}"
		download_file "${src}" "${dst}"
	done

	# Decompress blocklists
	print_hilite "Decompressing I-BlockList blocklists..."
	for list in "${!IBL_LISTS[@]}"; do
		print_normal "Decompressing blocklist '${list}'..."
		printf -v src "${TEMP_DIR}/${IBL_FIN1}" "${list}"
		printf -v dst "${TEMP_DIR}/${IBL_FIN2}" "${list}"
		vprint_transfer "${dst}" "${src}"
		gunzip < "${src}" > "${dst}"
		vprint_linecount "${dst}"
	done

	# Merge blocklists (NOTE: version sort works well for IPv4; for IPv6,
	# alphanumerical sort is required; since sort is required for uniq and
	# IPv4 is dominant anyway, version sort is being used; sed command is
	# used to remove empty and comment lines)
	print_hilite "Merging I-BlockList blocklists..."
	readarray -t src < <(printf "${TEMP_DIR}/${IBL_FIN2}\n" "${!IBL_LISTS[@]}")
	dst="${TEMP_DIR}/${IBL_FOUT}"
	vprint_transfer "${dst}" "${src[@]}"
	cat "${src[@]}" | sort --version-sort | uniq > "${dst}"
	if [[ "${PLATFORM}" == "macos" || "${PLATFORM}" == "freebsd" ]]; then
		sed -i "" -e '/^$/d' -e '/^#.*$/d' "${dst}"
	else
		sed --in-place --expression='/^$/d' --expression='/^#.*$/d' "${dst}"
	fi
	vprint_linecount "${dst}"

fi


# --------------------------------------
#                                      -
#  GeoLite2                            -
#                                      -
# --------------------------------------

> "${TEMP_DIR}/${GL2_FOUT2}"
if (( ${#GL2_COUNTRIES[@]} > 0 )) && [[ "${GL2_ID}" != "" && "${GL2_LICENSE}" != "" ]]; then

	# Download database
	print_hilite "Downloading GeoLite2 database..."
	printf -v src "${GL2_URL}"
	dst="${TEMP_DIR}/${GL2_FIN1}"
	vprint_transfer "${dst}" "${src}"
	download_file "${src}" "${dst}" "${GL2_ID}" "${GL2_LICENSE}"

	# Extract database (NOTE: on Windows, unzip '*.csv' does not work while
	# unzip '**.csv' does; no idea why exactly, but it works, so let it be)
	print_hilite "Extracting GeoLite2 database..."
	src="${TEMP_DIR}/${GL2_FIN1}"
	dst="${TEMP_DIR}"
	vprint_transfer "temporary directory" "${src}"
	if [[ "${PLATFORM}" == "windows"* ]]; then
		unzip -q -o -j -LL "${src}" '**.csv' -d "${dst}"
	else
		unzip -q -o -j -LL "${src}" '*.csv' -d "${dst}"
	fi
	[[ "${VERBOSE_OUTPUT}" == "true" ]] && print_normal "Extracted $(ls -l "${dst}"/*.csv | wc -l | awk '{ print $1 }') files"

	# Parse country locations, generate dict country names -> ids (NOTE: using
	# split_string here as it deals perfectly with quotes, separators in items
	# etc.; performance is not relevant here)
	print_hilite "Parsing GeoLite2 countries..."
	src="${TEMP_DIR}/${GL2_FIN2}"
	declare -A country_ids
	while read -r line; do
		split_string "${line}" "," array
		(( ${#array[@]} != 7 )) && { print_error "Skipping invalid line: ${line}" >&2; continue; }
		geoname_id="${array[0]}"
		continent_name="${array[3]}"
		country_name="${array[5]}"
		if [[ "${country_name}" != "" ]]; then
			country_ids["${country_name,,}"]="${geoname_id}"
		else
			country_ids["${continent_name,,}"]="${geoname_id}"
		fi
	done < <(tail -q -n +2 "${src}")
	[[ "${VERBOSE_OUTPUT}" == "true" ]] && print_normal "Found ${#country_ids[@]} countries"

	# Parse country blocks, generate country blocklists (NOTE: most, probably
	# only performance-critical part of script; awk call simplified for multi-
	# platform use)
	print_hilite "Generating GeoLite2 blocklists..."
	countries=()
	for country in "${GL2_COUNTRIES[@]}"; do
		in_array "${country,,}" "${!country_ids[@]}" || { print_warn "Skipping invalid country '${country}' in setting GL2_COUNTRIES"; continue; }
		print_normal "Generating blocklist for country '${country}'..."
		countries+=("${country}")
		printf -v dst "${TEMP_DIR}/${GL2_FOUT1}" "${country,,}"
		> "${dst}"
		for ipv in "${GL2_IPVERS[@]}"; do
			printf -v src "${TEMP_DIR}/${GL2_FIN3}" "${ipv,,}"
			[[ "${ipv,,}" == "ipv4" ]] && sort_opts="--version-sort" || sort_opts=""
			grep --no-filename "${country_ids["${country,,}"]}" "${src}" | awk -F ',' '{ print $1 }' | \
				while read -r cidr; do
					cidr_to_range_${ipv,,} "${cidr}" sips eips
					printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}"
				done | sort ${sort_opts} | uniq >> "${dst}"
		done
		vprint_linecount "${dst}"
	done

	# Merge blocklists (NOTE: version sort works well for IPv4; for IPv6,
	# alphanumerical sort is required; since sort is required for uniq and
	# IPv4 is dominant anyway, version sort is being used; sed command is
	# used to remove empty and comment lines)
	print_hilite "Merging GeoLite2 blocklists..."
	dst="${TEMP_DIR}/${GL2_FOUT2}"
	> "${dst}"
	if (( ${#countries[@]} > 0 )); then
		readarray -t src < <(printf "${TEMP_DIR}/${GL2_FOUT1}\n" "${countries[@],,}")
		vprint_transfer "${dst}" "${src[@]}"
		cat "${src[@]}" | sort --version-sort | uniq > "${dst}"
		if [[ "${PLATFORM}" == "macos" || "${PLATFORM}" == "freebsd" ]]; then
			sed -i "" -e '/^$/d' -e '/^#.*$/d' "${dst}"
		else
			sed --in-place --expression='/^$/d' --expression='/^#.*$/d' "${dst}"
		fi
	fi
	vprint_linecount "${dst}"

fi


# --------------------------------------
#                                      -
#  Finalization                        -
#                                      -
# --------------------------------------

# Merge I-BlockList and GeoLite2 blocklists
print_hilite "Merging I-BlockList and GeoLite2 blocklists..."
readarray -t src < <(printf "${TEMP_DIR}/%s\n" "${IBL_FOUT}" "${GL2_FOUT2}")
dst="${TEMP_DIR}/${FINAL_FILE}"
vprint_transfer "${dst}" "${src[@]}"
cat "${src[@]}" > "${dst}"
vprint_linecount "${dst}"

# Install final file to specified destination
print_hilite "Installing final IP filter file..."
src="${TEMP_DIR}/${FINAL_FILE}"
dst="${INSTALL_DST}"
vprint_transfer "${dst}" "${src}"
cp "${src}" "${dst}"

# Compress installed file in-place (NOTE: using '<cmd> -c "${src}" > "${dst}"'
# for gzip/bzip2/xz to overwrite existing destination file without having to
# use option '--force' which has other, potentially undesired side effects; zip
# by default updates existing archives, thus using output to stdout + redirect
# to create a fresh archive each time)
if [[ "${COMP_TYPE}" != "none" ]]; then
	print_hilite "Compressing installed file in-place..."
	src="${INSTALL_DST}"
	case "${COMP_TYPE}" in
		"gzip") dst="${src}.gz"; gzip -c "${src}" > "${dst}"; ;;
		"bzip2") dst="${src}.bz2"; bzip2 -c "${src}" > "${dst}"; ;;
		"xz") dst="${src}.xz"; xz -c "${src}" > "${dst}"; ;;
		"zip") dst="${src%.*}.zip"; zip -q -j - "${src}" > "${dst}"; ;;
	esac
	rm "${src}"
	vprint_transfer "${dst}" "${src}"
fi

# Update successfully completed
print_good "IP filter successfully updated."
[[ "${NOTIFY_USER}" == "true" ]] && notify "normal" "${SCRIPT_TITLE}" "IP filter successfully updated."
exit 0
