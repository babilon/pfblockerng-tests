#!/bin/bash
#
(cd $(dirname -- "${BASH_SOURCE[0]}")
source ../global/everything.sh

diglog="dig_results.log"

digcmd=/usr/local/bin/dig
nslookupcmd=/usr/local/bin/nslookup

function querydomain() {
	domain=$1
	/bin/ssh -i "${IDENTITY_FILE}" -p "${PFSENSE_PORT}" \
		"${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME}" \
		"/usr/local/bin/dig" \
		"${domain}" >> "${diglog}"

	return 0
}

function retrieve_dnsbl_log() {
	check_query_vars

	/usr/bin/rm -f "${QUERYLIST_RESULTS}"
	/bin/mkdir -p "${QUERYLIST_RESULTS}"

	/bin/scp -i "${IDENTITY_FILE}" -P "${PFSENSE_PORT}" -r \
		"${PFSENSE_USERNAME}@${PFSENSE_HOSTNAME}:/var/log/pfblockerng/*.log" \
		"${QUERYLIST_RESULTS}"
	ret=$?
	if [ ${ret} -ne 0 ]; then
		echo "ERROR: scp /var/log/pfblockerng/dnsbl.log exited non-zero ${ret}"
		exit ${ret}
	fi

	if [ ! -f "${QUERYLIST_RESULTS}/dnsbl.log" ]; then
		echo "ERROR: ${QUERYLIST_RESULTS}/dnsbl.log is not a file" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	# strip the date column from the query log and save a copy
	/usr/bin/cat "${QUERYLIST_RESULTS}/dnsbl.log" | cut -d',' -f2 --complement > \
		"${QUERYLIST_RESULTS}/dnsbl.dateless.log"

	if [ ${UPDATEBENCHMARK} == true ]; then
		/bin/rm -rf "${QUERYLIST_BENCHMARK}"
		/bin/mkdir -p "${QUERYLIST_BENCHMARK}"
		/bin/cp "${QUERYLIST_RESULTS}/dnsbl.dateless.log" "${QUERYLIST_BENCHMARK}/"
	fi
}

checks_and_balances

setupquery "$(pwd)" "$@"

querydomain "palpha02.com"
# will need to pick stable domains and handle IPs changing including IPv6
# or at least only care what the IP is of the domains that are blocked
querydomain "google.com"

querydomain "only.gamma.biz"
querydomain "bogus.subdomain.palpha01.com"

retrieve_dnsbl_log

diff_query
)
