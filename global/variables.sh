# global variables

UPDATEBENCHMARK=false
DRYRUN=true

IDENTITY_FILE="${HOME}/.ssh/id_rsa"

PFSENSE_USERNAME='admin'
PFSENSE_HOSTNAME='192.168.1.X'
PFSENSE_PORT=22
PFSENSE_RMPATH='/bin/rm'

WEBSERVER_USERNAME="username"
WEBSERVER_HOSTNAME="webserver.localdomain"
WEBSERVER_PORT=22
WEBSERVER_HTTPDOCS='/var/www/htdocs/pfblockerng/testing'
WEBSERVER_RMPATH='/bin/rm'

DIFFARGS="-qr"

source ${HOME}/.config/pfblockerng/userconfig.sh


# optional; used to filter the set of files to delete from webserver_httpdocs
LOGFILE='0UTPUT.log'
EXT=".txt"

TEECMD='tee -a'


BLOCKLIST_SRCDIR=
BLOCKLIST_STAGEDIR=
BLOCKLIST_RESULTS=
BLOCKLIST_BENCHMARK=
SETUP_TESTNAME=

QUERYLIST_RESULTS=
QUERYLIST_BENCHMARK=

# a list of all files that pfBlockerNG is configured to reference from the
# webserver. Initially support for exactly one webserver to serve these files.
# Each test case will ensure this set of files exist on the webserver - empty or
# with contents.
BLOCKLIST_FILENAMES=(
	"palpha_01.txt"
	"palpha_02.txt"
	"palpha_03.txt"

	"beta01.txt"
	"beta02.txt"
	"beta03.txt"

	"pbeta01.txt"
	"pbeta02.txt"
	"pbeta03.txt"

	"gamma01.txt"
	"gamma02.txt"
	"gamma03.txt"

	"delta01.txt"
	"delta02.txt"
	"delta03.txt"
)

WEBSERVER_REMOTE=false


function checks_and_balances() {
	webserver_local=false

	if [ -z "${LOGFILE}" ]; then
		echo "ERROR: LOGFILE is empty or undefined" | ${TEECMD} "${LOGFILE}"
		exit 1
	fi

	if [ -z "${PFSENSE_HOSTNAME}" ] || [ -z "${PFSENSE_USERNAME}" ] || \
		[ -z "${PFSENSE_PORT}" ]; then
		echo "ERROR: One or more pfSense options are unset or empty!" \
			| ${TEECMD} "${LOGFILE}"
		exit 1
	fi

	echo "pfSense host: ${PFSENSE_HOSTNAME}" | ${TEECMD} "${LOGFILE}"

	if [ -z "${WEBSERVER_USERNAME}" ] || [ -z "${WEBSERVER_HOSTNAME}" ] || \
		[ -z "${WEBSERVER_PORT}" ]; then
		echo "One or more required options for remote webserver is empty." \
			| ${TEECMD} "${LOGFILE}"
		echo "Blocklist files will be installed into a local directory." \
			| ${TEECMD} "${LOGFILE}"
		webserver_local=true
	else
		echo "All required options for remote webserver are non-empty." \
			| ${TEECMD} "${LOGFILE}"
		echo "Blocklist files will be installed onto a remote machine." \
			| ${TEECMD} "${LOGFILE}"
		WEBSERVER_REMOTE=true
	fi

	if [ -z "${WEBSERVER_HTTPDOCS}" ]; then
		WEBSERVER_REMOTE=false
		webserver_local=false
		echo "ERROR: webserver_httpdocs must be set to a non-empty valid directory path" \
			| ${TEECMD} "${LOGFILE}"
		exit 1
	fi

	if [ ${webserver_local} == true ]; then
		if [ ! -d "${WEBSERVER_HTTPDOCS}" ]; then
			echo "ERROR: webserver_httpdocs must be set to a valid existing directory path" \
				| ${TEECMD} "${LOGFILE}"
			exit 1
		fi
	fi
}

function check_query_vars() {
	if [ -z "${QUERYLIST_RESULTS}" ]; then
		echo "ERROR: QUERYLIST_RESULTS is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	if [ -z "${QUERYLIST_BENCHMARK}" ]; then
		echo "ERROR: QUERYLIST_BENCHMARK is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	return 0
}

function check_runtime_vars() {
	if [ -z "${BLOCKLIST_STAGEDIR}" ]; then
		echo "ERROR: BLOCKLIST_STAGEDIR is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	if [ -z "${BLOCKLIST_SRCDIR}" ]; then
		echo "ERROR: BLOCKLIST_SRCDIR is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	if [ -z "${BLOCKLIST_RESULTS}" ]; then
		echo "ERROR: BLOCKLIST_RESULTS is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	if [ -z "${BLOCKLIST_BENCHMARK}" ]; then
		echo "ERROR: BLOCKLIST_BENCHMARK is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	if [ -z "${SETUP_TESTNAME}" ]; then
		echo "ERROR: SETUP_TESTNAME is empty or unset" | ${TEECMD} "${LOGFILE}"
		exit -1
	fi

	return 0
}

function parsearg1() {
	argv1=$(echo "$1" | tr '[:lower:]' '[:upper:]')
	if [ "X${argv1}" == "XUPDATE" ]; then
		UPDATEBENCHMARK=true
	elif [ "X${argv1}" == "XDRYRUN" ] || [ "X${argv1}" == "XDRY" ]; then
		DRYRUN=true
	fi
	return 0
}
