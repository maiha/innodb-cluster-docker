build:
	mkdir -p v/9001
	docker run -e MYSQL_PORT=9001 -v $$PWD/v/9001:/mnt -it --rm innodb-cluster build

run:
	docker run -v $$PWD/v/9001:/mnt -d -p 9001:9001 --net host --name mysql-9001 innodb-cluster mysqld

console:
	docker exec -it mysql-9001 bash

destroy:
	docker rm -v -f mysql-9001

clean:
	docker run --rm -t -v $$PWD/v:/mnt alpine chown -R $$(id -u):$$(id -g) /mnt
	rm -rf v
