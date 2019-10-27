#!/bin/bash

# -------------------------------------------------------------------------
#                                                                         -
#  IP Filter Updater & Generator                                          -
#                                                                         -
#  Created by Fonic (https://github.com/fonic/ipfilter)                   -
#  Date: 10/26/19                                                         -
#                                                                         -
# -------------------------------------------------------------------------


# --------------------------------------
#                                      -
#  TODO                                -
#                                      -
# --------------------------------------
#
# - it seems IPv6 is not supported by the .p2p format -> IPv6 deactivated for now
#


# --------------------------------------
#                                      -
#  Configuration                       -
#                                      -
# --------------------------------------

# Program
PROG_NAME="IP Filter Updater & Generator"
PROG_EXEC="$(basename "${BASH_SOURCE[0]}")"
PROG_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wget options
WGET_OPTS=("--quiet" "--tries=3" "--timeout=15")

# I-BlockList (https://www.iblocklist.com/lists)
IBL_URL="http://list.iblocklist.com/?list=%s&fileformat=p2p&archiveformat=gz"
IBL_FIN1="iblocklist-%s.p2p.gz"
IBL_FIN2="iblocklist-%s.p2p"
IBL_FOUT="iblocklist-merged.p2p"
#declare -A IBL_LISTS=(["level1"]="ydxerpxkpcfqjaybcssw" ["level2"]="gyisgnzbhppbvsphucsw" ["level3"]="uwnukjqktoggdknzrhgh" ["badpeers"]="cwworuawihqvocglcoss")
declare -A IBL_LISTS=(["level1"]="ydxerpxkpcfqjaybcssw" ["level2"]="gyisgnzbhppbvsphucsw" ["level3"]="uwnukjqktoggdknzrhgh")

# GeoLite2 (https://dev.maxmind.com/geoip/geoip2/geolite2)
GL2_URL="https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip"
GL2_FIN1="geolite2-country-database.zip"
GL2_FIN2="geolite2-country-locations-en.csv"
GL2_FIN3="geolite2-country-blocks-%s.csv"
GL2_FOUT1="geolite2-%s.p2p"
GL2_FOUT2="geolite2-merged.p2p"
GL2_COUNTRIES=("China")

# Final output file, install destination
FINAL_FILE="ipfilter.p2p"
INSTALL_TO="${PROG_BASE}/${FINAL_FILE}"


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

# Print highlighted message [$*: message]
function print_light() {
	echo -e "\e[1m$*\e[0m"
}

# Print positive message [$*: message]
function print_good() {
	echo -e "\e[1;32m$*\e[0m"
}

# Print warning message [$*: message]
function print_warning() {
	echo -e "\e[1;33m$*\e[0m"
}

# Print error message [$*: message]
function print_error() {
	echo -e "\e[1;31m$*\e[0m"
}

# Handler for error trap [no arguments] (NOTE: redirection to stderr is
# important for this to work inside of pipes / process substitution;
# sending TERM signal to ourselves to realiably exit even if trap occurs
# in subshell)
function error_trap() {
	print_error "An error occured, aborting." >&2
	(( ${notify} == 1 )) && notify-send --urgency=critical --app-name="${PROG_NAME}" "An error occurred while updating." "Please check output for errors."
	kill -s TERM $$
	exit 1
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
# (NOTE: copied from 'Playground/bash_cidr_to_ip_range_ipv4_ipv6.sh'; reduced to what we need here)
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
# (NOTE: copied from 'Playground/bash_cidr_to_ip_range_ipv4_ipv6.sh'; reduced to what we need here; using padded hex for _sips/_eips to facilitate sort)
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

# Set extended Bash options, set error trap (NOTE: elaborate approach to
# reliably exit even if an error occurs in subshell / process substitution
# -> https://stackoverflow.com/a/9894126)
set -eEou pipefail
trap "exit 1" TERM; trap "error_trap" ERR

# Set cosmetic traps
trap "trap - ERR; echo -en \"\r\e[2K\"" INT
trap "print_normal" EXIT

# Set window title, print title
set_window_title "${PROG_NAME}"
print_normal
print_light "--== ${PROG_NAME} ==--"
print_normal

# Provide help if requested (NOTE: we do this separately so that help shows
# up when -h/--help is present, even if there are further/invalid options)
if in_array "-h" "$@" || in_array "--help" "$@"; then
	print_normal "Usage: $(basename "$0") [OPTIONS]"
	print_normal
	print_normal "Options:"
	print_normal "  -n, --notify               Send desktop notification when"
	print_normal "                             done / on error (for cron use)"
	print_normal "  -k, --keep-temp            Do not remove temp folder when"
	print_normal "                             done (helpful for debugging)"
	print_normal "  -h, --help                 Display this help message"
	exit 0
fi

# Parse command line
notify=0
keep_temp=0
invalid_args=0
for arg in "$@"; do
	case "${arg}" in
		"-n"|"--notify")    notify=1; ;;
		"-k"|"--keep-temp") keep_temp=1; ;;
		*)                  print_normal "Invalid argument '${arg}'"; invalid_args=1; ;;
	esac
