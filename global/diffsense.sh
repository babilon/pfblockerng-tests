# diff the results against known expected results

source ../global/variables.sh

function _run_diff() {
	resultsdir=${1}
	bencheddir=${2}

	/bin/diff ${DIFFARGS} "${bencheddir}" "${resultsdir}" > /dev/null
	ret=$?
	if [[ ${ret} -eq 0 ]]; then
		printf "OK!\n" | ${TEECMD} "${LOGFILE}"
		return 0
	else
		printf " DIFFERENCES!\ndiff -U 5 %s %s\n" "${bencheddir}" "${resultsdir}" \
			| ${TEECMD} ${LOGFILE}
		return -1
	fi
}

function diff_alldnsbl() {
	diff_dnsblorig
	diff_dnsbl
	diff_dnsblalias
	diff_DNSBLIP_v4
}

function diff_dnsblorig() {
	check_runtime_vars

	# dnsblorig should always match what is/was on the webserver which is what
	# is in the test directory
	r="${BLOCKLIST_RESULTS}/db/dnsblorig"
	b="${BLOCKLIST_STAGEDIR}"

	(cd ${r} && rename .orig .txt *.orig)

	printf "diff dnsblorig/ .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_dnsbl() {
	check_runtime_vars

	r="${BLOCKLIST_RESULTS}/db/dnsbl"
	b="${BLOCKLIST_BENCHMARK}/db/dnsbl"

	printf "diff dnsbl/ .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_dnsblalias() {
	check_runtime_vars
	r="${BLOCKLIST_RESULTS}/db/dnsblalias"
	b="${BLOCKLIST_BENCHMARK}/db/dnsblalias"

	printf "diff dnsblalias/ .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_deny() {
	check_runtime_vars
	r="${BLOCKLIST_RESULTS}/db/deny"
	b="${BLOCKLIST_BENCHMARK}/db/deny"

	printf "diff deny/ .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_DNSBLIP_v4() {
	# IPv4 addresses found in DNSBL lists
	check_runtime_vars
	r="${BLOCKLIST_RESULTS}/db/DNSBLIP_v4.txt"
	b="${BLOCKLIST_BENCHMARK}/db/DNSBLIP_v4.txt"

	printf "diff DNSBLIP_v4 .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"

	r="${BLOCKLIST_RESULTS}/db/original/DNSBLIP_v4.orig"
	b="${BLOCKLIST_BENCHMARK}/db/original/DNSBLIP_v4.orig"

	printf "diff original/DNSBLIP_v4 .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_match() {
	check_runtime_vars
	r="${BLOCKLIST_RESULTS}/db/match"
	b="${BLOCKLIST_BENCHMARK}/db/match"

	printf "diff match .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_native() {
	check_runtime_vars
	r="${BLOCKLIST_RESULTS}/native"
	b="${BLOCKLIST_BENCHMARK}/native"

	printf "diff native .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}

function diff_original() {
	check_runtime_vars
	r="${BLOCKLIST_RESULTS}/db/original"
	b="${BLOCKLIST_BENCHMARK}/db/original"

	printf "diff original .." | ${TEECMD} "${LOGFILE}"
	_run_diff "${r}" "${b}"
}
