#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ "$1" = 'mysqld' ]; then
  exec run-mysqld.sh
elif [ "$1" = 'router' ]; then
  exec run-router.sh
else
  exec "$@"
fi
