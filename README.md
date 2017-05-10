# innodb-cluster

a helper for running InnoDB Cluster on docker

## files

### bundled files

```
- examples/  # examples to run
- image/     # Dockerfile and image builder
```

## install docker image

```shell
% (cd image && make install)
% docker images | grep innodb-cluster | less -S
innodb-cluster               0.8.4               01743be6054c
innodb-cluster               latest              01743be6054c
```

# usage (on local)

1. build configs
2. start containers
3. setup cluster
4. run mysql-router
5. use cluster via router

## ports

In this example, we will use following ports on local server.

- 9001 - 9003 : for MySQL Servers
- 9011 - 9014 : for MySQL Router

Please edit `docker-compose.yml` and `Makefile` as you like.

## build configs

```shell
cd examples/local/
make build
```

This generates files in `v/900*/conf/*`.
MySQL server containers mount each directories.
If you need to add special settings, edit those configs before starting containers.

## start containers

```shell
docker-compose up -d
docker-compose logs
```

Please wait a few sec until following message appears.

```shell
mysql-9003   | MySQL init process done. Ready for start up.
```

Now, we have three MySQL instances on port 9001, 9002, 9003 and also have `ic` user on each nodes.

## setup cluster

The operation will be shown by following command.

```shell
% make cluster
```

## run mysql-router

### generate router configuration

Run mysqlrouter bootstrap on `router` container.
The operation will be shown by following command.

```shell
% make router
```

## use cluster via router

```shell
% make usage
```

Here, assumed that our IP Address of the docker host is `192.168.237.128`.

- router for primary node(read,write) : 9011
- back server : 9001 (it should be)

The operation will be shown by following command.

```shell
% mysql -h 192.168.237.128 -P 9011 -uic -proot
mysql> select @@port;
+--------+
| @@port |
+--------+
|   9001 |
+--------+
```

- router for secondary node(read-only) : 9012
- back server : 9002 or 9003

```shell
% mysql -h 192.168.237.128 -P 9012 -uic -proot
mysql> select @@port;
+--------+
| @@port |
+--------+
|   9003 |
+--------+
```

## NOTE

### known issues

- `/etc/init.d/mysql: line 63: /lib/apparmor/profile-load: No such file or directory`

I'd like to resolve this error.

