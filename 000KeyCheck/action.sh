#!/bin/bash

(cd $(dirname -- "${BASH_SOURCE[0]}")
source ../global/everything.sh

check_ssh_connections
)
