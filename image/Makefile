IMAGE := innodb-cluster
VERSION := 0.8.4
BUILD_ARG := --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(http_proxy)

.PHONY : install
install: Dockerfile
	@set -x; \
	docker build ${BUILD_ARG} -t ${IMAGE}:latest -t ${IMAGE}:${VERSION} .

.PHONY : uninstall
uninstall:
	docker rmi ${IMAGE}:${VERSION}

.PHONY : test
test: install check

.PHONY : check
check: version_check

.PHONY : version_check
version_check:
	@docker run --rm -it ${IMAGE}:latest mysql --version; \
	docker run --rm -it ${IMAGE}:latest mysqlsh --version; \
	docker run --rm -it ${IMAGE}:latest mysqlrouter --version;

.PHONY : mysql_check
mysql_check: mysql_clean
	docker run -d --name 'innodb-cluster-test' -e MYSQL_PORT=8999 innodb-cluster
	echo "SELECT user,host,plugin from mysql.user;" | docker exec -t 'innodb-cluster-test' mysql

.PHONY : mysql_clean
mysql_clean:
	@docker ps -f name='innodb-cluster-test' -a -q | cut -f1 -d' ' | xargs -r docker rm -f
