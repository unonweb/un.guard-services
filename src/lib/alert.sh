# REQUIRES
# ========
# - MAIL_ALERT
# - MAIL_TO
# - MAIL_SUBJECT
# - MAIL_TO

function alert {

	local alert_msg="${1}"

	if (( ! MAIL_ALERT )); then
		return 0
	fi

	if (( MAIL_ALERT )) && [[ -z "${MAIL_TO}" ]]; then
		log "<3> Required var not set: MAIL_TO"
		return 1
	fi

	if [[ -n "${alert_msg}" ]]; then

		# ALERT
		alert_msg_header+="DATE: $(date "+%Y-%m-%d %H:%M:%S")\n"
		alert_msg_header+="HOSTNAME: ${HOSTNAME}\n"
		alert_msg_header+="---\n\n"
		alert_msg_header+="NEW SERVICES:\n"
		
		echo -e "${alert_msg_header}${alert_msg}" | \
		mail -s "${MAIL_SUBJECT}" "${MAIL_TO}" 2>/dev/null
	
	fi
}