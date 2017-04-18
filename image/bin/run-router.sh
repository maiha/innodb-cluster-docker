#!/bin/bash
set -eo pipefail
shopt -s nullglob

set -x
service mysqlrouter start
exec tail -f /dev/null
