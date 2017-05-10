# TODO: dryup with docker-compose.yml
MYSQL_PORTS = 9001 9002 9003
MYSQL_PASSWORD = root

PRIMARY_PORT = $(shell echo "${MYSQL_PORTS}" | cut -d" " -f1)
PRIMARY_NAME = mysql-${PRIMARY_PORT}
HOST_IP = $(shell hostname -i)

all:
	@echo "# Please run following commands"
	@echo "make build"
	@echo "make run"
	@echo "make cluster"
	@echo "make router"
	@echo "make usage"

build:
	@for x in $(MYSQL_PORTS) ; do\
	  mkdir -p "v/$$x" ;\
	  docker run -e MYSQL_PORT="$$x" -v "$$PWD/v/$$x:/mnt" -it --rm innodb-cluster build ;\
	done

run:
	docker-compose up -d

logs:
	docker-compose logs

cluster:
	@echo "Please run following commands to setup cluster."
	@echo
	@echo "% docker exec -it ${PRIMARY_NAME} mysqlsh --uri ic:${MYSQL_PASSWORD}@${HOST_IP}:${PRIMARY_PORT}"
	@echo "mysql-js> var cluster = dba.createCluster('cluster1')"
	@for x in $(MYSQL_PORTS) ; do\
	  [ "$$x" = "${PRIMARY_PORT}" ] || echo "mysql-js> cluster.addInstance('ic:${MYSQL_PASSWORD}@${HOST_IP}:$$x')" ;\
	done

router:
	@echo "Please run following commands to setup cluster."
	@echo
	@echo "% docker exec -it mysql-router mysqlrouter --bootstrap ic:${MYSQL_PASSWORD}@${HOST_IP}:${PRIMARY_PORT} --user=mysqlrouter --conf-base-port=9011"
	@echo "% docker restart mysql-router"

usage:
	@echo "% mysql -h ${HOST_IP} -P 9011 -uic -p${MYSQL_PASSWORD}"
	@echo "mysql> select @@port;"
	@echo "# This port should be 9001. And the connection is writable."
	@echo
	@echo "% mysql -h ${HOST_IP} -P 9012 -uic -p${MYSQL_PASSWORD}"
	@echo "mysql> select @@port;"
	@echo "# This port should be 9002. And the connection is read-only."

console:
	docker exec -it "${PRIMARY_NAME}" bash

destroy:
	docker-compose stop
	docker-compose rm -v -f

clean: destroy
	docker run --rm -t -v "$$PWD/v:/mnt" alpine chown -R "$$(id -u):$$(id -g)" /mnt
	rm -rf v
