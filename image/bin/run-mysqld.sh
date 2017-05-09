#!/bin/bash

# original:  official "docker-entrypoint.sh"

set -eo pipefail
shopt -s nullglob

dir=$(dirname ${BASH_SOURCE:-$0})
source $dir/build-mysqld.sh

DATADIR=/mnt/data/mysql
LOGDIR=/mnt/logs
RUNDIR=/mnt/run
CNFDIR=/mnt/conf
SOCKET=/mnt/run/mysqld.sock
CUSTOM=/etc/mysql/mysql.conf.d/custom.cnf

# clean up old files for the case of reboot
rm -rf "${RUNDIR}"

# setup
mkdir -p "${LOGDIR}" "${RUNDIR}" "${DATADIR}"
chown -R mysql:mysql /mnt
chmod 777 "${RUNDIR}"
rm -rf /etc/mysql/mysql.conf.d
ln -sf /mnt/conf /etc/mysql/mysql.conf.d
ln -sf /mnt/run/mysqld.sock /var/run/mysqld/mysqld.sock

echo "Starting mysql service (ubuntu)"
#su - mysql -s /bin/sh -c "/usr/bin/mysqld_safe > /dev/null 2>&1 &"
service mysql start
echo "Started mysql service (ubuntu)"

mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="${SOCKET}")

for i in {10..0}; do
  if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
    break
  fi
  echo "MySQL init process in progress... (${mysql[@]})"
  sleep 1
done

if [ "$i" = 0 ]; then
    echo >&2 'MySQL init process failed.'
#    exit 1
fi

# [for 1st time boot]
# Create an account for MySQL-Shell as 'ic' if missing.
# This is an automation of "dba.configureLocalInstance".
RESULT_VARIABLE="$(${mysql[@]} -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = 'ic')")"
if [ $RESULT_VARIABLE = 1 ]; then
  echo "[PLUGIN] Group Replication is enabled."
else
  echo "[PLUGIN] Confuguring Group Replication user(ic)..."
  "${mysql[@]}" <<-EOSQL
    START TRANSACTION;
      CREATE USER 'ic'@'%' IDENTIFIED WITH 'mysql_native_password' BY '${MYSQL_ADMIN_PASSWORD}';
      GRANT RELOAD, SHUTDOWN, PROCESS, FILE, SUPER, REPLICATION SLAVE, REPLICATION CLIENT, CREATE USER ON *.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT ALL PRIVILEGES ON mysql_innodb_cluster_metadata.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT SELECT ON performance_schema.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT SELECT, INSERT, UPDATE, DELETE ON mysql.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT ALL PRIVILEGES ON *.* TO 'ic'@'%' WITH GRANT OPTION; -- for create database
      RESET MASTER; -- I'm not sure but this is needed due to password changed.
    COMMIT;
EOSQL
  echo "[PLUGIN] Configured Group Replication."
fi

for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
	*.sh)     echo "$0: running $f"; . "$f" ;;
	*.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
	*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
	*)        echo "$0: ignoring $f" ;;
    esac
    echo
done

echo
echo 'MySQL init process done. Ready for start up.'
echo

exec tail -f /dev/null
