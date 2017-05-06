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

1. start containers
2. setup cluster
3. run mysql-router
4. use cluster via router

## ports

In this example, we will use following ports on local server.

- 9001 - 9003 : for MySQL Servers
- 9011 - 9014 : for MySQL Router

Please edit `docker-compose.yml` as you like.

## start containers

```shell
cd examples/local/
docker-compose up -d
docker-compose logs
```

It will take 3 minutes until following message appears
due to something wrong about GR settings. sorry.

```shell
mysql-9003   | MySQL init process done. Ready for start up.
```

Now, we have three MySQL instances on 9001, 9002, 9003 and also have `ic` user on each nodes.

## setup cluster

Here, assumed that our IP Address of the docker host is `192.168.237.128`.
We should use it rather than `localhost` because InnoDB Cluster expects non-local addresses.

```shell
% docker exec -it mysql-9001 mysqlsh --uri ic:root@192.168.237.128:9001
mysql-js> var cluster = dba.createCluster('cluster1')
mysql-js> cluster.addInstance('ic:root@192.168.237.128:9002')
mysql-js> cluster.addInstance('ic:root@192.168.237.128:9003')
```

## run mysql-router

### generate router configuration

Run mysqlrouter bootstrap on `router` container.

```shell
% docker exec -it mysql-router bash
# mysqlrouter --bootstrap ic:root@192.168.237.128:9001 --user=mysqlrouter --conf-base-port=9011
```

### restart router service

```shell
% docker restart mysql-router
```

## use cluster via router

- router for primary node(read,write) : 9011
- back server : 9001 (it should be)

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


