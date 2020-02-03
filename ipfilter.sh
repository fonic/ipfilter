#!/usr/bin/env bash

# -------------------------------------------------------------------------
#                                                                         -
#  IP Filter Updater & Generator                                          -
#                                                                         -
#  Created by Fonic (https://github.com/fonic)                            -
#  Date: 02/02/20                                                         -
#                                                                         -
# -------------------------------------------------------------------------

# --------------------------------------
#                                      -
#  Early checks                        -
#                                      -
# --------------------------------------

# Check Bash version
if [ -z "${BASH_VERSION}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
	echo "This script requires Bash >= 4.0 to run."
	exit 1
fi


# --------------------------------------
#                                      -
#  Configuration                       -
#                                      -
# --------------------------------------

# Script
SCRIPT_TITLE="IP Filter Updater & Generator"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_FILE="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_FILE%.*}"
SCRIPT_CONFIG="${SCRIPT_DIR}/${SCRIPT_NAME}.conf"

# Command line options
CMD_NOTIFY=0
CMD_KEEPTEMP=0

# Wget options
WGET_OPTS=("--quiet" "--tries=3" "--timeout=15")

# Curl options
CURL_OPTS=("--location" "--silent" "--show-error" "--retry" "2" "--connect-timeout" "15")

# I-BlockList (https://www.iblocklist.com/lists)
IBL_URL="https://list.iblocklist.com/?list=%s&fileformat=p2p&archiveformat=gz"
IBL_FIN1="iblocklist-%s.p2p.gz"
IBL_FIN2="iblocklist-%s.p2p"
IBL_FOUT="iblocklist-merged.p2p"
declare -A IBL_LISTS=(["level1"]="ydxerpxkpcfqjaybcssw" ["level2"]="gyisgnzbhppbvsphucsw" ["level3"]="uwnukjqktoggdknzrhgh")

# GeoLite2 (https://dev.maxmind.com/geoip/geoip2/geolite2)
GL2_URL="https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=%s&suffix=zip"
GL2_FIN1="geolite2-country-database.zip"
GL2_FIN2="geolite2-country-locations-en.csv"
GL2_FIN3="geolite2-country-blocks-%s.csv"
GL2_FOUT1="geolite2-%s.p2p"
GL2_FOUT2="geolite2-merged.p2p"
GL2_LICENSE=""
GL2_COUNTRIES=()
GL2_IPVERS=("IPv4")

# Final output file, install destination
FINAL_FILE="ipfilter.p2p"
INSTALL_DST="${SCRIPT_DIR}/${SCRIPT_NAME}.p2p"


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

# Download file [$1: URL, $2: destination path]
function download_file() {
	if is_cmd_avail "wget"; then
		wget "${WGET_OPTS[@]}" "$1" --output-document="$2"
		return $?
	elif is_cmd_avail "curl"; then
		curl "${CURL_OPTS[@]}" "$1" --output "$2"
		return $?
	else
		print_error "Unable to download '$1': neither command 'wget' nor 'curl' is available"
		false
		return 1
	fi
}

# Send desktop notification [$1: type ('info'/'error'), $2: application name, $3: message summary, $4: message body (optional)]
# NOTE: ${4:-} -> required for optional variable if check for unbound variables is enabled (set -u)
function notify() {
	# On macOS, we use osascript to send notifications
	# (https://code-maven.com/display-notification-from-the-mac-command-line)
	if [[ "${OSTYPE}" == "darwin"* ]]; then
		osascript -e "display notification \"${4:-}\" with title \"$2\" subtitle \"$3\""
		return $?
	fi

	# On Windows, we use powershell to send notifications
	# (https://stackoverflow.com/a/45902432)
	if [[ "${OSTYPE}" == "msys"* ]]; then
		local icon
		case "$1" in
			"error") icon="error"; ;;
			*)       icon="information"; ;;
		esac
		local timeout=10
		local message
		[[ -z "${4+set}" ]] && message="$3" || message="$3 $4"
		powershell -c "[reflection.assembly]::loadwithpartialname('System.Windows.Forms'); [reflection.assembly]::loadwithpartialname('System.Drawing'); \$notify = new-object system.windows.forms.notifyicon; \$notify.icon = [System.Drawing.SystemIcons]::${icon}; \$notify.visible = \$true; \$notify.showballoontip(${timeout}, '$2', '${message}', [system.windows.forms.tooltipicon]::None)" &>/dev/null
		return $?
	fi

	# Translate type to notify-send's urgency
	local urgency
	case "$1" in
		"error") urgency="critical"; ;;
		*)       urgency="normal"; ;;
	esac

	# If script is run as root, try to determine user running desktop environment
	# and try to send notification using su -> https://stackoverflow.com/a/49533938
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
}

