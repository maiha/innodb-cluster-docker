FROM ubuntu:16.04

# Update packages
RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates wget lsb-release python \
  && rm -rf /var/lib/apt/lists

# run "dpkg-reconfigure mysql-apt-config" without interaction
COPY mysql.preseed /root/mysql.preseed

# Install latest MySQL packages
# https://dev.mysql.com/downloads/repo/apt/
# (mysql-apt-config_0.8.4-1_all.deb)	MD5: cdda177817edec8c14d8de2626b24e47
RUN set -x \
  && wget http://dev.mysql.com/get/mysql-apt-config_0.8.4-1_all.deb \
  && debconf-set-selections /root/mysql.preseed \
  && dpkg -i ./mysql-apt-config_0.8.4-1_all.deb

# Just put apt file directly rather than using "dpkg-reconfigure"
COPY mysql.apt     /etc/apt/sources.list.d/mysql.list

RUN set -x \
  && apt-get update \
  && debconf-set-selections /root/mysql.preseed \
  && DEBIAN_FRONTEND=noninteractive apt-get install -q -y mysql-server mysql-shell mysql-router \
  && rm -rf /var/lib/apt/lists

COPY bin/* /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["mysqld"]
