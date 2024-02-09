#!/bin/bash

(cd $(dirname -- "${BASH_SOURCE[0]}")
source ../global/everything.sh

# upload files to the webserver from within THIS test directory
setup "$(pwd)" "$@"

# there will be cases where the execution must use existing files
clean_pfsense

# each test may need to invoke the execution specially
exec_pfsense "updatednsbl"
exec_pfsense "updateip"
# options 'cron' and 'reload' require additional option(s) set

# retrieve files from /var/db/pfblockerng/ and /var/log/pfblockerng/
capture_pfsense
update_benchmark

# each test may need to diff one or more pieces of data
#diff_dnsbl
#diff_dnsblorig
diff_alldnsbl
)
