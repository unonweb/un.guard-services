#!/usr/bin/bash

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_PARENT=$(dirname "${SCRIPT_DIR}")

APP_NAME="${SCRIPT_PARENT##*/}"

PATH_CONFIG="${SCRIPT_PARENT}/config.cfg"
PATH_DEFAULTS="${SCRIPT_PARENT}/defaults.cfg"

HOSTNAME=$(hostname)

# IMPORTS
source "${SCRIPT_DIR}/lib/cleanup_cache.sh"
source "${SCRIPT_DIR}/lib/log.sh"
source "${SCRIPT_DIR}/lib/alert.sh"

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
	if [[ ! -f "${WHITELIST}" ]]; then
		log "<3> Whitelist file not found: ${WHITELIST}"
		exit 1
	else
		log "<6> Using whitelist: ${WHITELIST}"
	fi

	# SET current_services
	# (names only, sorted)
	local current_services=$(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | sort)

	# COMPARE against the whitelist using 'comm'
	# 'comm -13' suppresses lines unique to file1 (whitelist) and lines common to both.
	# It outputs ONLY lines unique to file2 (currently running but not whitelisted).
	local -a new_services
	mapfile -t new_services < <(comm -13 <(sort "${WHITELIST}") <(echo "${current_services}"))
	
	# Cleanup Cache
	cleanup_cache

	# Process new services and filter out recent alerts
	local alert_msg=""
	for service in "${new_services[@]}"; do
		# Skip empty lines if any
		[[ -z "${service}" ]] && continue

		# Check if this service was already alerted within the cache window
		if [[ -f "${CACHE_FILE}" ]] && grep --quiet --fixed-strings "|${service}" "${CACHE_FILE}"; then
			# Service found in cache, skip alerting
			log "<6>Skipping alert for '${service}' (already alerted within past ${CACHE_TTL_HOURS} hours)."
			continue
		fi

		alert_msg+="- ${service}\n"

		# Log the alert to the cache with the current epoch timestamp
		echo "$(date +%s)|${service}" >> "${CACHE_FILE}"
	done

	# ALERT
	alert "${alert_msg}
}

main