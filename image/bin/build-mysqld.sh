#!/bin/bash

# generate config files in "/mnt/conf"

set -eo pipefail
shopt -s nullglob

: ${MYSQL_PORT:=3306}
: ${MYSQL_SERVER_ID:=$MYSQL_PORT}
: ${MYSQL_ADMIN_PASSWORD:=root}

# config
mkdir -p /mnt/conf

# generate default mysqld.conf if missing
[ -f /mnt/conf/mysqld.cnf ] || cat <<EOF > /mnt/conf/mysqld.cnf
[mysqld]
plugin-load=group_replication=group_replication.so

# files
pid_file        = /mnt/run/mysqld.pid
pid-file        = /mnt/run/mysqld.pid    # ubuntu package expects hyphens format
socket          = /mnt/run/mysqld.sock
datadir         = /mnt/data/mysql
log_error       = /mnt/logs/error.log

# connection
bind-address    = *

# Group Replication
log_bin                          = master-bin
gtid_mode                        = ON
binlog_format                    = ROW
disabled_storage_engines         = MyISAM,BLACKHOLE,FEDERATED,CSV,ARCHIVE
binlog_checksum                  = NONE
enforce_gtid_consistency         = ON
transaction_write_set_extraction = XXHASH64

symbolic_links            = 0
log_slave_updates         = ON
relay_log_info_repository = TABLE
master_info_repository    = TABLE
EOF

# generate mysql config by running parameters if missing
[ -f /mnt/conf/custom.cnf ] || cat <<EOF > /mnt/conf/custom.cnf
[mysqld]
port        = $MYSQL_PORT
report_port = $MYSQL_PORT
server_id   = $MYSQL_SERVER_ID
EOF

