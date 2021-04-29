#!/usr/bin/env bash

# -------------------------------------------------------------------------
#                                                                         -
#  IP Filter Updater & Generator Test Suite                               -
#                                                                         -
#  Created by Fonic <https://github.com/fonic>                            -
#  Date: 10/06/20 - 04/28/21                                              -
#                                                                         -
# -------------------------------------------------------------------------

# --------------------------------------
#                                      -
#  Early checks                        -
#                                      -
# --------------------------------------

# Check if running Bash and required version
if [ -z "${BASH_VERSION}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
	echo "This script requires Bash >= 4.0 to run."
	exit 1
fi


# --------------------------------------
#                                      -
#  Configuration                       -
#                                      -
# --------------------------------------

# Determine platform / OS type
case "${OSTYPE,,}" in
	"linux"*) uname="$(uname -r)"; [[ "${uname,,}" == *"microsoft"* ]] && PLATFORM="linux-wsl" || PLATFORM="linux"; ;;
	"darwin"*) PLATFORM="macos"; ;;
	"freebsd"*) PLATFORM="freebsd"; ;;
	"msys"*) PLATFORM="windows-msys"; ;;
	"cygwin"*) PLATFORM="windows-cygwin"; ;;
	*) PLATFORM="${OSTYPE,,}"
esac

# Determine base directory, file name and name of test suite
SUITE_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_FILE="$(basename "$0")"
SUITE_NAME="${SUITE_FILE%.*}"

# Name of script to test (without extension)
SCRIPT_NAME="ipfilter"

# GeoLite2 license
GL2_LICENSE=""


# --------------------------------------
#                                      -
#  Functions                           -
#                                      -
# --------------------------------------

# Change configuration setting [$1: config file, $2: name, $3: value]
function change_config_setting() {
	local config="$1" name="$2" value="$3" sedexp

	# Check if configuration settings exists
	grep -q "^${name}=\|^#${name}=" "${config}" || { echo -e "\e[1;31mError: configuration does not contain setting '${name}' (1)\e[0m"; return 1; }

	# Change setting
	sedexp="s|^#\{0,1\}${name}=.*$|${name}=${value}|g"
	if [[ "${PLATFORM}" == "macos" || "${PLATFORM}" == "freebsd" ]]; then
		sed -i "" -e "${sedexp}" "${config}"
	else
		sed --in-place --expression="${sedexp}" "${config}"
	fi
	(( $? == 0 )) || { echo -e "\e[1;31mError: failed to change setting '${name}' to '${value}'\e[0m"; return 1; }

	# Verify setting now has desired value (NOTE: -F fixed string instead
	# of regex, -x whole line must match; -F is important to allow value to
	# contain regex characters like '[' etc.)
	grep -qFx "${name}=${value}" "${config}" || { echo -e "\e[1;31mError: failed to change setting '${name}' to '${value} (2)'\e[0m"; return 1; }
}

# Get file size [$1: path, $2: target variable]
function get_file_size() {
	local _path="$1"
	local -n _target="$2"
	if [[ "${PLATFORM}" == "macos" || "${PLATFORM}" == "freebsd" ]]; then
		_target=$(stat -f "%z" "$1")
	else
		_target=$(stat -c "%s" "$1")
	fi
	return $?
}

# Join countries to string [$1..$n: country]
function countries_to_str {
	local str
	for arg; do
		str+="${str+ }\"${arg}\""
	done
	echo -n "${str}"
}


# --------------------------------------
#                                      -
#  Main                                -
#                                      -
# --------------------------------------

# Set up error handling, set up interrupt handling
set -e; trap "echo -e \"\e[1;31mAn error occurred, aborting.\e[0m\"; exit 1" ERR
trap "echo -en \"\r\e[2K\"; echo -e \"\e[1;33mAborting per user request.\e[0m\"; exit 130" INT

# Clean up data from previous run(s) (NOTE: needs to be done before logging
# starts to be able to remove old log file)
echo -e "\e[1mCleaning up...\e[0m"
rm -rf "${SUITE_DIR}/${SUITE_NAME}.log" "${SUITE_DIR}/test-dir"* "${SUITE_DIR}/test-results"*

