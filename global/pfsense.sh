# execute commands on remote pfSense machine

source ../global/variables.sh

function clean_pfsense() {
	# TBD: delete specifics or all?
	#		"/var/db/pfblockerng/dnsbl/" \
	#		"/var/db/pfblockerng/dnsblorig/" \
	#		"/var/db/pfblockerng/dnsblalias/" \
	#		"/var/db/pfblockerng/deny/" \
	#		"/var/db/pfblockerng/match/" \
	if [ ${DRYRUN} == false ]; then
		/bin/ssh -i ${IDENTITY_FILE} -p ${PFSENSE_PORT} \
			${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME} \
			"rm -rf " \
			"/var/db/pfblockerng/" \
			"/var/log/pfblockerng/dnsbl.log" \
			"/var/log/pfblockerng/pfblockerng.log" \
			"/var/log/pfblockerng/dnsbl_parsed_error.log"
	else
		echo "DRYRUN rm -rf /var/db/pfblockerng/ and /var/log/pfblockerng/"
	fi
}

function exec_pfsense() {
	action=$1
	# cron
	# update
	# dnsbl
	# ip

	if [ -z "${action}" ]; then
		echo "ERROR: Missing argument action for ${FUNCNAME[0]}" | ${TEECMD} "${LOGFILE}"
		exit 1
	fi

	if [ ${DRYRUN} == false ]; then
		echo "$(date) : BEGAN php pfblockerng.php ${action}" | ${TEECMD} "${LOGFILE}"
		/bin/ssh -i ${IDENTITY_FILE} -p ${PFSENSE_PORT} \
			${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME} \
			"/usr/local/bin/php" \
			"/usr/local/www/pfblockerng/pfblockerng.php" \
			"${action}" \
			">> /var/log/pfblockerng/pfblockerng.log 2>&1"
		ret=$?
		if [ ${ret} -ne 0 ]; then
			echo "ssh php pfblockerng.php command exited non-zero: ${ret}"
			exit ${ret}
		fi
		echo "$(date) : ENDED php pfblockerng.php" | ${TEECMD} "${LOGFILE}"
	else
		echo "$(date) : DRYRUN php pfblockerng.php ${action}" | ${TEECMD} "${LOGFILE}"
	fi

	return 0
}

function capture_pfsense() {
	check_runtime_vars
	echo "Retrieve results from ${PFSENSE_HOSTNAME}.." | ${TEECMD} "${LOGFILE}"

	/bin/rm -rf "${BLOCKLIST_RESULTS}"

	db_dir="${BLOCKLIST_RESULTS}/db"
	log_dir="${BLOCKLIST_RESULTS}/log"

	/bin/mkdir -p ${db_dir}
	/bin/mkdir -p ${log_dir}

	/bin/scp -i ${IDENTITY_FILE} -P "${PFSENSE_PORT}" -r \
		"${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME}:/var/db/pfblockerng"/* \
		"${db_dir}"
	ret=$?
	if [ ${ret} -ne 0 ]; then
		echo "scp /var/db/pfblockerng/* exited non-zero ${ret}"
		exit ${ret}
	fi

	/bin/scp -i ${IDENTITY_FILE} -P "${PFSENSE_PORT}" -r \
		"${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME}:/var/log/pfblockerng"/* \
		"${log_dir}"
	ret=$?
	if [ ${ret} -ne 0 ]; then
		echo "scp /var/log/pfblockerng/* exited non-zero ${ret}"
		exit ${ret}
	fi

	/usr/bin/find ./zbenched/ ./zresults.nogit/ ./zstaged.nogit/ -type f -empty -exec rm {} \;
	if [ ${ret} -ne 0 ]; then
		echo "find and rm empty files in zbenched/ and zresults.nogit/ and exited non-zero ${ret}"
		exit ${ret}
	fi

	return 0
}

function update_benchmark() {
	check_runtime_vars

	if [ ${UPDATEBENCHMARK} == true ]; then
		echo "Update benchmark" | ${TEECMD} "${LOGFILE}"
		/bin/rm -rf "${BLOCKLIST_BENCHMARK}"
		/bin/cp -r "${BLOCKLIST_RESULTS}" "${BLOCKLIST_BENCHMARK}"
	fi

	return 0
}