# Handler for error trap [no arguments] (NOTE: redirection to stderr is
# important for this to work inside of pipes / process substitution;
# sending TERM signal to ourselves to realiably exit even if trap occurs
# in subshell)
function error_trap() {
	print_error "An error occured, aborting." >&2
	(( ${CMD_NOTIFY} == 1 )) && notify error "${SCRIPT_TITLE}" "An error occurred while updating." "Please check output for errors."
	kill -s TERM $$
	exit 1
}

# Split string into array [$1: string, $2: separator (single character), $3: name of target array variable]
function split_string() {
	local _string="$1" _sepchr="$2"
	local -n _arrref="$3"; _arrref=()
	local _i _char="" _escape=0 _quote=0 _item=""
	for (( _i=0; _i < ${#_string}; _i++ )); do
		_char="${_string:_i:1}"
		if (( ${_escape} == 1 )); then
			_item="${_item}${_char}"
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
			#[[ "${_item}" != "" ]] && _arrref+=("${_item}")
			_arrref+=("${_item}")
			_item=""
			continue
		fi
		_item="${_item}${_char}"
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

# Set extended shell options, set error trap (NOTE: elaborate approach to
# reliably exit even if an error occurs in subshell / process substitution
# -> https://stackoverflow.com/a/9894126)
set -eEou pipefail
trap "exit 1" TERM; trap "error_trap" ERR

# Set cosmetic traps
trap "trap - ERR; echo -en \"\r\e[2K\"" INT
trap "print_normal" EXIT

# Set window title, print title
set_window_title "${SCRIPT_TITLE}"
print_normal
print_hilite "--==[ ${SCRIPT_TITLE} ]==--"
print_normal

# Provide help if requested (NOTE: we do this separately so that help shows
# up whenever -h/--help is present, even if there are further valid/invalid
# options present)
if in_array "-h" "$@" || in_array "--help" "$@"; then
	print_normal "Usage: $(basename "$0") [OPTIONS]"
	print_normal
	print_normal "Options:"
	print_normal "  -n, --notify               Send desktop notification when done"
	print_normal "                             or an error occurred (for cron use)"
	print_normal "  -k, --keep-temp            Do not remove temporary folder when"
	print_normal "                             done (useful for debugging)"
	print_normal "  -h, --help                 Display this help message"
	exit 0
fi

# Parse command line
invalid=0
for arg in "$@"; do
	case "${arg}" in
		"-n"|"--notify")    CMD_NOTIFY=1; ;;
		"-k"|"--keep-temp") CMD_KEEPTEMP=1; ;;
		*)                  print_normal "Invalid option '${arg}'"; invalid=$((invalid + 1)); ;;
	esac
done
if (( ${invalid} > 0 )); then
	print_normal
	print_warn "Invalid command line. Use '--help' to display usage information."
	exit 2
fi

# Check command availability (NOTE: we do not check for coreutils like cat,
# sort, ..., we only check for commands that usually have their own package)
missing=0
commands=("awk" "grep" "gunzip" "sed" "unzip")
if (( ${CMD_NOTIFY} == 1 )); then
	if [[ "${OSTYPE}" == "darwin"* ]]; then
		commands+=("osascript")
	elif [[ "${OSTYPE}" == "msys"* ]]; then
		commands+=("powershell")
	else
		commands+=("notify-send")
	fi
fi
for cmd in "${commands[@]}"; do
	if ! is_cmd_avail "${cmd}"; then
		print_normal "Command '${cmd}' is not available"
		missing=$((missing + 1))
	fi
done
if ! is_cmd_avail "wget" && ! is_cmd_avail "curl"; then
	print_normal "Neither command 'wget' nor 'curl' is available"
	missing=$((missing + 1))
fi
if (( ${missing} > 0 )); then
	print_normal
	print_warn "One or more required commands are unavailable, please check dependencies."
	exit 1
fi

# Source configuration file if present
[[ -e "${SCRIPT_CONFIG}" ]] && source "${SCRIPT_CONFIG}"

# Create temporary folder, set cleanup trap (NOTE: replaces EXIT trap set
# above for cosmetic reasons)
print_hilite "Creating temporary folder..."
if [[ "${OSTYPE}" == "darwin"* || "${OSTYPE}" == "freebsd"* ]]; then
	tmpdir="$(mktemp -d "/tmp/${SCRIPT_NAME}.XXXXXXXXXX")"
else
	tmpdir="$(mktemp --directory --tmpdir=/tmp "${SCRIPT_NAME}.XXXXXXXXXX")"
fi
if (( ${CMD_KEEPTEMP} == 0 )); then
	trap "print_hilite \"Removing temporary folder...\"; rm -rf \"${tmpdir}\"; print_normal" EXIT
else
	trap "print_normal; print_hilite \"Keeping temporary files in '${tmpdir}'.\"; print_normal" EXIT
fi


# --------------------------------------
#                                      -
#  I-BlockList                         -
#                                      -
# --------------------------------------

if (( ${#IBL_LISTS[@]} > 0 )); then

	# Download blocklists
	print_hilite "Downloading I-BlockList blocklists..."
	for list in "${!IBL_LISTS[@]}"; do
		print_normal "Downloading I-BlockList blocklist '${list}'..."
		printf -v src "${IBL_URL}" "${IBL_LISTS["${list}"]}"
		printf -v dst "${tmpdir}/${IBL_FIN1}" "${list}"
		download_file "${src}" "${dst}"
	done

	# Decompress blocklists
	print_hilite "Decompressing I-BlockList blocklists..."
	for list in "${!IBL_LISTS[@]}"; do
		print_normal "Decompressing I-BlockList blocklist '${list}'..."
		printf -v src "${tmpdir}/${IBL_FIN1}" "${list}"
		printf -v dst "${tmpdir}/${IBL_FIN2}" "${list}"
		gunzip < "${src}" > "${dst}"
	done

	# Merge blocklists (NOTE: version sort works well for IPv4; for IPv6,
	# alphanumerical sort is required; since we have to sort for uniq and
	# IPv4 is dominant anyway, version sort is being used; sed command is
	# used to remove empty and comment lines)
	print_hilite "Merging I-BlockList blocklists..."
	readarray -t src < <(printf "${tmpdir}/${IBL_FIN2}\n" "${!IBL_LISTS[@]}")
	dst="${tmpdir}/${IBL_FOUT}"
	cat "${src[@]}" | sort --version-sort | uniq > "${dst}"
	if [[ "${OSTYPE}" == "darwin"* || "${OSTYPE}" == "freebsd"* ]]; then
		sed -i "" -e '/^$/d' -e '/^#.*$/d' "${dst}"
	else
		sed --in-place --expression='/^$/d' --expression='/^#.*$/d' "${dst}"
	fi

else
	touch "${tmpdir}/${IBL_FOUT}"
fi


# --------------------------------------
#                                      -
#  GeoLite2                            -
#                                      -
# --------------------------------------

if (( ${#GL2_COUNTRIES[@]} > 0 )) && [[ "${GL2_LICENSE}" != "" ]]; then

	# Download database
	print_hilite "Downloading GeoLite2 database..."
	printf -v src "${GL2_URL}" "${GL2_LICENSE}"
	dst="${tmpdir}/${GL2_FIN1}"
	download_file "${src}" "${dst}"

	# Extract database
	print_hilite "Extracting GeoLite2 database..."
	src="${tmpdir}/${GL2_FIN1}"
	dst="${tmpdir}"
	if [[ "${OSTYPE}" == "msys"* ]]; then
		unzip -q -o -j -LL "${src}" -d "${dst}"
	else
		unzip -q -o -j -LL "${src}" '*.csv' -d "${dst}"
	fi

	# Parse country locations, generate dict country names -> ids (NOTE: using
	# split_string here as it deals perfectly with quotes, separators in items
	# etc.; performance is not relevant here)
	print_hilite "Parsing GeoLite2 countries..."
	src="${tmpdir}/${GL2_FIN2}"
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

	# Parse country blocks, generate country blocklists (NOTE: most, probably
	# only performance-critical part of script)
	print_hilite "Generating GeoLite2 blocklists..."
	for country in "${GL2_COUNTRIES[@]}"; do
		print_normal "Generating GeoLite2 blocklist '${country}'..."
		printf -v dst "${tmpdir}/${GL2_FOUT1}" "${country,,}"
		> "${dst}"
		for ipv in "${GL2_IPVERS[@]}"; do
			printf -v src "${tmpdir}/${GL2_FIN3}" "${ipv,,}"
			[[ "${ipv}" == "IPv4" ]] && sort_opts="--version-sort" || sort_opts=""
			if [[ "${OSTYPE}" == "darwin"* || "${OSTYPE}" == "freebsd"* ]]; then
				grep --no-filename "${country_ids["${country,,}"]}" "${src}" | awk -F ',' '{ print $1 }' | \
					while read -r cidr; do
						cidr_to_range_${ipv,,} "${cidr}" sips eips
						printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}"
					done | sort ${sort_opts} | uniq >> "${dst}"
			else
				grep --no-filename "${country_ids["${country,,}"]}" "${src}" | awk --field-separator ',' '{ print $1 }' | \
					while read -r cidr; do
						cidr_to_range_${ipv,,} "${cidr}" sips eips
						printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}"
					done | sort ${sort_opts} | uniq >> "${dst}"
			fi
		done
	done

	# Merge blocklists (NOTE: version sort works well for IPv4; for IPv6,
	# alphanumerical sort is required; since we have to sort for uniq and
	# IPv4 is dominant anyway, version sort is being used; sed command is
	# used to remove empty and comment lines)
	print_hilite "Merging GeoLite2 blocklists..."
	readarray -t src < <(printf "${tmpdir}/${GL2_FOUT1}\n" "${GL2_COUNTRIES[@],,}")
	dst="${tmpdir}/${GL2_FOUT2}"
	cat "${src[@]}" | sort --version-sort | uniq > "${dst}"
	if [[ "${OSTYPE}" == "darwin"* || "${OSTYPE}" == "freebsd"* ]]; then
		sed -i "" -e '/^$/d' -e '/^#.*$/d' "${dst}"
	else
		sed --in-place --expression='/^$/d' --expression='/^#.*$/d' "${dst}"
	fi

else
	touch "${tmpdir}/${GL2_FOUT2}"
fi


# --------------------------------------
#                                      -
#  Finalization                        -
#                                      -
# --------------------------------------

# Merge I-BlockList and GeoLite2 blocklists
print_hilite "Merging I-BlockList and GeoLite2 blocklists..."
readarray -t src < <(printf "${tmpdir}/%s\n" "${IBL_FOUT}" "${GL2_FOUT2}")
dst="${tmpdir}/${FINAL_FILE}"
cat "${src[@]}" > "${dst}"

# Install final IP filter blocklist
print_hilite "Installing final IP filter blocklist..."
src="${tmpdir}/${FINAL_FILE}"
dst="${INSTALL_DST}"
cp "${src}" "${dst}"

# Return home safely
(( ${CMD_NOTIFY} == 1 )) && notify info "${SCRIPT_TITLE}" "IP filter successfully updated."
exit 0
