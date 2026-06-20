#!/usr/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_PARENT=$(dirname "${SCRIPT_DIR}")

PATH_CONFIG="${SCRIPT_PARENT}/config.cfg"
PATH_DEFAULTS="${SCRIPT_PARENT}/defaults.cfg"

HOSTNAME=$(hostname)

function main {

	if [ "${UID}" -ne 0 ]; then
  		echo "This script must be run as root."
  		exit 1
	fi

	# CONFIG & DEFAULTS
	if [[ -r ${PATH_CONFIG} ]]; then
		source "${PATH_CONFIG}"
	else
		echo "<4>WARN: No config file found at ${PATH_CONFIG}. Using defaults ..."
		source "${PATH_DEFAULTS}"
	fi

	# Ensure the whitelist file exists on first run
	if [ ! -f "${WHITELIST}" ]; then
		echo "Error: Whitelist file not found: ${WHITELIST}"
		exit 1
	fi

	# SET current_services
	# (names only, sorted)
	local current_services=$(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | sort)

	# COMPARE against the whitelist using 'comm'
	# 'comm -13' suppresses lines unique to file1 (whitelist) and lines common to both.
	# It outputs ONLY lines unique to file2 (currently running but not whitelisted).
	local new_services=$(comm -13 "${WHITELIST}" <(echo "${current_services}"))

	# 3. If new services are found, send an email alert
	if [ -n "${new_services}" ]; then

		# ALERT
		local msg=""
		msg+="DATE: $(date "+%Y-%m-%d %H:%M:%S")\n"
		msg+="HOSTNAME: ${HOSTNAME}\n\n"
		msg+="NEW SERVICES\n"
		msg+="------------\n"
		msg+="${new_services}"
		
		echo -e "${msg}" | \
		mail -s "${MAIL_SUBJECT}" "${MAIL_DST}" 2>/dev/null
	
	fi
}

main ${@}