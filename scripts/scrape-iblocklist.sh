#!/usr/bin/env bash

# -------------------------------------------------------------------------
#                                                                         -
#  I-BlockList Scraper                                                    -
#                                                                         -
#  Created by Fonic <https://github.com/fonic>                            -
#  Date: 10/06/20 - 04/28/21                                              -
#                                                                         -
#  Based on info provided by user 'Koeroesi86' on Gist:                   -
#  https://gist.github.com/johntyree/3331662#gistcomment-3251418          -
#  https://gist.github.com/johntyree/3331662#gistcomment-3251525          -
#                                                                         -
#  NOTE:                                                                  -
#  This will detect 'not available in selected format' as non-free        -
#  (not an issue as it only affects two lists which ARE non-free)         -
#                                                                         -
# -------------------------------------------------------------------------

# Check if item is element of array [$1: item, $2: array name]
function in_array() {
	local needle="$1" i
	local -n arrref="$2"
	for ((i=0; i < ${#arrref[@]}; i++)); do
		[[ "${arrref[i]}" == "${needle}" ]] && return 0
	done
	return 1
}

# Globals
user_agent="Mozilla/5.0 (X11; Linux x86_64; rv:75.0) Gecko/20100101 Firefox/75.0"
lists_url="https://www.iblocklist.com/lists.php"
download_url="https://list.iblocklist.com/?list=%s&fileformat=p2p&archiveformat=gz"
re_id_name="<a href='/list\?list=(.+)'>(.+)</a>" # link to list details (every list has this)
re_free="type='text' id='(.+)' readonly='readonly'" # attributes of <input> text field containing update url (only free lists have this)

# Scrape lists
echo -e "\e[1mScraping lists from '${lists_url}'...\e[0m"
ids=()
names=()
urls=()
frees=()
id_max=0
name_max=0
url_max=0
while read -r line; do
	if [[ "${line}" =~ ${re_id_name} ]]; then
		id="${BASH_REMATCH[1]}"
		ids+=("${id}")
		name="${BASH_REMATCH[2]}"
		names+=("${name}")
		printf -v url "${download_url}" "${id}"
		urls+=("${url}")
		(( ${#id} > ${id_max} )) && id_max=${#id}
		(( ${#name} > ${name_max} )) && name_max=${#name}
		(( ${#url} > ${url_max} )) && url_max=${#url}
	elif [[ "${line}" =~ ${re_free} ]]; then
		id="${BASH_REMATCH[1]}"
		frees+=("${id}")
	fi
done < <(curl --silent --show-error --user-agent "${user_agent}" "${lists_url}")
echo "Found ${#ids[@]} lists"
echo

# Print results
echo -e "\e[1mList details:\e[0m"
printf "%-${name_max}s   %-${id_max}s   %-${url_max}s   %-4s\n" "Name" "ID" "URL" "Free"
for ((i=0; i < ${#ids[@]}; i++)); do
	in_array "${ids[i]}" "frees" && free="yes" || free="no"
	printf "%-${name_max}s   %-${id_max}s   %-${url_max}s   %-4s\n" "${names[i]}" "${ids[i]}" "${urls[i]}" "${free}"
done
echo
echo -e "\e[1mAll lists:\e[0m"
echo -n "declare -A IBL_LISTS=("
for ((i=0; i < ${#ids[@]}; i++)); do
	echo -n "[\"${names[i]}\"]=\"${ids[i]}\" "
done
echo -e "\b)"
echo
echo -e "\e[1mFree lists:\e[0m"
echo -n "declare -A IBL_LISTS=("
for ((i=0; i < ${#ids[@]}; i++)); do
	in_array "${ids[i]}" "frees" && echo -n "[\"${names[i]}\"]=\"${ids[i]}\" "
done
echo -e "\b)"
echo
echo -e "\e[1mPaid lists:\e[0m"
echo -n "declare -A IBL_LISTS=("
for ((i=0; i < ${#ids[@]}; i++)); do
	in_array "${ids[i]}" "frees" || echo -n "[\"${names[i]}\"]=\"${ids[i]}\" "
done
echo -e "\b)"