done
if (( ${invalid_args} == 1 )); then
	print_normal
	print_error "Invalid command line. Use '--help' to display usage information."
	exit 2
fi

# Create temporary folder, set cleanup trap (NOTE: replaces EXIT trap set
# above for cosmetic reasons)
print_light "Creating temporary folder..."
tmpdir="$(mktemp --directory --tmpdir=/tmp "${PROG_EXEC%.*}.XXXXXXXXXX")"
(( ${keep_temp} == 0 )) && trap "print_light \"Removing temporary folder...\"; rm -rf \"${tmpdir}\"; print_normal" EXIT


# --------------------------------------
#                                      -
#  I-BlockList                         -
#                                      -
# --------------------------------------

if (( ${#IBL_LISTS[@]} > 0 )); then

	# Download blocklists
	print_light "Downloading I-BlockList blocklists..."
	for list in "${!IBL_LISTS[@]}"; do
		print_normal "Downloading I-BlockList blocklist '${list}'..."
		printf -v src "${IBL_URL}" "${IBL_LISTS["${list}"]}"
		printf -v dst "${tmpdir}/${IBL_FIN1}" "${list}"
		wget "${WGET_OPTS[@]}" "${src}" -O "${dst}"
	done

	# Decompress blocklists
	print_light "Decompressing I-BlockList blocklists..."
	for list in "${!IBL_LISTS[@]}"; do
		print_normal "Decompressing I-BlockList blocklist '${list}'..."
		printf -v src "${tmpdir}/${IBL_FIN1}" "${list}"
		printf -v dst "${tmpdir}/${IBL_FIN2}" "${list}"
		gunzip < "${src}" > "${dst}"
	done

	# Merge blocklists
	print_light "Merging I-BlockList blocklists..."
	readarray -t src < <(printf "${tmpdir}/${IBL_FIN2}\n" "${!IBL_LISTS[@]}")
	dst="${tmpdir}/${IBL_FOUT}"
	cat "${src[@]}" | sort --version-sort | uniq > "${dst}"                                     # Version sort works well for IPv4, but not for IPv6 (requires alphanumerical sort); We *have* to sort in order to uniq, so we use version sort as IPv4 is dominant anyway
	sed --in-place --expression='/^$/d' --expression='/^#.*$/d' "${dst}"                        # Remove empty lines and comment lines (there should only be two in total due to sort + uniq)

else
	touch "${tmpdir}/${IBL_FOUT}"
fi


# --------------------------------------
#                                      -
#  GeoLite2                            -
#                                      -
# --------------------------------------

if (( ${#GL2_COUNTRIES[@]} > 0 )); then

	# Download database
	print_light "Downloading GeoLite2 database..."
	src="${GL2_URL}"
	dst="${tmpdir}/${GL2_FIN1}"
	wget "${WGET_OPTS[@]}" "${src}" -O "${dst}"

	# Extract database
	print_light "Extracting GeoLite2 database..."
	src="${tmpdir}/${GL2_FIN1}"
	dst="${tmpdir}"
	unzip -q -o -j -LL "${src}" '*.csv' -d "${dst}"

	# Parse country locations, generate dict country names -> ids (NOTE: using
	# split_string here as it deals perfectly with quotes, separators in items
	# etc.; performance is not relevant here)
	print_light "Parsing GeoLite2 countries..."
	src="${tmpdir}/${GL2_FIN2}"
	declare -A country_ids
	while read -r line; do
		split_string "${line}" "," array
		(( ${#array[@]} != 7 )) && { print_error "Skipping invalid line: ${line}" >&2; continue; }

		geoname_id="${array[0]}"
		locale_code="${array[1]}"
		continent_code="${array[2]}"
		continent_name="${array[3]}"
		country_iso_code="${array[4]}"
		country_name="${array[5]}"
		is_in_european_union="${array[6]}"

		if [[ "${country_name}" != "" ]]; then
			country_ids["${country_name,,}"]="${geoname_id}"
		else
			country_ids["${continent_name,,}"]="${geoname_id}"
		fi
	done < <(tail -q -n +2 "${src}")

	# Parse country blocks, generate country blocklists (NOTE: performance-critical!)
	print_light "Generating GeoLite2 blocklists..."
	for country in "${GL2_COUNTRIES[@]}"; do
		print_normal "Generating GeoLite2 blocklist '${country}'..."
		printf -v dst "${tmpdir}/${GL2_FOUT1}" "${country,,}"
		> "${dst}"
		#for ipv in IPv4 IPv6; do                                                                   # TODO: IPv6 disabled for now (see header of script for details)
		for ipv in IPv4; do
			printf -v src "${tmpdir}/${GL2_FIN3}" "${ipv,,}"
			[[ "${ipv}" == "IPv4" ]] && sort_opts="--version-sort"
			#while read -r cidr; do                                                                 # not using this variant as it weirdly interferes with trap handling
			#	cidr_to_range_${ipv,,} "${cidr}" sips eips
			#	#printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}" >&2      # use this for terminal output
			#	#printf "GeoLite2 %s:%s-%s\n" "${country}" "${sips}" "${eips}"                      # use this for comparison with older script versions
			#	printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}"           # normal output
			#done < <(grep --no-filename "${country_ids["${country,,}"]}" "${src}" | awk --field-separator ',' '{ print $1 }') | sort ${sort_opts} | uniq >> "${dst}"
			grep --no-filename "${country_ids["${country,,}"]}" "${src}" | awk --field-separator ',' '{ print $1 }' | \
				while read -r cidr; do
					cidr_to_range_${ipv,,} "${cidr}" sips eips
					#printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}" >&2  # use this for terminal output
					printf "GeoLite2 %s:%s-%s\n" "${country}" "${sips}" "${eips}"                  # use this for comparison with older script revisions
					#printf "GeoLite2 %s %s:%s-%s\n" "${country}" "${ipv}" "${sips}" "${eips}"       # normal output
				done | sort ${sort_opts} | uniq >> "${dst}"
		done
	done

	# Merge blocklists
	print_light "Merging GeoLite2 blocklists..."
	readarray -t src < <(printf "${tmpdir}/${GL2_FOUT1}\n" "${GL2_COUNTRIES[@],,}")
	dst="${tmpdir}/${GL2_FOUT2}"
	cat "${src[@]}" | sort --version-sort | uniq > "${dst}"                                         # Version sort works well for IPv4, but not for IPv6 (requires alphanumerical sort); We *have* to sort in order to uniq, so we use version sort as IPv4 is dominant anyway
	sed --in-place --expression='/^$/d' --expression='/^#.*$/d' "${dst}"                            # Remove empty lines and comment lines (there should be none)

else
	touch "${tmpdir}/${GL2_FOUT2}"
fi


# --------------------------------------
#                                      -
#  Finalization                        -
#                                      -
# --------------------------------------

# Merge I-BlockList and GeoLite2 blocklists
print_light "Merging I-BlockList and GeoLite2 blocklists..."
readarray -t src < <(printf "${tmpdir}/%s\n" "${IBL_FOUT}" "${GL2_FOUT2}")
dst="${tmpdir}/${FINAL_FILE}"
cat "${src[@]}" > "${dst}"

# Install IP-Filter blocklist
print_light "Installing IP-Filter blocklist..."
src="${tmpdir}/${FINAL_FILE}"
dst="${INSTALL_TO}"
cp "${src}" "${dst}"

# Return home safely
(( ${notify} == 1 )) && notify-send --urgency=normal --app-name="${PROG_NAME}" "IP filter successfully updated."
exit 0
