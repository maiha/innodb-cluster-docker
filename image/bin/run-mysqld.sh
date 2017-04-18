#!/bin/bash

# original:  official "docker-entrypoint.sh"

set -eo pipefail
shopt -s nullglob

: ${MYSQL_PORT:=3306}
: ${MYSQL_SERVER_ID:=$MYSQL_PORT}
: ${MYSQL_ADMIN_PASSWORD:=root}

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
ln -sf /mnt/run/mysqld.sock /var/run/mysqld/mysqld.sock

# config
[ -f $CUSTOM ] || rm -rf /etc/mysql/mysql.conf.d
[ -d $CNFDIR ] || mkdir $CNFDIR
[ -L /etc/mysql/mysql.conf.d ] || ln -sf $CNFDIR /etc/mysql/mysql.conf.d

# generate mysqld.conf if missing
[ -f $CNFDIR/mysqld.cnf ] || cat <<EOF > $CNFDIR/mysqld.cnf
[mysqld]
pid_file        = $RUNDIR/mysqld.pid
socket          = $SOCKET
datadir         = $DATADIR
log_error       = $LOGDIR/error.log
# By default we only accept connections from localhost
bind-address = *
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic_links=0
log_slave_updates = ON
relay_log_info_repository = TABLE
master_info_repository = TABLE
transaction_write_set_extraction = XXHASH64
binlog_format = ROW
disabled_storage_engines = MyISAM,BLACKHOLE,FEDERATED,CSV,ARCHIVE
binlog_checksum = NONE
enforce_gtid_consistency = ON
log_bin
gtid_mode = ON
EOF

# generate mysql config by running parameters
[ -f $CUSTOM ] || cat <<EOF > $CUSTOM
[mysqld]
port = $MYSQL_PORT
report_port = $MYSQL_PORT
server_id = $MYSQL_SERVER_ID
EOF

service mysql start

mysql=( mysql --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" )

for i in {30..0}; do
  if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
    break
  fi
  echo "MySQL init process in progress... (${mysql[@]})"
  sleep 1
done

if [ "$i" = 0 ]; then
    echo >&2 'MySQL init process failed.'
    exit 1
fi

# [for 1st time boot]
# Create an account for MySQL-Shell as 'ic', and install "group_replication" plugin.
# This is an automation of "dba.configureLocalInstance".
# CONDITION: group_replication is install or not
if echo 'SHOW PLUGINS' | "${mysql[@]}" | grep -q -i group_replication &> /dev/null; then
  echo "[PLUGIN] found: group_replication"
else
  echo "[PLUGIN] not found: group_replication"
  "${mysql[@]}" <<-EOSQL
    START TRANSACTION;
      CREATE USER 'ic'@'%' IDENTIFIED WITH 'mysql_native_password' BY '${MYSQL_ADMIN_PASSWORD}';
      GRANT RELOAD, SHUTDOWN, PROCESS, FILE, SUPER, REPLICATION SLAVE, REPLICATION CLIENT, CREATE USER ON *.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT ALL PRIVILEGES ON mysql_innodb_cluster_metadata.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT SELECT ON performance_schema.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT SELECT, INSERT, UPDATE, DELETE ON mysql.* TO 'ic'@'%' WITH GRANT OPTION;
      GRANT ALL PRIVILEGES ON *.* TO 'ic'@'%' WITH GRANT OPTION; -- for create database
      INSTALL PLUGIN group_replication SONAME 'group_replication.so';
      RESET MASTER; -- I'm not sure but this is needed due to password changed.
    COMMIT;
EOSQL
  echo >&2 "[PLUGIN] installed: group_replication"
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
