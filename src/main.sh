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
	if [[ ! -f "${WHITELIST}" ]]; then
		echo "Error: Whitelist file not found: ${WHITELIST}"
		exit 1
	else
		echo "Using whitelist: ${WHITELIST}"
	fi

	# SET current_services
	# (names only, sorted)
	local current_services=$(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}' | sort)

	# COMPARE against the whitelist using 'comm'
	# 'comm -13' suppresses lines unique to file1 (whitelist) and lines common to both.
	# It outputs ONLY lines unique to file2 (currently running but not whitelisted).
	local -a new_services
	mapfile -t new_services < <(comm -13 <(sort "${WHITELIST}") <(echo "${current_services}"))
	
	# Clean up the cache of records older than 48 hours to keep it tidy
	if [[ -f "${CACHE}" ]]; then
		# Keeps only lines where the timestamp is within the last 48 hours
		# Format in cache: EPOCH_TIMESTAMP|SERVICE_NAME
		local current_time=$(date +%s)
		local cutoff_time=$(( current_time - (CACHE_TTL_HOURS * 3600) ))
		# Cache pruning
		# Only keep timestamps that are younger than cutoff_time
		local tmp_cache=$(mktemp)
		while IFS='|' read -r timestamp service; do
			if (( timestamp >= cutoff_time )); then
				echo "${timestamp}|${service}" >> "${tmp_cache}"
			fi
		done < "${CACHE}"
		mv "${tmp_cache}" "${CACHE}"
	fi

	# Process new services and filter out recent alerts
	local alert_msg=""
	for service in "${new_services[@]}"; do
		# Skip empty lines if any
		[[ -z "${service}" ]] && continue

		# Check if this service was already alerted within the cache window
		if [[ -f "${CACHE}" ]] && grep --quiet --fixed-strings "|${service}" "${CACHE}"; then
			# Service found in cache, skip alerting
			echo "Skipping alert for '${service}' (already alerted within past ${CACHE_TTL_HOURS} hours)."
			continue
		fi

		alert_msg+="NEW SERVICE: ${service}\n"

		# Log the alert to the cache with the current epoch timestamp
		echo "$(date +%s)|${service}" >> "${CACHE}"
	done

	# If new services are found, send an email alert
	if [[ -n "${alert_msg}" ]]; then

		# ALERT
		alert_msg_header+="DATE: $(date "+%Y-%m-%d %H:%M:%S")\n"
		alert_msg_header+="HOSTNAME: ${HOSTNAME}\n\n"
		
		if ((SEND_MAIL_ALERT)); then
			echo -e "${alert_msg_header}${alert_msg}" | \
			mail -s "${MAIL_SUBJECT}" "${MAIL_TO}" 2>/dev/null
		fi
	
	fi
}

main