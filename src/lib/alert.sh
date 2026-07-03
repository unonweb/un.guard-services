# REQUIRES
# ========
# - MAIL_ALERT
# - MAIL_TO
# - MAIL_SUBJECT

function alert {

	local alert_msg="${1}"

	if (( ! MAIL_ALERT )); then
		return 0
	fi

	if [[ -z "${alert_msg}" ]]; then
		return 0
	fi

	# CHECK vars
	for var in MAIL_TO; do
		if [[ -z "${!var}" ]]; then
			log "<3> Required var missing: ${var}"
			return 1
		fi
	done

	# CHECK internal deps
	for fctn in log; do
    	if ! declare -f "${fctn}" > /dev/null; then
        	echo "<3> Error: Required function missing: ${fctn}" >&2
        	return 1
    	fi
	done

	# CHECK external deps
	for cmd in mail; do
    	if ! command -v "${cmd}" &> /dev/null; then
        	log "<3> Error: Required external cmd missing: ${cmd}" >&2
        	return 1
    	fi
	done

	# ALERT
	alert_msg_header+="DATE:		$(date "+%Y-%m-%d %H:%M:%S")\n"
	alert_msg_header+="HOSTNAME:	${HOSTNAME}\n"
	alert_msg_header+="---\n\n"
	alert_msg_header+="NEW SERVICES:\n"
	
	echo -e "${alert_msg_header}${alert_msg}" | \
	mail -s "${MAIL_SUBJECT}" "${MAIL_TO}" 2>/dev/null
}