# Set up logging (NOTE: all output produced by this script after this will be
# logged to file)
echo -e "\e[1mSetting up logging...\e[0m"
exec 3>&1 4>&2
exec > >(tee -i "${SUITE_DIR}/${SUITE_NAME}.log") 2>&1

# Print base directory
echo -e "\e[1mBase directory:\e[0m"
echo "${SUITE_DIR}"

# Print platform / OS type
echo -e "\e[1mPlatform / OS type:\e[0m"
echo "uname:  $(uname -a)"
echo "OSTYPE: ${OSTYPE}"
echo "ID'ed:  ${PLATFORM}"

# Modify default configuration
#change_config_setting "${SUITE_DIR}/${SCRIPT_NAME}.conf" "VERBOSE_OUTPUT" "\"true\""

# Run tests (NOTE: run the following command to generate a list of all tests:
# grep -Po "(?<=[[:space:]][[:space:]])[0-9][0-9](?=\))" scripts/test-suite.sh)
echo -e "\e[1mRunning tests...\e[0m"
#for ((test=1; ; test++)); do
#for test in 11; do
for test in 11  21 22  31 32  41 42 43 44 45 46  51 52 53 54  61 62 63 64 65  91 92 93 94; do
	echo "Test ${test}:"

	# Set up test directory
	tstdir="${SUITE_DIR}/test-dir-${test}"
	[[ -d "${tstdir}" ]] && { echo -e "\e[1;33mskipped\e[0m"; continue; }
	mkdir -p "${tstdir}"
	cp "${SUITE_DIR}/${SCRIPT_NAME}"{.sh,.conf} "${tstdir}"

	# Run test
	result=0
	case "${test}" in

		11) # Default configuration
			opts=()
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;

		21) # Desktop notification (positive)
			opts=("-n")
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;
		22) # Desktop notification (negative)
			opts=("-n")
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "([\"unknown\"]=\"xxxxxxxxxxxxxxxxxxxx\")" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" && { echo "${SCRIPT_NAME}.sh succeeded (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] && { echo "${SCRIPT_NAME}.p2p exists"; result=1; }
			;;

		31) # Verbose output ('true')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "VERBOSE_OUTPUT" "\"true\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			grep -qE "^.+: [0-9]+ lines$" "${tstdir}/${SCRIPT_NAME}.log" || { echo "${SCRIPT_NAME}.log does not contain verbose output"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;
		32) # Verbose output ('false')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "VERBOSE_OUTPUT" "\"false\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			grep -qE "^.+: [0-9]+ lines$" "${tstdir}/${SCRIPT_NAME}.log" && { echo "${SCRIPT_NAME}.log contains verbose output"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;

		41) # Log file (custom location)
			opts=()
			path="$(mktemp)"
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "LOG_FILE" "\"${path}\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			#echo "${path}: "; ls -lh "${path}" || :
			#get_file_size "${path}" size && (( ${size} > 0 )) || { echo "log file not properly created at custom location"; result=1; }
			grep -qF "Started:" "${path}" || { echo "log file not properly created at custom location"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] && { echo "${SCRIPT_NAME}.log exists at default location"; result=1; }
			mv "${path}" "${tstdir}/${SCRIPT_NAME}.log" || { echo "failed to pull log file from custom location"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;

		42) # Log mode ('disabled')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "LOG_MODE" "\"disabled\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] && { echo "${SCRIPT_NAME}.log exists"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;
		43) # Log mode ('append')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "LOG_MODE" "\"append\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			entries=$(grep -F "Started:" "${tstdir}/${SCRIPT_NAME}.log" | wc -l) && (( ${entries} == 3 )) || { echo "${SCRIPT_NAME}.log does not contain three entries"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;
		44) # Log mode ('overwrite')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "LOG_MODE" "\"overwrite\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			entries=$(grep -F "Started:" "${tstdir}/${SCRIPT_NAME}.log" | wc -l) && (( ${entries} == 1 )) || { echo "${SCRIPT_NAME}.log does not contain one entry"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;
		45) # Log colors ('true')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "LOG_COLORS" "\"true\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			grep -qF $'\e[1m' "${tstdir}/${SCRIPT_NAME}.log" || { echo "${SCRIPT_NAME}.log does not contain escape code"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;
		46) # Log colors ('false')
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "LOG_COLORS" "\"false\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			grep -qF $'\e[1m' "${tstdir}/${SCRIPT_NAME}.log" && { echo "${SCRIPT_NAME}.log contains escape code"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			;;

		51) # GeoLite2 countries
			[[ -z "${GL2_LICENSE}" ]] && { echo -e "\e[1;33mskipped\e[0m"; continue; }
			opts=()
			countries=("France" "Italy" "Spain")
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_LICENSE" "\"${GL2_LICENSE}\"" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_COUNTRIES" "($(countries_to_str "${countries[@]}"))" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			for country in "${countries[@]}"; do
				grep -qi "^geolite2 ${country}" "${tstdir}/${SCRIPT_NAME}.p2p" || { echo "${SCRIPT_NAME}.p2p does not contain lines for country '${country}'"; result=1; }
			done
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			;;
		52|53) # GeoLite2 IP versions
			[[ -z "${GL2_LICENSE}" ]] && { echo -e "\e[1;33mskipped\e[0m"; continue; }
			case "${test}" in
				52) ipv="IPv4"; ;;
				53) ipv="IPv6"; ;;
				*) echo "Invalid test '${test}'"; result=1; ;;
			esac
			opts=()
			country="Italy"
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_LICENSE" "\"${GL2_LICENSE}\"" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_COUNTRIES" "(\"${country}\")" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_IPVERS" "(\"${ipv}\")" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			grep -qi "^geolite2 ${country} ${ipv}" "${tstdir}/${SCRIPT_NAME}.p2p" || { echo "${SCRIPT_NAME}.p2p does not contain lines for country '${country}' IP version '${ipv}'"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			;;
		54) # GeoLite2 invalid license
			opts=()
			country="Italy"
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_LICENSE" "\"xxxxxxxxxxxxxxxx\"" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_COUNTRIES" "(\"${country}\")" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" && { echo "${SCRIPT_NAME}.sh succeeded (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] && { echo "${SCRIPT_NAME}.p2p exists"; result=1; }
			;;

		61|62|63|64|65) # Compression type
			case "${test}" in
				61) comp="none"; ext="p2p"; ;;
				62) comp="gzip"; ext="p2p.gz"; ;;
				63) comp="bzip2"; ext="p2p.bz2"; ;;
				64) comp="xz"; ext="p2p.xz"; ;;
				65) comp="zip"; ext="zip"; ;;
				*) echo "Invalid test '${test}'"; result=1; ;;
			esac
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "([\"level3\"]=\"uwnukjqktoggdknzrhgh\")" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "COMP_TYPE" "\"${comp}\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.${ext}" ]] || { echo "${SCRIPT_NAME}.${ext} does not exist"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			;;

		91) # Install destination (custom path)
			opts=()
			path="$(mktemp)"
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "([\"level3\"]=\"uwnukjqktoggdknzrhgh\")" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "INSTALL_DST" "\"${path}\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			#echo "${path}: "; ls -lh "${path}" || :
			#get_file_size "${path}" size && (( ${size} > 0 )) || { echo "p2p file not properly created at custom location"; result=1; }
			grep -qE "^.+:[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}-[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}$" "${path}" || { echo "p2p file not properly created at custom location"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] && { echo "${SCRIPT_NAME}.p2p exists at default location"; result=1; }
			mv "${path}" "${tstdir}/${SCRIPT_NAME}.p2p" || { echo "failed to pull p2p file from custom location"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			;;
		92) # No I-BlockList blocklists and no GeoLite2 countries set
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "()" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_COUNTRIES" "()" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }
			get_file_size "${tstdir}/${SCRIPT_NAME}.p2p" size && (( ${size} == 0 )) || { echo "${SCRIPT_NAME}.p2p does not exist or is not empty"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			;;
		93) # Run script from path containing spaces with different name containing spaces
			opts=()
			path="${tstdir}/dir with spaces"
			name="file with spaces"
			mkdir -p "${path}" || result=1
			mv "${tstdir}/${SCRIPT_NAME}.sh" "${path}/${name}.sh" || result=1
			mv "${tstdir}/${SCRIPT_NAME}.conf" "${path}/${name}.conf" || result=1
			change_config_setting "${path}/${name}.conf" "IBL_LISTS" "([\"level3\"]=\"uwnukjqktoggdknzrhgh\")" || result=1
			"${path}/${name}.sh" "${opts[@]}" &>"${path}/${name}.out" || { echo "${name}.sh failed (exit code: $?)"; result=1; }
			#echo "${tstdir}: "; ls -lh "${tstdir}" || :
			#echo "${path}: "; ls -lh "${path}" || :
			[[ -f "${path}/${name}.log" ]] || { echo "${name}.log does not exist"; result=1; }
			[[ -f "${path}/${name}.p2p" ]] || { echo "${name}.p2p does not exist"; result=1; }
			;;
		94) # Multiple I-Blocklists and GeoLite2 countries (for comparison of resulting .p2p files across different platforms)
			[[ -z "${GL2_LICENSE}" ]] && { echo -e "\e[1;33mskipped\e[0m"; continue; }
			opts=()
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "VERBOSE_OUTPUT" "\"true\"" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "IBL_LISTS" "([\"level1\"]=\"ydxerpxkpcfqjaybcssw\" [\"level2\"]=\"gyisgnzbhppbvsphucsw\" [\"level3\"]=\"uwnukjqktoggdknzrhgh\" [\"spyware\"]=\"llvtlsjyoyiczbkjsxpf\" [\"proxy\"]=\"xoebmbyexwuiogmbyprb\" [\"badpeers\"]=\"cwworuawihqvocglcoss\")" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_LICENSE" "\"${GL2_LICENSE}\"" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_COUNTRIES" "(\"France\" \"Italy\" \"Spain\")" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "GL2_IPVERS" "(\"IPv4\" \"IPv6\")" || result=1
			change_config_setting "${tstdir}/${SCRIPT_NAME}.conf" "COMP_TYPE" "\"none\"" || result=1
			"${tstdir}/${SCRIPT_NAME}.sh" "${opts[@]}" &>"${tstdir}/${SCRIPT_NAME}.out" || { echo "${SCRIPT_NAME}.sh failed (exit code: $?)"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.log" ]] || { echo "${SCRIPT_NAME}.log does not exist"; result=1; }
			[[ -f "${tstdir}/${SCRIPT_NAME}.p2p" ]] || { echo "${SCRIPT_NAME}.p2p does not exist"; result=1; }

		#*)  # End of tests reached (only relevant if using loop incrementing ${test})
		#	echo "<reached end of tests>"
		#	break
		#	;;

	esac
	(( ${result} == 0 )) && echo -e "\e[1;32mpassed\e[0m" || echo -e "\e[1;31mfailed\e[0m"

done

# Display test folder contents
echo -e "\e[1mTest folder contents:\e[0m"
ls -lh "${SUITE_DIR}"

# End logging (NOTE: required for MSYS2, which fails archiving due to log
# file being inaccessible; all other platforms seem fine without this)
exec 1>&3 3>&-; exec 2>&4 4>&-

# Archive test results (NOTE: create archive outside of test folder first
# to avoid mutation errors; suppress verbose ouput on macOS/FreeBSD)
echo -e "\e[1mArchiving test results...\e[0m"
result=0
uname="$(uname -s)"; uname="${uname,,}"
archive="${SUITE_DIR}/test-results-${PLATFORM}-${uname}.tar.gz"
temp="$(mktemp)" || result=1
output="$(tar -cvzf "${temp}" -C "${SUITE_DIR}" . 2>&1)" || { echo "${output}"; result=1; }
mv "${temp}" "${archive}" || result=1
(( ${result} == 0 )) && echo -e "\e[1;32msuccess\e[0m" || echo -e "\e[1;31mfailed\e[0m"
