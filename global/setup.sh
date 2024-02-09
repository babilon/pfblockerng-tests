# setup and preparation

source ../global/variables.sh

_staged="zstaged.nogit"
_benchmarkdir="zbenched"
_resultsdir="zresults.nogit"

function check_ssh_pfSense() {
	/bin/ssh -i ${IDENTITY_FILE} -p "${PFSENSE_PORT}" \
		"${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME}" hostname
	ret=$?
	if [[ ${ret} -ne 0 ]]; then
		echo "Failed ssh pfSense test"
		exit ${ret}
	fi
	return 0
}

function check_ssh_webserver() {
	/bin/ssh -i ${IDENTITY_FILE} -p "${WEBSERVER_PORT}" \
		"${WEBSERVER_USERNAME}@${WEBSERVER_HOSTNAME}" hostname
	ret=$?
	if [[ ${ret} -ne 0 ]]; then
		echo "Failed ssh webserver test"
		exit ${ret}
	fi
	return 0
}

function check_ssh_connections() {
	check_ssh_webserver
	check_ssh_pfSense
}

function clean_httpdocs() {
	if [ ${WEBSERVER_REMOTE} == true ]; then
		echo "Clean remote webserver httpdocs" | ${TEECMD} "${LOGFILE}"
		/bin/ssh -i ${IDENTITY_FILE} -p ${WEBSERVER_PORT} \
			${WEBSERVER_USERNAME}@${WEBSERVER_HOSTNAME} \
			"rm -f ${WEBSERVER_HTTPDOCS}/*${EXT}"
		ret=$?
		if [ ${ret} -ne 0 ]; then
			echo "Failed to clean webserver's ${WEBSERVER_HTTPDOCS}"
			exit ${ret}
		fi
	else
		echo "Clean local httpdocs" | ${TEECMD} "${LOGFILE}"
		/bin/rm -f "${WEBSERVER_HTTPDOCS}/*${EXT}"
	fi
}

function _stage_raw_dnsbl() {
	check_runtime_vars
	fname=$1

	if [ -z "${fname}" ]; then
		echo "ERROR: Missing argument fname for ${FUNCNAME[0]}" >> "${LOGFILE}"
		exit 1
	fi

	if [ -z "${BLOCKLIST_SRCDIR}" ]; then
		echo "ERROR: BLOCKLIST_SRCDIR is unset or empty for ${FUNCNAME[0]}" >> \
			"${LOGFILE}"
		exit 1
	fi

	if [ -z "${BLOCKLIST_STAGEDIR}" ]; then
		echo "ERROR: BLOCKLIST_STAGEDIR is unset or empty for ${FUNCNAME[0]}" \
			>> "${LOGFILE}"
		exit 1
	fi

	fullpath="${BLOCKLIST_SRCDIR}/${fname}"

	if [ -f ${fullpath} ]; then
		/bin/cp "${fullpath}" "${BLOCKLIST_STAGEDIR}"
		ret=$?
		if [ ${ret} -ne 0 ]; then
			echo "Failed to cp ${fullpath}/* to ${BLOCKLIST_STAGEDIR}"
			exit ${ret}
		fi
		echo "Copied ${fname} into ${_staged}/" >> ${LOGFILE}
	else
		echo "touching ${BLOCKLIST_STAGEDIR}/${fname}" >> "${LOGFILE}"
		touch "${BLOCKLIST_STAGEDIR}/${fname}"
		echo "Created empty file for ${fname} in ${_staged}/" >> "${LOGFILE}"
	fi
}

function upload_raw_dnsbl() {
	if [ ! -d "${BLOCKLIST_STAGEDIR}" ]; then
		echo "ERROR: BLOCKLIST_STAGEDIR is invalid" >> ${LOGFILE}
		exit 1
	fi
	if [ ${WEBSERVER_REMOTE} == true ]; then
		echo "Copying files to ${WEBSERVER_HOSTNAME} in ${WEBSERVER_HTTPDOCS}" \
			>> "${LOGFILE}"

		/bin/scp -i ${IDENTITY_FILE} -P "${WEBSERVER_PORT}" \
			"${BLOCKLIST_STAGEDIR}"/* \
			"${WEBSERVER_USERNAME}@${WEBSERVER_HOSTNAME}:${WEBSERVER_HTTPDOCS}/"
		ret=$?
		if [ ${ret} -ne 0 ]; then
			echo "Failed to scp ${_staged}/* to ${WEBSERVER_HTTPDOCS}"
			exit ${ret}
		fi
		echo "Copied ${_staged}/* to ${WEBSERVER_HOSTNAME}/${WEBSERVER_HTTPDOCS}" \
			>> "${LOGFILE}"
	else
		/bin/cp "${BLOCKLIST_STAGEDIR}"/* "${WEBSERVER_HTTPDOCS}"
		ret=$?
		if [ ${ret} -ne 0 ]; then
			echo "Failed to cp ${_staged}/* to ${WEBSERVER_HTTPDOCS}"
			exit ${ret}
		fi
		echo "Copied ${_staged}/* to localhost:${WEBSERVER_HTTPDOCS}" \
			>> "${LOGFILE}"
	fi
}

function stage_raw_dnsbl() {
	for str in ${BLOCKLIST_FILENAMES[@]}; do
		_stage_raw_dnsbl "${str}"
	done
}

function clean_stage() {
	/bin/rm -rf "${BLOCKLIST_STAGEDIR}/"
	/bin/mkdir -p "${BLOCKLIST_STAGEDIR}"
}

function _started_test() {
	echo "$(date) : STARTED ${SETUP_TESTNAME} test" | ${TEECMD} "${LOGFILE}"
}

function _finished_test() {
	echo "$(date) : FINISHED test" | ${TEECMD} "${LOGFILE}"
}

# like the main function: this does all the things
function setup() {
	testpath=$1
	parsearg1 $2

	if [ -z "${testpath}" ]; then
		echo "ERROR: Missing argument testpath empty for ${FUNCNAME[0]}" >> "${LOGFILE}"
		exit 1
	fi

	checks_and_balances

	BLOCKLIST_SRCDIR="${testpath}/raw_dnsbl"
	BLOCKLIST_STAGEDIR="${testpath}/${_staged}"
	BLOCKLIST_RESULTS="${testpath}/${_resultsdir}"
	BLOCKLIST_BENCHMARK="${testpath}/${_benchmarkdir}"
	SETUP_TESTNAME=$(basename "$(readlink -f -- "${testpath}"; )")
	check_runtime_vars

	_started_test
	trap _finished_test EXIT

	if [ -e "${LOGFILE}" ]; then
		/bin/mv "${LOGFILE}" "${LOGFILE}.old"
	fi

	clean_stage
	clean_httpdocs
	stage_raw_dnsbl
	upload_raw_dnsbl
}
